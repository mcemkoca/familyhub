# SPRINT 2: GUVENLIK & VERI BUTUNLUGU
## 5 Kritik Sorun | Hedef: Guvenlik Aciklari Kapandi

---

## 6. Child Login — Aile Filtresi Ekle

**Sorun:** Auth'siz tum cocuklari listeleyebilir → **Veri sizintisi**

### lib/features/auth/screens/child_login_screen.dart
```dart
class ChildLoginScreen extends StatelessWidget {
  Future<List<ChildProfile>> _getFamilyChildren() async {
    final user = SupabaseConfig.safeClient.auth.currentUser;
    if (user == null) throw AuthException('Oturum yok');

    // ONCE aile ID'sini al
    final familyResult = await SupabaseConfig.safeClient
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id)
        .single();

    final familyId = familyResult['family_id'];

    // SONRA sadece o aileye ait cocuklari getir
    final children = await SupabaseConfig.safeClient
        .from('child_profiles')
        .select('*')
        .eq('family_id', familyId)
        .eq('is_active', true);

    return (children as List).map((e) => ChildProfile.fromJson(e)).toList();
  }
}
```

### SQL — family_id kolonu ekle (yoksa)
```sql
ALTER TABLE child_profiles ADD COLUMN IF NOT EXISTS family_id UUID REFERENCES families(id);
CREATE INDEX idx_child_profiles_family ON child_profiles(family_id);
```

---

## 7. Child PIN — bcrypt ile Hash'le

**Sorun:** Plaintext saklaniyor, `hashPin()` hic cagrilmiyor

### pubspec.yaml
```yaml
dependencies:
  bcrypt: ^1.1.3
```

### lib/core/utils/crypto_utils.dart
```dart
import 'package:bcrypt/bcrypt.dart';

class CryptoUtils {
  static String hashPin(String pin) {
    return BCrypt.hashpw(pin, BCrypt.gensalt(rounds: 10));
  }

  static bool verifyPin(String pin, String hash) {
    return BCrypt.checkpw(pin, hash);
  }
}
```

### lib/features/auth/screens/children_step.dart — Duzeltilmis
```dart
Future<void> _saveChildPin(String childId, String pin) async {
  // YANLIS: await _client.from('child_profiles').update({'pin': pin});

  // DOGRU:
  final hashedPin = CryptoUtils.hashPin(pin);

  await SupabaseConfig.safeClient
      .from('child_profiles')
      .update({'pin_hash': hashedPin})
      .eq('id', childId);
}

Future<bool> _verifyChildPin(String childId, String pin) async {
  final result = await SupabaseConfig.safeClient
      .from('child_profiles')
      .select('pin_hash')
      .eq('id', childId)
      .single();

  final storedHash = result['pin_hash'] as String?;
  if (storedHash == null) return false;

  return CryptoUtils.verifyPin(pin, storedHash);
}
```

### SQL Migration
```sql
-- Mevcut PIN'leri hash'le
ALTER TABLE child_profiles ADD COLUMN IF NOT EXISTS pin_hash TEXT;

-- Eski plaintext kolonu kaldir (veri kaybi olabilir, once hash'le!)
-- UPDATE child_profiles SET pin_hash = ... (migration script ile)
ALTER TABLE child_profiles DROP COLUMN IF EXISTS pin;
```

---

## 8. Chat → Supabase Realtime

**Sorun:** Chat tamamen local, aile uyeleri mesajlari goremiyor

### supabase/migrations/048_chat_messages.sql
```sql
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL,
    sender_id UUID REFERENCES auth.users(id),
    sender_name VARCHAR(100),
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can view chat"
ON chat_messages FOR SELECT TO authenticated
USING (family_id IN (
    SELECT family_id FROM family_members 
    WHERE user_id = auth.uid() AND is_active = true
));

CREATE POLICY "Family members can send messages"
ON chat_messages FOR INSERT TO authenticated
WITH CHECK (family_id IN (
    SELECT family_id FROM family_members 
    WHERE user_id = auth.uid() AND is_active = true
));
```

### lib/features/chat/services/chat_service.dart
```dart
class ChatService {
  final SupabaseClient _client = SupabaseConfig.safeClient;
  RealtimeChannel? _channel;

  Stream<List<ChatMessage>> watchMessages(String familyId) {
    _channel = _client
        .channel('chat:$familyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: (payload) {},
        )
        .subscribe();

    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ChatMessage.fromJson(e)).toList());
  }

  Future<void> sendMessage(String familyId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('Oturum yok');

    await _client.from('chat_messages').insert({
      'family_id': familyId,
      'sender_id': user.id,
      'sender_name': user.userMetadata?['name'] ?? 'Bilinmiyor',
      'content': content,
      'message_type': 'text',
    });
  }

  void dispose() => _channel?.unsubscribe();
}
```

### lib/features/chat/screens/chat_screen.dart — senderId duzeltme
```dart
// YANLIS: final isMe = msg.senderId == 'm1';
// DOGRU:
final isMe = msg.senderId == SupabaseConfig.safeClient.auth.currentUser?.id;
```

---

## 9. Family Screen — Sahte CRUD'u Gercek Yap

**Sorun:** Rol degisikligi/silme local state only, Supabase'e yazmiyor

### lib/features/family/repositories/family_repository.dart
```dart
class FamilyRepository {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _client.from('family_members')
        .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', memberId);
  }

  Future<void> deactivateMember(String memberId) async {
    await _client.from('family_members')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', memberId);
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final response = await _client
        .from('family_members')
        .select('*, profiles:user_id(*)')
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('created_at', ascending: true);

    return (response as List).map((e) => FamilyMember.fromJson(e)).toList();
  }
}
```

### lib/features/family/screens/family_screen.dart
```dart
Future<void> _updateMemberRole(String memberId, String newRole) async {
  try {
    await _repository.updateMemberRole(memberId, newRole);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol guncellendi')),
      );
    }
    _loadMembers(); // Listeyi yenile
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}

Future<void> _removeMember(String memberId) async {
  try {
    await _repository.deactivateMember(memberId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uye kaldirildi')),
      );
    }
    _loadMembers();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}
```

---

## 10. Biometric PIN Duzelt

**Sorun:** Fallback PIN her zaman `false` donuyor

### lib/core/services/biometric_service.dart
```dart
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    final bool canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return await _authenticateWithPin();

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Guvenli erisim icin kimliginizi dogrulayin',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet') {
        return await _authenticateWithPin();
      }
      return false;
    }
  }

  Future<bool> _authenticateWithPin() async {
    final String? pin = await _showPinDialog();
    if (pin == null) return false;

    final storedHash = await _getStoredPinHash();
    if (storedHash == null) return false;

    return CryptoUtils.verifyPin(pin, storedHash);
  }

  Future<String?> _showPinDialog() async {
    // PIN input dialog
    String? enteredPin;
    await showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PIN Girin'),
        content: TextField(
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          onChanged: (value) => enteredPin = value,
        ),
        actions: [
          TextButton(
            onPressed: () {
              enteredPin = null;
              Navigator.pop(context);
            },
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dogru'),
          ),
        ],
      ),
    );
    return enteredPin;
  }

  Future<String?> _getStoredPinHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_pin_hash');
  }
}
```

---

## Kontrol Listesi

- [ ] Child login sadece aile cocuklarini listeliyor
- [ ] Child PIN bcrypt ile hash'leniyor
- [ ] Chat Supabase Realtime'e bagli
- [ ] Chat senderId auth.uid() kullaniyor
- [ ] Family screen CRUD Supabase'e yaziyor
- [ ] Biometric fallback PIN calisiyor
- [ ] Tüm RLS politikalari aktif

---
**Versiyon:** 1.0 | **Sprint:** 2/4 | **Hedef:** Guvenlik Aciklari Kapandi
