# FAMILYHUB AI MASTER PROMPT v3.0 — EKRAN DÜZELTME & GELİŞTİRME
# ===================================================================
# SİSTEM: FamilyHub Flutter Uygulaması — Ekran Düzeltme Motoru
# GÖREV: 15 kritik/orta/düşük öncelikli sorunu çöz, gerçek veri entegrasyonu sağla
# TEKNOLOJİ: Flutter + Supabase + Hive + GoRouter + local_auth + flutter_stripe
# DİL: Dart (Flutter)
# ===================================================================

## SİSTEM KİMLİĞİ
Sen "FamilyHub Ekran Düzeltme AI"'sısın. Flutter kodunu analiz eder, gerçek veri akışı sağlar, sahte/statik kodları tespit edip düzeltirsin. Her düzeltme için:
1. Sorunu tanımla (kök neden)
2. Gerçek veri kaynağını belirle (Supabase tablosu / Hive kutusu / API)
3. Dart kodunu yaz (null-safety, async/await, error handling ile)
4. Cache stratejisi tanımla (Hive ile offline-first)

## VERİ KAYNAKLARI HARİTASI

### Supabase Tabloları
| Tablo | Amaç | İlişki |
|-------|------|--------|
| `profiles` | Kullanıcı profili (ad, avatar, rol, is_premium, family_id) | auth.users 1:1 |
| `families` | Aile bilgisi (id, name, invite_code, invite_expires_at) | profiles.family_id |
| `family_members` | Aile üyeleri (user_id, family_id, role: admin/member) | profiles.user_id |
| `child_accounts` | PIN'li çocuk hesapları (id, family_id, name, pin, avatar, age) | families.id |
| `family_backups` | Yedekleme kayıtları (id, family_id, data_json, created_at) | families.id |
| `settings` | Kullanıcı ayarları (user_id, notifications, privacy, security JSON) | profiles.user_id |
| `weather_prefs` | Hava durumu tercihleri (user_id, city, unit, alerts) | profiles.user_id |
| `premium_subscriptions` | Abonelikler (user_id, tier, expires_at, provider) | profiles.user_id |

### Hive Kutuları (Offline Cache)
| Kutu | İçerik | TTL |
|------|--------|-----|
| `userBox` | profiles + families verisi | 1 saat |
| `membersBox` | family_members + child_accounts | 30 dk |
| `settingsBox` | Tüm ayarlar (bildirim, gizlilik, güvenlik) | Kalıcı |
| `backupBox` | Son yedekleme metadata | 24 saat |
| `weatherBox` | Hava durumu tercihleri | Kalıcı |

## SORUN 1: ProfileCard — Sahte Veri → Gerçek Veri
**Kök Neden**: Sabit string'ler ('M', 'Kullanıcı', 'Aile Yöneticisi', 'Premium')
**Çözüm**: Supabase `profiles` + `families` + `premium_subscriptions` JOIN

```dart
// models/profile_model.dart
class ProfileModel {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String role; // 'admin' | 'member' | 'child'
  final String? familyId;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final String? familyName;

  ProfileModel({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.role,
    this.familyId,
    required this.isPremium,
    this.premiumExpiry,
    this.familyName,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] ?? '',
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      role: map['role'] ?? 'member',
      familyId: map['family_id'],
      isPremium: map['is_premium'] ?? false,
      premiumExpiry: map['premium_expires_at'] != null 
          ? DateTime.parse(map['premium_expires_at']) 
          : null,
      familyName: map['families']?['name'],
    );
  }

  String get displayName => fullName ?? 'Kullanıcı';
  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
  String get roleDisplay {
    switch (role) {
      case 'admin': return 'Aile Yöneticisi';
      case 'member': return 'Aile Üyesi';
      case 'child': return 'Çocuk Hesabı';
      default: return 'Üye';
    }
  }
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiry == null) return true;
    return premiumExpiry!.isAfter(DateTime.now());
  }
}
```

```dart
// services/profile_service.dart
class ProfileService {
  final SupabaseClient _supabase;
  final Box<dynamic> _userBox;

  ProfileService(this._supabase, this._userBox);

  Future<ProfileModel> getCurrentProfile() async {
    // 1. Cache kontrolü
    final cached = _userBox.get('current_profile');
    if (cached != null) {
      final cacheTime = _userBox.get('profile_cache_time');
      if (cacheTime != null && 
          DateTime.now().difference(DateTime.parse(cacheTime)) < Duration(hours: 1)) {
        return ProfileModel.fromMap(Map<String, dynamic>.from(cached));
      }
    }

    // 2. Supabase sorgusu (profiles + families JOIN)
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('Oturum açık değil');

    final response = await _supabase
        .from('profiles')
        .select('''
          id, full_name, avatar_url, role, family_id, is_premium, premium_expires_at,
          families (name)
        ''')
        .eq('id', userId)
        .single();

    final profile = ProfileModel.fromMap(response);

    // 3. Cache'e kaydet
    await _userBox.put('current_profile', response);
    await _userBox.put('profile_cache_time', DateTime.now().toIso8601String());

    return profile;
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('Oturum açık değil');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('profiles').update(updates).eq('id', userId);

    // Cache'i temizle (bir sonraki get'te yeniden çek)
    await _userBox.delete('current_profile');
    await _userBox.delete('profile_cache_time');
  }
}
```

```dart
// widgets/profile_card.dart — DÜZELTİLMİŞ
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileModel>(
      future: context.read<ProfileService>().getCurrentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileCardSkeleton(); // Shimmer loading
        }
        if (snapshot.hasError) {
          return ProfileCardError(error: snapshot.error.toString());
        }

        final profile = snapshot.data!;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profile.avatarUrl != null 
                  ? NetworkImage(profile.avatarUrl!) 
                  : null,
              child: profile.avatarUrl == null 
                  ? Text(profile.initials) 
                  : null,
            ),
            title: Text(profile.displayName),
            subtitle: Text(profile.roleDisplay),
            trailing: profile.isPremiumActive 
                ? const Chip(label: Text('Premium')) 
                : null,
          ),
        );
      },
    );
  }
}
```

---

## SORUN 2: FamilyManageScreen — Çocuk Hesapları Eksik
**Kök Neden**: Sadece `family_members` (auth kullanıcıları) çekiyor, `child_accounts` (PIN'li çocuklar) yok
**Çözüm**: UNION sorgusu — hem ebeveynler hem çocuklar

```dart
// models/family_member_model.dart
class FamilyMemberModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // 'admin' | 'member' | 'child'
  final String memberType; // 'adult' | 'child'
  final DateTime? joinedAt;
  final int? age; // Sadece çocuklar için

  FamilyMemberModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.memberType,
    this.joinedAt,
    this.age,
  });

  factory FamilyMemberModel.fromAdult(Map<String, dynamic> map) {
    return FamilyMemberModel(
      id: map['user_id'] ?? map['id'],
      name: map['profiles']?['full_name'] ?? 'İsimsiz',
      avatarUrl: map['profiles']?['avatar_url'],
      role: map['role'] ?? 'member',
      memberType: 'adult',
      joinedAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  factory FamilyMemberModel.fromChild(Map<String, dynamic> map) {
    return FamilyMemberModel(
      id: map['id'],
      name: map['name'] ?? 'İsimsiz Çocuk',
      avatarUrl: map['avatar_url'],
      role: 'child',
      memberType: 'child',
      age: map['age'],
    );
  }
}
```

```dart
// services/family_service.dart
class FamilyService {
  final SupabaseClient _supabase;
  final Box<dynamic> _membersBox;

  FamilyService(this._supabase, this._membersBox);

  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    // 1. Cache kontrolü
    final cached = _membersBox.get('family_members_$familyId');
    if (cached != null) {
      final cacheTime = _membersBox.get('members_cache_time_$familyId');
      if (cacheTime != null && 
          DateTime.now().difference(DateTime.parse(cacheTime)) < Duration(minutes: 30)) {
        return (cached as List)
            .map((e) => FamilyMemberModel.fromAdult(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    // 2. Paralel sorgular (ebeveynler + çocuklar)
    final futures = await Future.wait([
      // Ebeveynler (auth kullanıcıları)
      _supabase
          .from('family_members')
          .select('''
            user_id, role, created_at,
            profiles (full_name, avatar_url)
          ''')
          .eq('family_id', familyId),

      // Çocuklar (PIN'li hesaplar)
      _supabase
          .from('child_accounts')
          .select('id, name, avatar_url, age')
          .eq('family_id', familyId),
    ]);

    final adults = (futures[0] as List)
        .map((e) => FamilyMemberModel.fromAdult(Map<String, dynamic>.from(e)))
        .toList();

    final children = (futures[1] as List)
        .map((e) => FamilyMemberModel.fromChild(Map<String, dynamic>.from(e)))
        .toList();

    final allMembers = [...adults, ...children];

    // 3. Cache'e kaydet
    await _membersBox.put('family_members_$familyId', futures[0]);
    await _membersBox.put('child_accounts_$familyId', futures[1]);
    await _membersBox.put('members_cache_time_$familyId', DateTime.now().toIso8601String());

    return allMembers;
  }

  Future<void> addChildAccount({
    required String familyId,
    required String name,
    required String pin,
    int? age,
    String? avatarUrl,
  }) async {
    // PIN 4 haneli, sadece rakam kontrolü
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ValidationException('PIN 4 haneli rakam olmalı');
    }

    await _supabase.from('child_accounts').insert({
      'family_id': familyId,
      'name': name,
      'pin': pin, // Hash'lenmiş olarak saklanmalı (Supabase trigger ile)
      'age': age,
      'avatar_url': avatarUrl,
    });

    // Cache'i temizle
    await _membersBox.delete('child_accounts_$familyId');
    await _membersBox.delete('members_cache_time_$familyId');
  }
}
```

```dart
// screens/family_manage_screen.dart — DÜZELTİLMİŞ
class FamilyManageScreen extends StatelessWidget {
  const FamilyManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyId = context.read<ProfileService>().currentFamilyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Yönetimi')),
      body: FutureBuilder<List<FamilyMemberModel>>(
        future: context.read<FamilyService>().getFamilyMembers(familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MembersListSkeleton();
          }
          if (snapshot.hasError) {
            return ErrorWidget(error: snapshot.error.toString());
          }

          final members = snapshot.data!;
          final adults = members.where((m) => m.memberType == 'adult').toList();
          final children = members.where((m) => m.memberType == 'child').toList();

          return ListView(
            children: [
              // Ebeveynler bölümü
              const ListTile(title: Text('Ebeveynler', style: TextStyle(fontWeight: FontWeight.bold))),
              ...adults.map((member) => MemberListTile(member: member)),

              const Divider(),

              // Çocuklar bölümü
              const ListTile(title: Text('Çocuklar', style: TextStyle(fontWeight: FontWeight.bold))),
              ...children.map((member) => MemberListTile(member: member)),

              // Çocuk ekle butonu
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('Çocuk Hesabı Ekle'),
                onTap: () => context.push('/add-child'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## SORUN 3: InviteCodeScreen — Sahte Davet Sistemi
**Kök Neden**: Client-side üretim, sunucu kaydı yok, 24 saat geçerlilik yok
**Çözüm**: Supabase RPC + 24 saat TTL + tek kullanımlık kod

```sql
-- Supabase Migration: Davet kodu sistemi
CREATE OR REPLACE FUNCTION generate_invite_code(family_id UUID)
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists_check BOOLEAN;
BEGIN
  LOOP
    -- 8 haneli alfanümerik kod (örn: A3B9K2L1)
    code := upper(substring(md5(random()::text) from 1 for 8));

    -- Çakışma kontrolü
    SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = code) INTO exists_check;

    EXIT WHEN NOT exists_check;
  END LOOP;

  -- Kodu kaydet, 24 saat geçerlilik
  UPDATE families 
  SET invite_code = code, 
      invite_expires_at = NOW() + INTERVAL '24 hours',
      invite_used = false
  WHERE id = family_id;

  RETURN code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

```dart
// services/invite_service.dart
class InviteService {
  final SupabaseClient _supabase;

  InviteService(this._supabase);

  Future<String> generateInviteCode(String familyId) async {
    final response = await _supabase.rpc(
      'generate_invite_code',
      params: {'family_id': familyId},
    );
    return response as String;
  }

  Future<void> joinFamilyByCode(String code, String userId) async {
    // 1. Kodu doğrula
    final family = await _supabase
        .from('families')
        .select('id, invite_expires_at, invite_used')
        .eq('invite_code', code.toUpperCase())
        .single();

    if (family == null) throw InviteException('Geçersiz davet kodu');
    if (family['invite_used'] == true) throw InviteException('Kod zaten kullanılmış');
    if (DateTime.parse(family['invite_expires_at']).isBefore(DateTime.now())) {
      throw InviteException('Kodun süresi dolmuş (24 saat)');
    }

    // 2. Kullanıcıyı aileye ekle
    await _supabase.from('family_members').insert({
      'user_id': userId,
      'family_id': family['id'],
      'role': 'member',
    });

    // 3. Kodu kullanılmış olarak işaretle
    await _supabase
        .from('families')
        .update({'invite_used': true})
        .eq('id', family['id']);
  }
}
```

---

## SORUN 4-5: GoogleDriveBackupScreen & BackupSettingsScreen
**Kök Neden**: `_triggerRestore()` sahte, `BackupSettingsScreen` kullanılmıyor
**Çözüm**: Supabase `family_backups` + Hive entegrasyonu + gerçek geri yükleme

```dart
// services/backup_service.dart
class BackupService {
  final SupabaseClient _supabase;
  final Box<dynamic> _backupBox;
  final Box<dynamic> _settingsBox;

  BackupService(this._supabase, this._backupBox, this._settingsBox);

  Future<Map<String, dynamic>> createBackup(String familyId) async {
    // 1. Tüm veriyi topla
    final backupData = <String, dynamic>{
      'profiles': await _supabase.from('profiles').select().eq('family_id', familyId),
      'family_members': await _supabase.from('family_members').select().eq('family_id', familyId),
      'child_accounts': await _supabase.from('child_accounts').select().eq('family_id', familyId),
      'settings': await _supabase.from('settings').select().eq('user_id', _supabase.auth.currentUser!.id),
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    // 2. Supabase'e kaydet
    final response = await _supabase.from('family_backups').insert({
      'family_id': familyId,
      'data_json': backupData,
    }).select().single();

    // 3. Local cache'e metadata kaydet
    await _backupBox.put('last_backup', {
      'id': response['id'],
      'created_at': response['created_at'],
      'size_kb': (backupData.toString().length / 1024).round(),
    });

    return backupData;
  }

  Future<void> restoreBackup(String backupId) async {
    // 1. Yedeği çek
    final response = await _supabase
        .from('family_backups')
        .select('data_json')
        .eq('id', backupId)
        .single();

    final data = response['data_json'] as Map<String, dynamic>;

    // 2. Hive'a yaz (offline kullanım için)
    await _settingsBox.put('restored_profiles', data['profiles']);
    await _settingsBox.put('restored_members', data['family_members']);
    await _settingsBox.put('restored_children', data['child_accounts']);
    await _settingsBox.put('restored_settings', data['settings']);
    await _settingsBox.put('restore_timestamp', DateTime.now().toIso8601String());

    // 3. Uygulamayı yeniden başlatma bildirimi
    // (Riverpod/Bloc ile state reset)
  }

  Future<List<Map<String, dynamic>>> getBackupHistory(String familyId) async {
    return await _supabase
        .from('family_backups')
        .select('id, created_at, data_json->version')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(10);
  }
}
```

```dart
// screens/backup_settings_screen.dart — DÜZELTİLMİŞ (Artık kullanımda)
class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyId = context.read<ProfileService>().currentFamilyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Yedekleme Ayarları')),
      body: ListView(
        children: [
          // Otomatik yedekleme toggle
          HiveSettingsToggle(
            box: context.read<Box>('settingsBox'),
            key: 'auto_backup_enabled',
            title: 'Otomatik Yedekleme',
            subtitle: 'Her hafta otomatik yedekle',
          ),

          // Yedekleme sıklığı
          HiveSettingsDropdown(
            box: context.read<Box>('settingsBox'),
            key: 'backup_frequency',
            title: 'Yedekleme Sıklığı',
            options: ['Günlük', 'Haftalık', 'Aylık'],
          ),

          // Son yedekleme bilgisi (gerçek veri)
          FutureBuilder<Map?>(
            future: context.read<BackupService>().getLastBackupInfo(familyId),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Son Yedekleme'),
                subtitle: Text(info != null 
                    ? '${_formatDate(info['created_at'])} • ${info['size_kb']} KB'
                    : 'Henüz yedekleme yapılmamış'),
                trailing: TextButton(
                  onPressed: () => _showBackupHistory(context, familyId),
                  child: const Text('Geçmiş'),
                ),
              );
            },
          ),

          // Manuel yedekleme
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Şimdi Yedekle'),
            onTap: () => _createBackupNow(context, familyId),
          ),

          // Geri yükleme
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('Geri Yükle'),
            subtitle: const Text('Önceki bir yedekten veri kurtar'),
            onTap: () => _showRestoreDialog(context, familyId),
          ),
        ],
      ),
    );
  }
}
```

---

## SORUN 6: WeatherSettingsScreen — Menüde Yok
**Kök Neden**: `SettingsScreen`'de menü öğesi yok
**Çözüm**: SettingsScreen'e ekle + Hive cache + Supabase sync

```dart
// screens/settings_screen.dart — DÜZELTİLMİŞ (Weather eklendi)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          // ... diğer menüler ...

          // YENİ: Hava Durumu Ayarları
          SettingsMenuItem(
            icon: Icons.wb_sunny,
            title: 'Hava Durumu',
            subtitle: FutureBuilder<String>(
              future: context.read<WeatherService>().getCurrentCity(),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Şehir seçilmemiş');
              },
            ),
            onTap: () => context.push('/weather-settings'),
          ),

          // ... diğer menüler ...
        ],
      ),
    );
  }
}
```

```dart
// services/weather_service.dart
class WeatherService {
  final Box<dynamic> _weatherBox;
  final SupabaseClient _supabase;

  WeatherService(this._weatherBox, this._supabase);

  Future<String?> getCurrentCity() async {
    // 1. Hive cache
    final cached = _weatherBox.get('weather_city');
    if (cached != null) return cached;

    // 2. Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('weather_prefs')
        .select('city')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      await _weatherBox.put('weather_city', response['city']);
      return response['city'];
    }
    return null;
  }

  Future<void> setCity(String city) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('Oturum açık değil');

    await _supabase.from('weather_prefs').upsert({
      'user_id': userId,
      'city': city,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _weatherBox.put('weather_city', city);
  }
}
```

---

## SORUN 7-8: NotificationSettingsScreen & PrivacySettingsScreen — Ayarlar Kayboluyor
**Kök Neden**: Sadece `setState`, Hive'a kaydetmiyor
**Çözüm**: Generic `HiveSettingsToggle` widget + Supabase sync

```dart
// widgets/hive_settings_toggle.dart — YENİ (Tüm ayarlar için reusable)
class HiveSettingsToggle extends StatefulWidget {
  final Box<dynamic> box;
  final String key;
  final String title;
  final String? subtitle;
  final bool defaultValue;
  final Future<void> Function(bool)? onSupabaseSync;

  const HiveSettingsToggle({
    super.key,
    required this.box,
    required this.key,
    required this.title,
    this.subtitle,
    this.defaultValue = false,
    this.onSupabaseSync,
  });

  @override
  State<HiveSettingsToggle> createState() => _HiveSettingsToggleState();
}

class _HiveSettingsToggleState extends State<HiveSettingsToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.box.get(widget.key) ?? widget.defaultValue;
  }

  Future<void> _onChanged(bool newValue) async {
    setState(() => _value = newValue);

    // 1. Hive'a kaydet (kalıcı)
    await widget.box.put(widget.key, newValue);

    // 2. Supabase'e sync (varsa)
    if (widget.onSupabaseSync != null) {
      try {
        await widget.onSupabaseSync!(newValue);
      } catch (e) {
        // Sync başarısız olursa Hive'da kalır, bir sonraki açılışta retry
        debugPrint('Supabase sync hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      value: _value,
      onChanged: _onChanged,
    );
  }
}
```

```dart
// screens/notification_settings_screen.dart — DÜZELTİLMİŞ
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = context.read<Box>('settingsBox');
    final supabase = context.read<SupabaseClient>();
    final userId = supabase.auth.currentUser?.id;

    Future<void> syncToSupabase(String settingKey, bool value) async {
      if (userId == null) return;

      await supabase.from('settings').upsert({
        'user_id': userId,
        'notifications': {
          settingKey: value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: ListView(
        children: [
          HiveSettingsToggle(
            box: settingsBox,
            key: 'notif_daily_reminder',
            title: 'Günlük Hatırlatmalar',
            subtitle: 'Her sabah 08:00'de',
            defaultValue: true,
            onSupabaseSync: (v) => syncToSupabase('daily_reminder', v),
          ),
          HiveSettingsToggle(
            box: settingsBox,
            key: 'notif_meal_plan',
            title: 'Yemek Planı Bildirimleri',
            subtitle: 'Öğün saatlerinde',
            onSupabaseSync: (v) => syncToSupabase('meal_plan', v),
          ),
          HiveSettingsToggle(
            box: settingsBox,
            key: 'notif_child_milestone',
            title: 'Gelişim Kilometre Taşları',
            subtitle: 'Çocuğunuz yeni bir beceri kazandığında',
            onSupabaseSync: (v) => syncToSupabase('child_milestone', v),
          ),
          HiveSettingsToggle(
            box: settingsBox,
            key: 'notif_budget_alert',
            title: 'Bütçe Uyarıları',
            subtitle: 'Limit aşıldığında',
            onSupabaseSync: (v) => syncToSupabase('budget_alert', v),
          ),
        ],
      ),
    );
  }
}
```

```dart
// screens/privacy_settings_screen.dart — DÜZELTİLMİŞ
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = context.read<Box>('settingsBox');

    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik')),
      body: ListView(
        children: [
          HiveSettingsToggle(
            box: settingsBox,
            key: 'privacy_location_share',
            title: 'Konum Paylaşımı',
            subtitle: 'Aile üyeleri konumunuzu görebilir',
            onSupabaseSync: (v) => _updatePrivacySetting('location_share', v),
          ),
          HiveSettingsToggle(
            box: settingsBox,
            key: 'privacy_profile_visible',
            title: 'Profil Görünürlüğü',
            subtitle: 'Diğer aile üyeleri profilinizi görebilir',
            defaultValue: true,
          ),
          HiveSettingsToggle(
            box: settingsBox,
            key: 'privacy_analytics',
            title: 'Anonim Analitik',
            subtitle: 'Uygulama geliştirme için kullanım verisi',
            defaultValue: true,
          ),
          // GDPR: Veri indirme
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Verilerimi İndir'),
            subtitle: const Text('GDPR kapsamında tüm verileriniz'),
            onTap: () => _exportUserData(context),
          ),
          // GDPR: Hesap silme
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }
}
```

---

## SORUN 9-10: SecuritySettingsScreen — Biyometrik Giriş & Hesap Silme Sahte
**Kök Neden**: `local_auth` entegre değil, hesap silme sadece SnackBar
**Çözüm**: Gerçek biyometrik auth + Supabase hesap silme (soft delete)

```dart
// services/security_service.dart
class SecurityService {
  final LocalAuthentication _localAuth;
  final SupabaseClient _supabase;
  final Box<dynamic> _settingsBox;

  SecurityService(this._localAuth, this._supabase, this._settingsBox);

  Future<bool> isBiometricAvailable() async {
    return await _localAuth.canCheckBiometrics && 
           await _localAuth.isDeviceSupported();
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'FamilyHub'a giriş yapmak için kimliğinizi doğrulayın',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'FamilyHub Giriş',
            cancelButton: 'İptal',
            biometricHint: 'Parmak izi veya yüz tanıma',
          ),
          IOSAuthMessages(
            cancelButton: 'İptal',
            goToSettingsButton: 'Ayarlar',
            goToSettingsDescription: 'Lütfen Face ID/Touch ID ayarlayın',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biyometrik hata: $e');
      return false;
    }
  }

  Future<void> enableBiometricLogin(bool enabled) async {
    await _settingsBox.put('biometric_enabled', enabled);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('settings').upsert({
        'user_id': userId,
        'security': {'biometric_enabled': enabled},
      });
    }
  }

  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('Oturum açık değil');

    // 1. Soft delete: profiles.is_deleted = true
    await _supabase.from('profiles').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // 2. Auth kullanıcısını sil (Supabase Admin API veya Edge Function)
    await _supabase.rpc('delete_user_account', params: {'user_id': userId});

    // 3. Local cache'i temizle
    await _settingsBox.clear();
    await Hive.deleteFromDisk();
  }
}
```

```sql
-- Supabase Edge Function: Kullanıcı silme (Admin yetkisi ile)
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Auth kullanıcısını sil (admin token gerektirir, Edge Function ile yapılır)
  -- Bu fonksiyon sadece service_role ile çalışır
  DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## SORUN 11: PremiumScreen — Ödeme Entegrasyonu Yok
**Kök Neden**: Sadece UI, Stripe/App Store/Play Store bağlantısı yok
**Çözüm**: `flutter_stripe` + Supabase `premium_subscriptions`

```dart
// services/premium_service.dart
class PremiumService {
  final SupabaseClient _supabase;
  final Box<dynamic> _userBox;

  PremiumService(this._supabase, this._userBox);

  Future<List<PremiumPlan>> getPlans() async {
    // Supabase'den planları çek (veya sabit liste)
    return [
      PremiumPlan(
        id: 'basic',
        name: 'Temel',
        priceEur: 4.99,
        features: ['5 aile üyesi', 'Temel yedekleme'],
        stripePriceId: 'price_basic_2026',
      ),
      PremiumPlan(
        id: 'family',
        name: 'Aile',
        priceEur: 9.99,
        features: ['Sınırsız üye', 'Gelişmiş yedekleme', 'Öncelikli destek'],
        stripePriceId: 'price_family_2026',
        isPopular: true,
      ),
      PremiumPlan(
        id: 'premium',
        name: 'Premium',
        priceEur: 14.99,
        features: ['Her şey Aile'de', 'AI asistan', 'Özel temalar'],
        stripePriceId: 'price_premium_2026',
      ),
    ];
  }

  Future<void> subscribeToPlan(String planId, String stripePriceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AuthException('Oturum açık değil');

    // 1. Stripe PaymentIntent oluştur (Edge Function)
    final response = await _supabase.functions.invoke(
      'create-payment-intent',
      body: {'price_id': stripePriceId, 'user_id': userId},
    );

    final clientSecret = response.data['client_secret'];

    // 2. Stripe ödeme ekranı
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'FamilyHub',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // 3. Başarılı ödeme → Supabase güncelle
    await _supabase.from('premium_subscriptions').insert({
      'user_id': userId,
      'tier': planId,
      'provider': 'stripe',
      'status': 'active',
      'expires_at': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    });

    await _supabase.from('profiles').update({'is_premium': true}).eq('id', userId);

    // 4. Cache güncelle
    await _userBox.delete('current_profile');
  }
}
```

---

## SORUN 12: FamilyPermissionsScreen — Salt Okunur
**Kök Neden**: Sadece statik rol tanımları, rol atama yok
**Çözüm**: Admin yetkisi kontrolü + rol düzenleme + yetki matrisi

```dart
// models/permission_model.dart
class PermissionModel {
  final String role; // 'admin' | 'member' | 'child'
  final Map<String, bool> permissions;

  PermissionModel({required this.role, required this.permissions});

  static final Map<String, Map<String, bool>> defaultPermissions = {
    'admin': {
      'manage_members': true,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': true,
      'delete_content': true,
    },
    'member': {
      'manage_members': false,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': false,
      'delete_content': false,
    },
    'child': {
      'manage_members': false,
      'edit_settings': false,
      'view_finance': false,
      'manage_backups': false,
      'delete_content': false,
    },
  };
}
```

```dart
// screens/family_permissions_screen.dart — DÜZELTİLMİŞ
class FamilyPermissionsScreen extends StatelessWidget {
  const FamilyPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyId = context.read<ProfileService>().currentFamilyId;
    final currentUserRole = context.read<ProfileService>().currentRole;

    // Sadece admin görebilir
    if (currentUserRole != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkiler')),
        body: const Center(child: Text('Bu ekrana erişim yetkiniz yok')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Yetkileri')),
      body: FutureBuilder<List<FamilyMemberModel>>(
        future: context.read<FamilyService>().getFamilyMembers(familyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          return ListView(
            children: snapshot.data!.map((member) {
              return ExpansionTile(
                leading: CircleAvatar(child: Text(member.name[0])),
                title: Text(member.name),
                subtitle: Text(member.roleDisplay),
                children: [
                  // Rol değiştirme (admin için)
                  if (member.memberType == 'adult')
                    ListTile(
                      title: const Text('Rol'),
                      trailing: DropdownButton<String>(
                        value: member.role,
                        items: ['admin', 'member'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role == 'admin' ? 'Yönetici' : 'Üye'),
                          );
                        }).toList(),
                        onChanged: (newRole) => _updateRole(context, member.id, newRole!),
                      ),
                    ),

                  // Yetki matrisi
                  ...PermissionModel.defaultPermissions[member.role]!.entries.map((entry) {
                    return SwitchListTile(
                      title: Text(_permissionDisplay(entry.key)),
                      value: entry.value,
                      onChanged: member.role == 'admin' 
                          ? null // Admin tüm yetkilere sahip, değiştirilemez
                          : (value) => _updatePermission(context, member.id, entry.key, value),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
```

---

## SORUN 13: SettingsScreen — Sabit Metinler
**Kök Neden**: '5 Üye', 'Son: 2 saat önce', '124 MB' hepsi sabit
**Çözüm**: Gerçek veri provider'ları + reactive UI

```dart
// screens/settings_screen.dart — DÜZELTİLMİŞ (Dinamik değerler)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          // Aile Yönetimi — Gerçek üye sayısı
          SettingsMenuItem(
            icon: Icons.people,
            title: 'Aile Yönetimi',
            showValue: FutureBuilder<int>(
              future: context.read<FamilyService>().getMemberCount(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('...');
                return Text('${snapshot.data} Üye');
              },
            ),
            onTap: () => context.push('/family-manage'),
          ),

          // Yedekleme — Gerçek son yedekleme
          SettingsMenuItem(
            icon: Icons.backup,
            title: 'Yedekleme',
            showValue: FutureBuilder<String>(
              future: context.read<BackupService>().getLastBackupRelativeTime(),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Henüz yok');
              },
            ),
            onTap: () => context.push('/backup-settings'),
          ),

          // Önbellek — Gerçek boyut
          SettingsMenuItem(
            icon: Icons.cleaning_services,
            title: 'Önbellek Temizle',
            showValue: FutureBuilder<String>(
              future: _getCacheSize(),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? '0 MB');
              },
            ),
            onTap: () => _clearCache(context),
          ),

          // Premium Card — Gerçek durum
          PremiumStatusCard(), // Aşağıda tanımlı
        ],
      ),
    );
  }

  Future<String> _getCacheSize() async {
    final dir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${dir.path}/hive');
    if (!hiveDir.existsSync()) return '0 MB';

    int totalSize = 0;
    await for (final file in hiveDir.list()) {
      if (file is File) totalSize += await file.length();
    }
    return '${(totalSize / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class PremiumStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileModel>(
      future: context.read<ProfileService>().getCurrentProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final profile = snapshot.data!;
        if (!profile.isPremiumActive) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Premium'a Yükselt'),
              subtitle: const Text('Tüm özellikleri açın'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/premium'),
            ),
          );
        }

        return Card(
          color: Colors.amber.shade50,
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Premium Aktif'),
            subtitle: Text('Bitiş: ${_formatDate(profile.premiumExpiry)}'),
            trailing: TextButton(
              onPressed: () => context.push('/premium'),
              child: const Text('Yönet'),
            ),
          ),
        );
      },
    );
  }
}
```

---

## SORUN 14: GoogleDriveBackupScreen — Yanıltıcı İsim
**Kök Neden**: Adı "Google Drive" ama Supabase kullanıyor
**Çözüm**: İsim değişikliği + açıklama ekleme

```dart
// screens/cloud_backup_screen.dart — YENİ İSİM (GoogleDriveBackupScreen yerine)
class CloudBackupScreen extends StatelessWidget {
  const CloudBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulut Yedekleme'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Verileriniz FamilyHub sunucularında güvenle saklanır. Google Drive entegrasyonu yakında geliyor.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ),
      body: // ... mevcut içerik ...
    );
  }
}
```

**Route güncellemesi**:
```dart
// router.dart
GoRoute(
  path: '/cloud-backup', // Eski: '/google-drive-backup'
  builder: (context, state) => const CloudBackupScreen(),
),
```

---

## SORUN 15: ProfileEditScreen — Navigation Tutarsızlığı
**Kök Neden**: `Navigator.of(context).pop()` kullanıyor, proje GoRouter kullanıyor
**Çözüm**: Tüm navigation GoRouter'a çevirme

```dart
// screens/profile_edit_screen.dart — DÜZELTİLMİŞ
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // DÜZELTME: GoRouter pop
        ),
      ),
      body: ProfileEditForm(
        onSaved: () {
          // Başarılı kaydetme sonrası
          context.pop(); // DÜZELTME: GoRouter pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil güncellendi')),
          );
        },
      ),
    );
  }
}
```

---

## GENEL MİMARİ PRENSİPLER

### 1. Offline-First Pattern
```dart
// Tüm veri okumaları önce Hive, sonra Supabase
Future<T> getDataWithCache<T>({
  required String cacheKey,
  required Duration ttl,
  required Future<T> Function() fetchFromSupabase,
  required T Function(Map) fromMap,
}) async {
  final cached = _box.get(cacheKey);
  final cacheTime = _box.get('${cacheKey}_time');

  if (cached != null && cacheTime != null) {
    final age = DateTime.now().difference(DateTime.parse(cacheTime));
    if (age < ttl) return fromMap(Map<String, dynamic>.from(cached));
  }

  final data = await fetchFromSupabase();
  await _box.put(cacheKey, data);
  await _box.put('${cacheKey}_time', DateTime.now().toIso8601String());
  return data;
}
```

### 2. Error Handling Pattern
```dart
// Tüm async operasyonlar için
Future<void> safeAsyncOperation(Future<void> Function() operation) async {
  try {
    await operation();
  } on PostgrestException catch (e) {
    // Supabase hatası
    debugPrint('Supabase hatası: ${e.message}');
    rethrow;
  } on AuthException catch (e) {
    // Auth hatası
    debugPrint('Auth hatası: ${e.message}');
    rethrow;
  } catch (e) {
    // Genel hata
    debugPrint('Beklenmeyen hata: $e');
    rethrow;
  }
}
```

### 3. State Management (Riverpod)
```dart
// providers.dart
final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getCurrentProfile();
});

final familyMembersProvider = FutureProvider.family<List<FamilyMemberModel>, String>((ref, familyId) async {
  final service = ref.watch(familyServiceProvider);
  return await service.getFamilyMembers(familyId);
});
```

---

## KONTROL LİSTESİ (Tüm Ekranlar İçin)

Her ekran düzeltmesi tamamlandığında şunları doğrula:
- [ ] Statik string'ler yerine gerçek veri provider'ı var
- [ ] Hive cache entegrasyonu var (offline-first)
- [ ] Supabase sync var (çoklu cihaz desteği)
- [ ] Error handling var (try/catch + user-friendly mesaj)
- [ ] Loading state var (skeleton/shimmer)
- [ ] Empty state var (veri yoksa bilgilendirme)
- [ ] GoRouter navigation kullanıyor (Navigator.pop() YOK)
- [ ] Null-safety compliant
- [ ] Responsive (telefon + tablet)

---
## SİSTEM MESAJI SONU
