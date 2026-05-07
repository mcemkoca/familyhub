# SPRINT 3: FONKSIYONEL TAMAMLAMA
## 7 Yuksek Oncelikli Sorun | Hedef: Tum Ozellikler Calisiyor

---

## 11. Health Card — Supabase Sync

**Sorun:** Sadece local, Supabase sync yok

### supabase/migrations/049_health_cards.sql
```sql
CREATE TABLE IF NOT EXISTS health_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    blood_type VARCHAR(5),
    allergies TEXT[] DEFAULT '{}',
    chronic_diseases TEXT[] DEFAULT '{}',
    medications JSONB DEFAULT '[]',
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    special_notes TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE health_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own health card"
ON health_cards FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
```

### lib/features/health/services/health_card_service.dart
```dart
class HealthCardService {
  final SupabaseClient _client = SupabaseConfig.safeClient;
  final LocalCache _cache = LocalCache();

  Future<HealthCard?> getHealthCard() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('health_cards')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final card = HealthCard.fromJson(response);
        await _cache.set('health_card_${user.id}', card.toJson());
        return card;
      }

      final cached = await _cache.get('health_card_${user.id}');
      return cached != null ? HealthCard.fromJson(cached) : null;

    } catch (e) {
      final cached = await _cache.get('health_card_${user.id}');
      return cached != null ? HealthCard.fromJson(cached) : null;
    }
  }

  Future<void> saveHealthCard(HealthCard card) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('Oturum yok');

    final data = {
      'user_id': user.id,
      ...card.toJson(),
      'last_updated': DateTime.now().toIso8601String(),
    };

    await _client.from('health_cards').upsert(data);
    await _cache.set('health_card_${user.id}', card.toJson());
  }
}
```

---

## 12. Smart Rotation — Supabase'e Kaydetme

**Sorun:** Atamalar Supabase'e kaydedilmiyor

### lib/features/tasks/services/smart_rotation_service.dart
```dart
class SmartRotationService {
  final SupabaseClient _client = SupabaseConfig.safeClient;
  final FairnessEngine _engine = FairnessEngine();

  Future<void> generateAndSaveAssignments({
    required DateTime date,
    required String familyId,
  }) async {
    final tasks = await _getTasksForDate(date);
    final members = await _getFamilyMembers(familyId);

    final assignments = _engine.distributeTasks(
      tasks: tasks,
      members: members,
      date: date,
    );

    final batchData = assignments.map((a) => {
      'task_id': a.taskId,
      'assigned_to': a.assignedTo,
      'assigned_date': date.toIso8601String().split('T')[0],
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await _client.from('task_assignments').insert(batchData);
  }

  Future<List<TaskAssignment>> getAssignmentsForDate(DateTime date) async {
    final response = await _client
        .from('task_assignments')
        .select('*, household_tasks(*)')
        .eq('assigned_date', date.toIso8601String().split('T')[0])
        .order('created_at', ascending: true);

    return (response as List).map((e) => TaskAssignment.fromJson(e)).toList();
  }
}
```

---

## 13. Calendar Sync — Gercek API

**Sorun:** Sadece sayac artiriyor, veri tasinmiyor

### lib/features/calendar/services/calendar_sync_service.dart
```dart
class CalendarSyncService {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  Future<SyncResult> syncWithGoogleCalendar() async {
    try {
      final googleEvents = await _fetchGoogleCalendarEvents();
      final localEvents = await _fetchLocalEvents();

      final toAdd = googleEvents.where((e) => 
          !localEvents.any((l) => l.googleId == e.id));

      final toUpdate = googleEvents.where((e) => 
          localEvents.any((l) => l.googleId == e.id && 
          l.updatedAt.isBefore(e.updatedAt)));

      if (toAdd.isNotEmpty) {
        await _client.from('calendar_events').insert(
          toAdd.map((e) => e.toSupabaseJson()).toList(),
        );
      }

      if (toUpdate.isNotEmpty) {
        for (final event in toUpdate) {
          await _client.from('calendar_events')
              .update(event.toSupabaseJson())
              .eq('google_id', event.id);
        }
      }

      return SyncResult(
        added: toAdd.length,
        updated: toUpdate.length,
        success: true,
      );

    } catch (e) {
      return SyncResult(error: e.toString(), success: false);
    }
  }

  Future<List<GoogleCalendarEvent>> _fetchGoogleCalendarEvents() async {
    final auth = await _getGoogleAuth();
    final calendarApi = calendar.CalendarApi(auth);

    final events = await calendarApi.events.list(
      'primary',
      timeMin: DateTime.now().toUtc(),
      maxResults: 100,
    );

    return events.items?.map((e) => 
        GoogleCalendarEvent.fromGoogle(e)).toList() ?? [];
  }
}

class SyncResult {
  final int added;
  final int updated;
  final bool success;
  final String? error;

  SyncResult({this.added = 0, this.updated = 0, 
              required this.success, this.error});
}
```

---

## 14. Crash SOS — Tam Implementasyon

**Sorun:** Alarm/SMS/112 arama tamamen TODO/empty

### lib/features/safety/services/crash_detection_service.dart
```dart
class CrashDetectionService {
  final SafetyRepository _safetyRepo = SafetyRepository();
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final CallService _callService = CallService();

  Future<void> handleCrashDetected() async {
    // 1. Konum al
    final position = await _locationService.getCurrentPosition();

    // 2. Acil durum kisilerini cek
    final emergencyContacts = await _safetyRepo.getEmergencyContacts();

    // 3. SMS gonder (tum acil durum kisilerine)
    for (final contact in emergencyContacts) {
      await _smsService.sendSms(
        phoneNumber: contact.phone,
        message: '🚨 KAZA ALGILANDI! Konum: '
            'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      );
    }

    // 4. Alarm cal (max volume)
    await _playEmergencyAlarm();

    // 5. Countdown baslat (30 saniye)
    final userCancelled = await _showCancelCountdown();

    if (!userCancelled) {
      // 6. 112'yi ara
      await _callService.callEmergency('112');
    }
  }

  Future<void> _playEmergencyAlarm() async {
    await AudioService.playAlarmSound(
      soundAsset: 'assets/sounds/emergency_alarm.mp3',
      loop: true,
      volume: 1.0,
    );
  }

  Future<bool> _showCancelCountdown() async {
    bool cancelled = false;

    await showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => EmergencyCountdownDialog(
        seconds: 30,
        onCancel: () {
          cancelled = true;
          AudioService.stopAlarm();
          Navigator.pop(context);
        },
      ),
    );

    return cancelled;
  }
}
```

---

## 15. Premium Sistem Birlestir

**Sorun:** Cift sistem (Stripe + RevenueCat) cakisiyor, bitis tarihi kontrol edilmiyor

### lib/features/premium/services/premium_service.dart
```dart
class PremiumService {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  /// Tek kaynak: Supabase subscriptions tablosu
  Future<bool> isPremium() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .gte('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    return response != null;
  }

  Future<void> upgradeToPremium(String planId) async {
    // 1. Odeme gateway'ine git
    final paymentResult = await _processPayment(planId);
    if (!paymentResult.success) {
      throw PaymentException('Odeme basarisiz: ${paymentResult.error}');
    }

    // 2. Odeme dogrulamasi
    final verified = await _verifyPayment(paymentResult.paymentIntentId);
    if (!verified) {
      throw PaymentException('Odeme dogrulanamadi');
    }

    // 3. Supabase'e kaydet (SADECE dogrulama sonrasi)
    final now = DateTime.now();
    await _client.from('subscriptions').upsert({
      'user_id': _client.auth.currentUser!.id,
      'plan_id': planId,
      'status': 'active',
      'started_at': now.toIso8601String(),
      'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
      'payment_provider': paymentResult.provider,
      'payment_id': paymentResult.paymentIntentId,
    });
  }

  Future<PaymentResult> _processPayment(String planId) async {
    // RevenueCat entegrasyonu (tek odeme sistemi)
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages
          .firstWhere((p) => p.identifier == planId);

      if (package == null) throw Exception('Plan bulunamadi');

      final customerInfo = await Purchases.purchasePackage(package);
      return PaymentResult(
        success: customerInfo.entitlements.active.isNotEmpty,
        provider: 'revenuecat',
        paymentIntentId: customerInfo.originalAppUserId,
      );
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<bool> _verifyPayment(String paymentId) async {
    // RevenueCat server-side verification
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.isNotEmpty;
  }
}
```

---

## 16. HubRepository — .subscribe() Ekle

**Sorun:** Realtime calismiyor

### lib/features/hub/repositories/hub_repository.dart
```dart
class HubRepository {
  final SupabaseClient _client = SupabaseConfig.safeClient;
  RealtimeChannel? _channel;

  Stream<List<HubEvent>> watchHubEvents() {
    _channel = _client
        .channel('hub_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hub_events',
          callback: (payload) {
            // Event handling
          },
        )
        .subscribe();  // ← BU SATIR EKLENDI

    return _client
        .from('hub_events')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => HubEvent.fromJson(e)).toList());
  }

  void dispose() => _channel?.unsubscribe();
}
```

---

## 17. Tum Repository'lere try/catch Ekle

**Sorun:** Event, Task, Chat, Budget, Calendar, Child*, Contacts, Crash* vb. try/catch yok

### lib/core/utils/repository_mixin.dart
```dart
mixin RepositoryErrorHandler {
  Future<T> handleRepositoryCall<T>(
    Future<T> Function() call, 
    String operation,
  ) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        'Veritabani hatasi [$operation]: ${e.message}',
        code: e.code,
      );
    } on SocketException catch (_) {
      throw RepositoryException(
        'Internet baglantisi yok [$operation]',
        isOffline: true,
      );
    } on AuthException catch (e) {
      throw RepositoryException(
        'Oturum hatasi [$operation]: ${e.message}',
        isAuthError: true,
      );
    } catch (e) {
      throw RepositoryException(
        'Beklenmeyen hata [$operation]: $e',
      );
    }
  }
}

class RepositoryException implements Exception {
  final String message;
  final String? code;
  final bool isOffline;
  final bool isAuthError;

  RepositoryException(
    this.message, {
    this.code,
    this.isOffline = false,
    this.isAuthError = false,
  });

  @override
  String toString() => message;
}
```

### Kullanim ornegi:
```dart
class EventRepository with RepositoryErrorHandler {
  final SupabaseClient _client = SupabaseConfig.safeClient;

  Future<List<Event>> getEvents() async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from('events')
          .select('*')
          .order('date', ascending: true);
      return (response as List).map((e) => Event.fromJson(e)).toList();
    }, 'getEvents');
  }

  Future<void> createEvent(Event event) async {
    return handleRepositoryCall(() async {
      await _client.from('events').insert(event.toJson());
    }, 'createEvent');
  }
}
```

---

## Kontrol Listesi

- [ ] Health Card Supabase'e sync ediyor
- [ ] Smart Rotation atamalari kaydediyor
- [ ] Calendar Sync gercek Google Calendar API kullaniyor
- [ ] Crash SOS SMS/Alarm/112 calisiyor
- [ ] Premium tek sistem (RevenueCat) + odeme dogrulama
- [ ] HubRepository .subscribe() cagriliyor
- [ ] Tum repository'ler try/catch ile korunuyor

---
**Versiyon:** 1.0 | **Sprint:** 3/4 | **Hedef:** Tum Ozellikler Calisiyor
