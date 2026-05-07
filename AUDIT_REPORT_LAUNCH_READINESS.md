# FamilyHub — Ürün Çıkışı Eksiklik ve Hata Raporu
> Kapsamlı Kod, Tasarım, Fonksiyon ve Veri Denetimi
> Tarih: 2026-05-05

---

## 🔴 KRİTİK SEVİYE (Uygulama Çöker, Store Reddedilir veya Güvenlik Açığı)

### 1. `app_links` Bağımlılığı Eksik → Derleme/Runtime Hatası
- **Dosya:** `lib/services/deep_link_service.dart` `package:app_links/app_links.dart` import ediyor
- **Ama** `pubspec.yaml`'da `app_links` paketi **yok**
- **Sonuç:** Derleme başarısız olur veya runtime'da `MissingPluginException`/`NoSuchMethodError`

### 2. `firebase_options.dart` Gerçek API Key İçeriyor
- **Dosya:** `lib/firebase_options.dart:44`
- `android.apiKey = 'AIzaSyAbsV-yuJ6vXsoA0jkEw-MgFeMffLA9x5U'` → **gerçek Firebase API key formatında**
- **Sonuç:** APK/IPA içinde secret exposure. GitHub'a push edilmişse public repo'da yayında.
- **Çözüm:** `flutterfire configure` ile yeniden üret, `.gitignore`'a ekle, `dart-define` ile enjekte et.

### 3. iOS Info.plist — App Store Red Sebepleri
**Eksik Usage Descriptions:**
| İzin | Açıklama |
|------|----------|
| `NSLocationWhenInUseUsageDescription` | Konum tabanlı hava durumu ve güvenlik özellikleri var |
| `NSLocationAlwaysUsageDescription` | Arka plan konum takibi var |
| `NSContactsUsageDescription` | `flutter_contacts` kullanılıyor |
| `NSPhotoLibraryUsageDescription` | `image_picker` ve `photo_manager` kullanılıyor |
| `NSSpeechRecognitionUsageDescription` | `speech_to_text` kullanılıyor |
| `NSFaceIDUsageDescription` | `local_auth` Face ID desteği var |

**Eksik Background Modes:**
- `UIBackgroundModes` tamamen yok. Gerekli olanlar:
  - `location` (konum takibi)
  - `audio` (ambient listening)
  - `fetch` (arka plan senkronizasyonu)
  - `remote-notification` (FCM)
  - `voip` (WebRTC sesli arama)

**Google Sign-In Placeholder:**
- `GIDClientID = "YOUR_CLIENT_ID"` → iOS'ta Google Sign-In çalışmaz.
- `CFBundleURLSchemes` → `com.googleusercontent.apps.YOUR_CLIENT_ID`

### 4. Android Release Build — Debug Signing
- **Dosya:** `android/app/build.gradle.kts`
- `signingConfig = signingConfigs.getByName("debug")` → **release build debug imzasıyla oluşuyor**
- **Sonuç:** Play Store'a yüklenemez. `jarsigner` ile imzalanması gerekir.

### 5. `mood_entries` Tablosu Yok → Runtime Crash
- **Dosya:** `lib/repositories/mood_repository.dart`
- `SupabaseConfig.safeClient!.from('mood_entries')` çağrısı yapılıyor
- **Ama** `supabase/migrations/` içinde `mood_entries` için **hiçbir `CREATE TABLE` yok**
- **Sonuç:** Uygulama `mood_entries` okumaya/yazmaya çalıştığında **PostgrestException** → crash

### 6. Chat Tamamen Local — Supabase'a Gitmiyor
- **Dosya:** `lib/presentation/screens/chat/chat_screen.dart`
- `chatMessagesProvider` sadece `StateProvider<List<ChatMessage>>((ref) => [])`
- Mesajlar **hiçbir zaman** `ChatRepository`'ye gitmiyor
- `ChatRepository` (Supabase realtime stream) var ama ekran onu kullanmıyor
- **Sonuç:** Sohbet cihaz hafızasında, yeniden başlatınca siliniyor, aile üyeleri birbirinin mesajlarını göremiyor

### 7. Family Screen — Sahte (Local-Only) CRUD
- **Dosya:** `lib/presentation/screens/family/family_screen.dart`
- `_handleRoleChange()` ve `_handleRemove()` sadece local provider state değiştiriyor
- ```dart
  ref.read(familyMembersProvider.notifier).state = newList; // Supabase çağrısı YOK
  ```
- **Sonuç:** Kullanıcı "rol değiştirdi"/"üyeyi çıkardı" sanıyor ama Supabase'de hiçbir şey değişmiyor. Yeniden giriş yapınca eski haline dönüyor.
- **Ayrıca:** `_isAdmin` mantığı bozuk — her zaman listedeki ilk üyeyi döndürüyor, current user değil

### 8. Location Screen — Hardcoded Sahte Veri
- **Dosya:** `lib/presentation/screens/safety/location_screen.dart`
- Aile üyesi konumları **hardcoded**:
  ```dart
  _LocationRow(name: 'Üye 1', status: 'Evde', ...),
  _LocationRow(name: 'Üye 2', status: 'İşte', ...),
  _LocationRow(name: 'Üye 3', status: 'Okulda', ...)
  ```
- **Sonuç:** Gerçek aile üyesi konumları gösterilmiyor.

### 9. Biometric Fallback PIN Tamamen Bozuk
- **Dosya:** `lib/services/biometric_service.dart:45-48`
- `_validatePin()` **her zaman `false` döndürüyor**
- ```dart
  // In production, compare against secure storage hash
  return false;
  ```
- **Sonuç:** Biyometrik başarısız olunca PIN ile giriş imkansız.

### 10. Child Login — Aile Filtresi Yok (Güvenlik Açığı)
- **Dosya:** `lib/presentation/screens/auth/child_login_screen.dart`
- `userId == null` olduğunda:
  ```dart
  await SupabaseConfig.safeClient?.from('child_accounts')
      .select('id, name, avatar_url')
      .eq('is_active', true)
      .limit(20);
  ```
- **Aile filtresi (`family_id`) yok!** Auth'sız herhangi bir kullanıcı **tüm ailelerin çocuklarını** görebilir.
- **Sonuç:** Büyük veri sızıntısı / gizlilik ihlali.

### 11. Child PIN Plaintext Saklanıyor
- **Dosya:** `lib/presentation/screens/auth/steps/children_step.dart:47`
- `'pin_hash': child['pin_hash']` — burada `pin_hash` aslında **düz metin PIN**
- `ChildAuthService.hashPin()` var ama **hiçbir yerde çağrılmıyor**
- **Sonuç:** Çocuk PIN'leri Supabase'de plaintext. Veri sızıntısında açığa çıkar.

### 12. Splash Screen — `ChildAuthService` Import Eksik
- **Dosya:** `lib/presentation/screens/auth/splash_screen.dart`
- `ChildAuthService.restoreSession()`, `ChildAuthService.isChildMode` kullanılıyor
- **Ama import satırı yok!**
- **Sonuç:** `dart analyze` sıfır veriyor muhtemelen transitif import var, ama ileride derleme/regresyon riski yüksek.

---

## 🟠 YÜKSEK SEVİYE (Önemli Fonksiyonel Eksiklik / Bozuk Akış)

### 13. Health Card — Sadece Local, Supabase Sync Yok
- `HealthCardService` sadece `FlutterSecureStorage` kullanıyor
- `AuthService.updateProfile()` aynı verileri (`blood_type`, `allergies`, `emergency_contact`) Supabase `profiles`'a yazabiliyor
- **Ama iki sistem arasında köprü yok.** Sağlık kartı ekranı local, profil ekranı Supabase.
- **Sonuç:** Sağlık kartı verileri cihaz değişince kaybolur, aile üyeleriyle paylaşılmaz.

### 14. Smart Rotation — Atamalar Supabase'e Kaydedilmiyor
- **Dosya:** `lib/presentation/screens/organizer/smart_rotation_screen.dart`
- `_runRotation()` `SmartRotationService.distributeTasks()` ile atama hesaplıyor
- `_acceptAssignment()` ve `_rejectAssignment()` sadece local `_tasks` listesini değiştiriyor
- **Sonuç:** AI akıllı dağılım hesaplanıyor ama kabul/reddet butonları veritabanına yazmıyor.

### 15. Calendar Sync — Sahte Sync (Sadece Sayaç)
- **Dosya:** `lib/services/calendar_sync_service.dart`
- `syncCalendar()` cihaz takviminden etkinlikleri çekiyor, karşılaştırıyor, `added/updated/deleted` sayıyor
- **Ama** `CalendarRepository`'ye yazmıyor, cihaz takvimine yazmıyor
- **Sonuç:** "Senkronize edildi" SnackBar'ı çıkıyor ama hiçbir veri taşınmıyor.

### 16. Crash Detection — Alarm/SOS/Telefon Arayışı Boş
- **Dosya:** `lib/services/crash_detection_service.dart`
- `_triggerAlarm()`: Sadece `HapticFeedback` — ses alarmı, max volume, ekran flaşı **TODO**
- `_stopAlarm()`: **Boş**
- `_notifyEmergencyContacts()`: Döngü var ama SMS/arama **TODO**
- `_startLocationSharing()`: **Boş**
- `_callEmergencyServices()`: **Boş**
- `_shareMedicalInfo()`: **Boş**
- **Sonuç:** Kaza tespiti çalışıyor ama hiçbir acil durum eylemi gerçekleşmiyor.

### 17. Emergency Auto Actions Engine — Tamamen Stub
- **Dosya:** `lib/services/emergency_auto_actions_engine.dart`
- `_executeEscalationStep()`: Tüm 5 `EscalationAction` case'i **boş `break`**
- `_checkUserResponse()`: **Hardcoded `return false`**
- `_startAudioRecording()`: **Boş TODO**
- `_getTemplate()`: Hardcoded template, repository'den yükleme **TODO**
- **Sonuç:** Acil durum otomasyonu hiçbir şey yapmıyor.

### 18. Smart Reminder Background Service — Tamamen Stub
- **Dosya:** `lib/services/smart_reminder_background_service.dart`
- `initialize()`, `scheduleReminder()`, `cancelReminder()` hepsi **boş no-op**
- `main.dart` bunu kaydediyor ama hiçbir şey yapmıyor
- **Sonuç:** Akıllı hatırlatıcılar arka planda çalışmıyor.

### 19. Premium Sistemi — Çifte Çatışma ve Güvenlik Açığı

**A. Çift Ödeme Sistemi:**
- `PaymentService` (Stripe) ve `SubscriptionService` (RevenueCat) birbiriyle koordineli değil

**B. Stale Premium Check:**
- `SubscriptionService._isPremium()` `auth.userMetadata`'dan okuyor
- Ama `purchasePackage()` Supabase `profiles` tablosuna yazıyor
- `userMetadata` asla güncellenmiyor → feature gate'ler yanlış değer döndürür

**C. Ücretsiz Premium:**
- `AuthService.upgradeToPremium()` doğrudan `is_premium = true` yazıyor
- **Hiçbir ödeme doğrulaması yok!** UI'dan çağrılırsa bedava premium

**D. Bitiş Tarihi Kontrolü Yok:**
- `subscription_expires_at` hiçbir yerde `DateTime.now()` ile karşılaştırılmıyor
- Süresi dolan kullanıcı hâlâ premium görünür

### 20. `ErrorService.initialize()` `runApp()`'dan Sonra Çağrılıyor
- **Dosya:** `lib/main.dart:225`
- ```dart
  runApp(ProviderScope(...));
  ErrorService.initialize(); // SONRA
  ```
- **Sonuç:** İlk frame'lerdeki hatalar (router hatası, provider hatası) yakalanmaz.

### 21. `HubRepository.subscribeToHub()` `.subscribe()` Çağırmıyor
- **Dosya:** `lib/repositories/hub_repository.dart`
- ```dart
  return _safeClient!
      .channel('hub:$familyId')
      .onPostgresChanges(...)
      .onPostgresChanges(...);
  // .subscribe() EKSİK!
  ```
- **Sonuç:** Realtime kanalı oluşturuluyor ama asla dinlenmeye başlanmıyor. Hub anlık güncelleme almıyor.

### 22. `FamilyMembersRepository.watchMembers()` Yanlış Primary Key
- **Dosya:** `lib/repositories/family_members_repository.dart`
- ```dart
  .stream(primaryKey: ['family_id', 'user_id'])
  ```
- Ama migration `027_add_id_to_family_members.sql` ile tablonun PK'sı `id`
- **Sonuç:** Realtime stream tutarsız çalışır veya çöker.

### 23. `BackupRepository` Tüm Ailelerin Backup'ını Stream Ediyor
- **Dosya:** `lib/repositories/backup_repository.dart`
- ```dart
  return _client.from('family_backups').stream(primaryKey: ['id'])
  ```
- `family_id` filtresi yok! Client-side filtering yapmaya çalışıyor
- **Sonuç:** Her cihaz **tüm ailelerin** yedek metadata'sını alıyor.

### 24. `LiveSupportService` Yanlış Tabloyu İzliyor
- **Dosya:** `lib/services/live_support_service.dart`
- `watchMessages()` `support_sessions` tablosunu stream ediyor
- Ama mesajlar `messages` JSONB alanında
- **Sonuç:** "Mesaj izleme" aslında session satırının tekrar tekrar emit edilmesi.

### 25. Repository'lerin Çoğunda Try/Catch Yok
Aşağıdaki repository'lerin tüm CRUD metodları **try/catch içermiyor:**
- `EventRepository`, `TaskRepository`, `ChatRepository`, `BudgetRepository`, `CalendarRepository`
- `HouseholdTaskRepository`, `ChildAccountRepository`, `ChildChatRepository`
- `ChildDevelopmentRepository`, `ChildHomeworkRepository`, `ChildLocationRepository`
- `ChildScheduleRepository`, `ChildStreakRepository`, `ChildTaskRepository`
- `ContactsRepository`, `CrashEventRepository`, `CrashSettingsRepository`
- `EmergencyActionRepository`, `ContextSnapshotRepository`, `RoutineRepository`
- `ReminderInteractionRepository`, `SafeArrivalRepository`, `ShoppingRepository`
- `SmartReminderRepository`

**Sonuç:** Herhangi bir Supabase bağlantı hatası, RLS reddi veya network kesintisi uygulamayı çökertir.

### 26. `EmergencyScreen` Gerçek SOS Göndermiyor
- **Dosya:** `lib/presentation/screens/safety/emergency_screen.dart`
- 3 saniye basılı tutma animasyonu var
- Sadece diyalog gösteriyor: "Acil durum bildirimi ailene gönderildi"
- **Ama** `EmergencyService.sendSOSAlert()` **çağrılmıyor**
- **Sonuç:** Kullanıcı acil durum butonuna bastığını sanıyor ama hiçbir şey olmuyor.

### 27. `BatteryAwareLocationTracker` Batch Upload Yok
- **Dosya:** `lib/services/battery_aware_location_tracker.dart`
- `_flushBatch()` konum segmentini oluşturuyor ama Supabase'e yazma **TODO**
- `LocationTrackingRepository.insertBatch()` hazır ama **kimse çağırmıyor**

### 28. Registration Wizard — Boş Catch Blokları
- **Dosya:** `lib/presentation/screens/auth/registration_wizard_screen.dart`
- `_saveProfileData()`, `_saveParentRoleData()`, `_saveHealthData()` → **boş catch `{}`**
- **Sonuç:** Profil/rol/sağlık verisi kaydedilemese bile kullanıcı habersiz, wizard devam eder.

### 29. `children_step.dart` ve `safe_zones_step.dart` — Boş Catch
- Benzer şekilde child insert ve safe zone insert hataları yutuluyor.

### 30. `BiometricService.authenticateWithFallback()` — PIN Hiç Çalışmaz
- Biyometrik başarısız olunca PIN fallback'e geçiyor
- Ama `_validatePin()` her zaman `false` → **sonsuz döngüye giriyor** muhtemelen

---

## 🟡 ORTA SEVİYE (Kullanıcı Deneyimi, Tasarım Eksiklikleri, Veri Tutarsızlığı)

### 31. Lokalizasyon (Localization) Tamamen Yok
- **Proje geneli:** 42+ ekranda **hiçbir `.arb` dosyası yok**, `l10n.yaml` yok, `flutter_localizations` paketi yok
- Tüm metinler hardcoded Türkçe: `'Aile Sohbeti'`, `'Merhaba,'`, `'Görevlerim'`, `'Aile Ruh Hali'`...
- **Sonuç:** Uygulama sadece Türkçe çalışır. İngilizce seçeneği `LanguageSettingsScreen`'de var ama **locale değiştirmiyor**.

### 32. `LanguageSettingsScreen` Locale Değiştirmiyor
- **Dosya:** `lib/presentation/screens/settings/language_settings_screen.dart`
- Dil seçimi Hive'e kaydediliyor ama `MaterialApp.locale` veya `Localizations` güncellenmiyor
- **Sonuç:** İngilizce seçildiğinde bile tüm UI Türkçe kalıyor.

### 33. Theme Eksik Token'lar
- **Dosya:** `lib/config/theme.dart`
- Eksik tema tanımları:
  - `snackBarTheme`, `bottomSheetTheme`, `textButtonTheme`, `outlinedButtonTheme`
  - `chipTheme`, `progressIndicatorTheme`, `tooltipTheme`, `popupMenuTheme`
  - `navigationBarTheme`, `tabBarTheme`, `radioTheme`, `sliderTheme`, `iconTheme`
- **Sonuç:** Bu widget'lar default Material 2/3 renklerine düşer, tema tutarsızlığı oluşur.

### 34. AndroidManifest.xml Eksik İzinler
| Eksiz İzin | Gerekçe |
|------------|---------|
| `ACTIVITY_RECOGNITION` | Crash detection accelerometer |
| `HIGH_SAMPLING_RATE_SENSORS` | Android 12+ accelerometer >200Hz |
| `WAKE_LOCK` | SOS ekranı açık kalma |
| `READ_PHONE_STATE` | Telefon entegrasyonu |
| `FOREGROUND_SERVICE_MICROPHONE` | Ambient listening arka plan |
| `FOREGROUND_SERVICE_DATA_SYNC` | Arka plan senkronizasyonu |
| `android:enableOnBackInvokedCallback="true"` | Android 13+ predictive back |

### 35. Proguard Kuralları Eksik
- **Dosya:** `android/app/proguard-rules.pro`
- Eksik:
  - Crashlytics için `-keepattributes LineNumberTable`, `-keepattributes SourceFile`
  - `flutter_contacts` için keep rules
- Gereksiz:
  - `device_info_plus` keep rule var ama paket `pubspec.yaml`'da yok

### 36. Background Servisler `main.dart`'ta Başlatılmıyor
Aşağıdaki servisler `startMonitoring()` / `startTracking()` metodlarına sahip ama **hiçbir yerde çağrılmıyor:**
- `LocationTrackingService` — periyodik konum upload
- `CrashDetectionService` — kaza tespiti dinleme
- `SafetyService` — güvenlik monitoring
- `BatteryAwareLocationTracker` — akıllı konum takibi
- `AmbientListeningService` — sallama algılama (initShakeDetection)
- `CallService` — gelen arama dinleyici

**Sonuç:** Tüm bu "arka plan" özellikler manuel UI tetiklemesi olmadan çalışmaz.

### 37. Workmanager YOK
- `pubspec.yaml`'da `workmanager` yok
- `SmartReminderBackgroundService` yorumunda `workmanager ^1.0.0+` bekleniyor
- **Sonuç:** Periyodik arka plan işleri (hava durumu güncelleme, hatırlatıcı kontrolü) yapılamıyor.

### 38. `lottie` ve `vibration` Kullanılmayan Bağımlılıklar
- `lottie: ^3.3.0` → `lib/` içinde **hiç import yok**
- `vibration: ^3.1.3` → `lib/` içinde **hiç import yok** (kod `VibrationPattern` enum'u kullanıyor ama paketi import etmiyor)
- **Sonuç:** APK boyutu şişiyor, gereksiz.

### 39. `household_tasks.json` Asset Olarak Tanımlı Değil
- **Dosya:** `assets/data/household_tasks.json` (300 kayıt)
- **Ama** `pubspec.yaml`'da `assets/data/` altında **yok**
- Kod içinde `rootBundle.loadString('assets/data/household_tasks.json')` çağrısı olursa **AssetNotFoundException**

### 40. `version: 0.1.0+1` Çok Düşük
- `pubspec.yaml:4` → Production release için uygun değil.

### 41. Onboarding Content Hardcoded
- **Dosya:** `lib/presentation/screens/auth/onboarding_screen.dart`
- 3 slayt title, description, image path hardcoded
- **Sonuç:** Remote A/B test, güncelleme, lokalizasyon imkansız.

### 42. Safe Zones Default Konumu Frankfurt
- **Dosya:** `lib/presentation/screens/auth/steps/safe_zones_step.dart`
- Default lat/lng = `50.1109, 8.6821` (Almanya/Frankfurt merkezi)
- **Sonuç:** Kullanıcı konum izni vermeden önce harita Frankfurt'ta açılır.

### 43. `AuthService.signUp()` Kısmi Durum (Partial State)
- Aile oluşturulup `family_members` insert edildikten sonra `profiles` upsert başarısız olursa
- Aile var ama kullanıcının profili yok → **bozuk durum**
- Transaction/Rollback yok

### 44. `forgot_password_screen.dart` — `_sendResetEmail` `await` Eksik
- `Future.delayed` await edilmiyor → race condition

### 45. `CalendarSyncService` — Gerçek Sync Yok
- Zaten yukarıda kritik olarak belirtildi ama ek not:
- `addOrUpdateEvent` metodu var ama `syncCalendar` onu çağırmıyor
- Cihaz takvimi → uygulama tek yönlü sync de yok

### 46. `LoginScreen._biometricLogin()` — Session Kontrolü Yetersiz
- `AuthService.currentUser != null` kontrolü yapıyor
- Ama app restart sonrası `currentUser` `null` olabilir (session henüz restore edilmemiş)
- Biyometrik başarılı olunca hub'a gidiyor ama auth'sız kalıyor

### 47. `child_login_screen.dart` — PIN 5 Karakter Kabul Ediyor
- `maxLength: 6` ama `_signIn()` sadece `pin.length < 4` kontrolü yapıyor
- 5 karakterli PIN kabul ediliyor ama muhtemelen backend reddediyor

### 48. `health_card_edit_screen.dart` — Typo
- `_buildSectionTitle('Tımi Bilgiler', ...)` → **'Tıbbi Bilgiler'** olmalı

### 49. `privacy_settings_screen.dart` — TODO Var
- `// TODO: GDPR veri indirme implementasyonu`

### 50. `crash_detection_service.dart` — 9 TODO
- Ses alarmı, max volume, ekran flaşı, SMS gönderme, 112 arama, vs.

### 51. `emergency_auto_actions_engine.dart` — 4 TODO
- SMS, FCM push, third-party entegrasyonlar, ses kaydı

### 52. `enterprise_service.dart` — 2 TODO
- BambooHR, Workday API entegrasyonları

### 53. `smart_reminder_background_service.dart` — 1 TODO
- Workmanager yeniden etkinleştirme

### 54. `premium_screen.dart` — Planlar Hardcoded
- `// Gerçek uygulamada bu veri Supabase'den çekilebilir`
- Plan fiyatları ve özellikleri kodda sabit

### 55. `profile_edit_screen.dart` — Avatar Upload İyi Ama
- Avatarı Firebase Storage'a yüklüyor muhtemelen (kod incelenmeli)
- Ama `AuthService.updateProfile()` sadece `avatar_url` güncelliyor

### 56. `family_screen.dart` — `_isAdmin` Mantığı Bozuk
```dart
final me = members.firstWhere(
  (m) => m.id == (members.isNotEmpty ? members.first.id : ''), ...
);
```
- Her zaman listedeki **ilk üyeyi** döndürür

### 57. `chat_screen.dart` — Hardcoded Kimlik
```dart
senderId: 'm1', senderName: 'Ben', senderColor: AppColors.blue
```
- Tüm mesajlar aynı senderId ile gönderiliyor

### 58. `chat_screen.dart` — Image Picker Hata Yönetimi Yok
- `_pickImage()` ve `_takePhoto()` try/catch içermiyor
- `mounted` kontrolü yok

### 59. `mood_screen.dart` — `addEntry` Hata Yönetimi Yok
- `onTap: () async { await ref.read(...).addEntry(...); }`
- try/catch ve `mounted` kontrolü yok

### 60. `smart_rotation_screen.dart` — `_loadRealData()` Catch'te `mounted` Kontrolü Yok

### 61. `safe_zones_screen.dart` — `_checkZones()` `mounted` Kontrolü Yok

### 62. `emergency_screen.dart` — `_animateProgress()` Dispose Riski
- `while (_holding && _progress < 1)` loop + `Future.delayed`
- Widget dispose olunca loop arka planda devam edebilir

### 63. `calendar_sync_screen.dart` — `_loadRealCalendars()` `mounted` Kontrolü Yok

### 64. `location_screen.dart` — Current User Konumu Gerçek, Aile Üyeleri Sahte
- Zaten kritik olarak belirtildi

### 65. `safe_arrival_screen.dart` — Stream Error Handler Yok
- `_activeSub` ve `_histSub` `onError` handler yok

### 66. `ambient_listening_screen.dart` — Stream Error Handler Yok
- `_dbSub` `onError` handler yok

### 67. `settings_screen.dart` ve Alt Ekranlar — Hardcoded Türkçe
- Tüm 15+ ayar ekranı hardcoded Türkçe

### 68. `weather_settings_screen.dart` — Şehir Listesi Hâlâ Var
- Requirement: "Şehir listesi kaldırılacak"
- Ama ekranda hâlâ 20 Avrupa şehri listesi var
- (Yeni `LocationWeatherService` var ama eski UI güncellenmemiş)

### 69. `about_app_screen.dart`, `terms_of_service_screen.dart`, `privacy_policy_screen.dart`
- Statik içerik, yasal metinler muhtemelen placeholder

### 70. `leaderboard_screen.dart` — Öksüz Dosya
- `lib/presentation/screens/settings/leaderboard_screen.dart` var ama
- `routes.dart`'ta route yok, hiçbir yerden çağrılmıyor

### 71. `ProfileEditorScreen` — Öksüz Dosya
- `lib/presentation/screens/location_tracking/profile_editor_screen.dart` var ama
- `routes.dart`'ta yok, hiçbir yerden çağrılmıyor

### 72. `EmergencyScreen` — Öksüz / Sahte
- `routes.dart`'ta yok, `safety_screen.dart` dışında çağrılmıyor
- Gerçek SOS mantığı `safety_screen.dart`'ta var

### 73. `notification_service.dart` — Android Notification Channel
- Kanal oluşturuluyor ama önem seviyesi (importance) ve ses/ titreşim davranışları detaylı kontrol edilmeli

### 74. `fcm_service.dart` — Token Sync Hata Yönetimi Yok
- `_syncTokenToSupabase()` try/catch içermiyor

### 75. `sync_service.dart` — Bilinmeyen Operasyonlar Sessizce Atlanıyor
- `_executeRemote()` `op.operation` validasyonu yok

---

## 📊 Özet Tablo

| Kategori | 🔴 Kritik | 🟠 Yüksek | 🟡 Orta | Toplam |
|----------|-----------|-----------|---------|--------|
| **Güvenlik** | 5 | 2 | 3 | 10 |
| **Store Reddi** | 4 | 1 | 1 | 6 |
| **Veri Eksikliği** | 3 | 5 | 4 | 12 |
| **Fonksiyonel Bozukluk** | 4 | 8 | 5 | 17 |
| **Tasarım/UI** | 0 | 2 | 6 | 8 |
| **Konfigürasyon** | 3 | 3 | 5 | 11 |
| **Arka Plan Servis** | 0 | 3 | 4 | 7 |
| **Repository/Servis** | 1 | 6 | 3 | 10 |
| **Toplam** | **20** | **30** | **31** | **81** |

---

## 🎯 Öncelikli Düzeltme Sırası (Definition of Done İçin)

### Sprint 1 — Acil (Uygulama Açılmaz / Store Reddedilir)
1. `app_links` bağımlılığını `pubspec.yaml`'a ekle
2. `firebase_options.dart`'taki gerçek API key'i kaldır / envied'e taşı
3. iOS `Info.plist` usage descriptions ve background modes ekle
4. Android release signing config düzelt (debug → release keystore)
5. `mood_entries` migration'ını oluştur
6. Splash screen `ChildAuthService` import'ını ekle

### Sprint 2 — Kritik (Veri Kaybı / Güvenlik)
7. Child login'a `family_id` filtresi ekle
8. Child PIN'i hash'leyerek sakla (`hashPin()` kullan)
9. Chat'i `ChatRepository` + Supabase realtime'e bağla
10. Family screen'de role/remove değişikliklerini Supabase'e yaz
11. Location screen'deki sahte veriyi kaldır, gerçek konum verisi göster
12. Biometric fallback PIN'i düzelt (secure storage karşılaştırması)

### Sprint 3 — Yüksek (Fonksiyonel Eksiklik)
13. Health Card ↔ Supabase sync köprüsü kur
14. Smart Rotation atamalarını Supabase'e kaydet
15. Calendar Sync'i gerçekten çalıştır (iki yönlü)
16. Crash Detection SOS eylemlerini implemente et (ses, flaş, SMS, 112)
17. Premium sistemi birleştir (tek ödeme sağlayıcı, bitiş tarihi kontrolü)
18. `ErrorService.initialize()`'ı `runApp()`'dan önce taşı
19. `HubRepository.subscribeToHub()`'a `.subscribe()` ekle
20. Repository'lere try/catch ekle

### Sprint 4 — Orta (UX / Lokalizasyon / Tasarım)
21. `flutter_localizations` + `l10n.yaml` + `.arb` dosyaları oluştur, tüm stringleri çıkar
22. `LanguageSettingsScreen`'i gerçekten locale değiştirecek hale getir
23. Theme token'larını tamamla
24. AndroidManifest eksik izinlerini ekle
25. Background servisleri `main.dart`'ta kaydet veya başlat
26. Kullanılmayan bağımlılıkları kaldır (`lottie`, `vibration`)
27. Öksüz screen dosyalarını kaldır veya route'la
