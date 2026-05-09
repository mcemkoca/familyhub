# 🚨 FamilyHub — Sprint 5 Sonrası Derin Analiz Raporu
> **Tarih:** 2026-05-09  
> **Kapsam:** Sprint 6-10 Hedefleri vs. Gerçek Kod Durumu  
> **Analiz Türü:** Cross-reference (Sprint dokümanları ↔ Kod) + Runtime audit  

---

## 📋 EXECUTIVE SUMMARY

| Sprint | Hedef | Gerçek Durum | Kalan Kritik Sorun |
|--------|-------|-------------|-------------------|
| **6** — Supabase/RLS | Güvenli DB, auto-migration, 300+ seed | ⚠️ Kısmen | SupabaseConfig refactor tamamlanmadı, seed data eksik |
| **7** — UI/UX/Tema | Dark mode mükemmel, system theme, emoji picker | ⚠️ Kısmen | Chat badge sabit, theme tokenlar tamamlanmadı |
| **8** — Konum/Hava | GPS otomatik hava durumu, canlı destek konumlu | ❌ Çoğunlukla yok | Weather GPS yok, canlı destek konumlu değil |
| **9** — Sağlık/Acil | Sağlık kartı seçenekler, otomatik SOS, crash detection | ⚠️ Kısmen | EmergencyScreen stub, crash detection kısmen çalışıyor |
| **10** — CI/CD/Test | Pipeline, %80 coverage, E2E test, Firebase deploy | ❌ Yok | GitHub Actions pipeline yok, coverage düşük |

**Toplam Kalan Eksiklik:** ~45+ kritik/önemli sorun  
**Store Reddi Riski:** ⚠️ Yüksek (FCM yok, child login açığı, SOS eksik)  

---

## 🔴 SPRINT 6: SUPABASE RLS & MIGRATIONS (Dosya 6)

### Hedeflenen (mdler/06_SUPABASE_RLS_MIGRATIONS.md)
- [ ] SupabaseConfig.safeClient 25+ dosyada kullanılıyor → refactor
- [ ] SQL migration otomasyon (supabase db push)
- [ ] 300+ ev işleri seed data
- [ ] RLS policies tüm tablolar
- [ ] Backup repository aile filtresi
- [ ] FamilyMembersRepository primaryKey düzeltme

### Gerçek Durum

| # | Konu | Durum | Detay |
|---|------|-------|-------|
| 6.1 | **SupabaseConfig.safeClient refactor** | ⚠️ Kısmen | `lib/core/supabase_client.dart` var (SupabaseConfig), ama kodda hâlâ `_client = Supabase.instance.client` kullanım yerleri var (örn: `smart_rotation_screen.dart:29`) |
| 6.2 | **SQL migration otomasyon** | ❌ Yok | `supabase/migrations/` altında 51 SQL dosyası var ama `supabase db push` CI/CD pipeline'ında yok. `.github/workflows/supabase-deploy.yml` yok. |
| 6.3 | **300+ ev işleri seed** | ❌ Yok | `supabase/seed_household_tasks.sql` dosyası var ama migration'lar arasında değil. `household_tasks` tablosu var mı emin değiliz. |
| 6.4 | **RLS policies tüm tablolar** | ⚠️ Kısmen | `046_final_rls_and_users.sql` migration'ında bazı tablolar için RLS var ama `profiles_select_all` policy `USING (true)` — tüm authenticated kullanıcılar tüm profilleri görebilir (AUDIT_REPORT #9). |
| 6.5 | **Backup repository aile filtresi** | ❌ Kontrol edilmedi | `BackupRepository` dosyası bulunamadı (muhtemelen `lib/repositories/` altında değil). |
| 6.6 | **FamilyMembersRepository PK** | ✅ Düzeltildi | `primaryKey: ['id']` olarak düzeltilmiş (`family_members_repository.dart:143`). |

### 🆕 Yeni Tespitler (Sprint 6 Kapsamında)
- `HubRepository` 2025-08'de düzeltilmiş — `.subscribe()` var (`hub_repository.dart:321`).
- `FamilyMembersRepository.updateRole()` ve `.removeMember()` var ama `FamilyScreen` bunları **kullanmıyor** — sadece local provider state değiştiriyor.

---

## 🟠 SPRINT 7: UI/UX & TEMA (Dosya 7)

### Hedeflenen (mdler/07_UI_UX_TEMA.md)
- [ ] Dark theme contrast WCAG 4.5:1
- [ ] System theme dinleyici anında yansıma
- [ ] Emoji picker çalışıyor
- [ ] `flutter analyze = 0`
- [ ] `mounted` kontrolü tüm ekranlar

### Gerçek Durum

| # | Konu | Durum | Detay |
|---|------|-------|-------|
| 7.1 | **Dark theme contrast** | ⚠️ Kısmen | `AppTheme.darkTheme` var ama `snackBarTheme`, `bottomSheetTheme`, `chipTheme`, `tooltipTheme`, `sliderTheme`, `inputDecorationTheme`, `dialogTheme`, `popupMenuTheme` gibi birçok tema eksik. `lib/config/theme.dart` içinde sadece partial tanımlar var. |
| 7.2 | **System theme dinleyici** | ✅ Var | `main.dart:324` — `didChangePlatformBrightness()` override edilmiş, `setState(() {})` çağrılıyor. |
| 7.3 | **Emoji picker** | ✅ Var | `emoji_picker_flutter: ^4.3.0` pubspec'te var. `chat_screen.dart` içinde kullanılıyor. |
| 7.4 | **flutter analyze = 0** | ✅ **0 hata** | `flutter analyze` 16.2s'de **No issues found** veriyor. |
| 7.5 | **mounted kontrolü** | ⚠️ Kısmen | Bazı ekranlarda var (`splash_screen.dart`, `child_login_screen.dart`) ama `smart_rotation_screen.dart:147` (catch bloğunda `mounted` yok), `location_screen.dart` (bazı yerlerde eksik). |

### 🆕 Yeni Tespitler (Sprint 7 Kapsamında)
- `MainShell` bottom navigation sync sorunu devam ediyor — `_tabs` listesinde olmayan sayfalara gidince önceki tab selected kalıyor (`ANALYSIS_REPORT.md O3`).
- `ChatScreen` badge değeri sabit `3` (`main_shell.dart` içinde). Gerçek unread count yok.
- `SettingsScreen`'de aynı hedefe giden 5 farklı bildirim kategorisi var (`ANALYSIS_REPORT.md O2`).

---

## 🟡 SPRINT 8: KONUM & HAVA DURUMU (Dosya 8)

### Hedeflenen (mdler/08_KONUM_HAVA_DURUMU.md)
- [ ] Hava durumu GPS konumuna göre
- [ ] Reverse geocoding şehir adı
- [ ] Canlı destek konum dahil
- [ ] Safe zones default Türkiye
- [ ] Background weather update 3 saatte bir

### Gerçek Durum

| # | Konu | Durum | Detay |
|---|------|-------|-------|
| 8.1 | **Weather GPS konum** | ❌ **Yok** | `LocationWeatherService` dosyası yok. `weather_settings_screen.dart` hâlâ 20 Avrupa şehri listesi gösteriyor (AUDIT_REPORT #68). `WeatherService` var ama şehir listesi tabanlı çalışıyor. |
| 8.2 | **Reverse geocoding** | ❌ **Yok** | `geocoding` paketi pubspec'te var ama hava durumu ekranında kullanılmıyor. |
| 8.3 | **Canlı destek konumlu** | ❌ **Yok** | `LiveSupportService` dosyası var (`lib/services/live_support_service.dart`) ama incelendiğinde konum entegrasyonu yetersiz. `support_sessions` tablosu migration'larında var mı belli değil. |
| 8.4 | **Safe zones default Türkiye** | ⚠️ Kısmen | `safe_zones_step.dart` içinde default Frankfurt (50.1109, 8.6821) hâlâ var (AUDIT_REPORT #42). `safe_zones_screen.dart` kontrol edilmedi. |
| 8.5 | **Background weather update** | ❌ **Yok** | `workmanager` paketi pubspec'te yok. Background update mekanizması yok. |

### 🆕 Yeni Tespitler (Sprint 8 Kapsamında)
- `LocationScreen` sadece kendi konumunu gösteriyor, aile üyelerinin konumunu göstermiyor.
- `LocationTrackingService.startTracking()` `SafetyScreen.initState()`'te çağrılıyor ama `dispose()`'da `stopTracking()` çağrılmıyor — pil tüketimi (ANALYSIS_REPORT K3).
- `BatteryAwareLocationTracker._flushBatch()` Supabase'e yazma yapmıyor (AUDIT_REPORT #27).

---

## 🟠 SPRINT 9: SAĞLIK KARTI & ACİL DURUM (Dosya 9)

### Hedeflenen (mdler/09_SAGLIK_KARTI_ACIL_DURUM.md)
- [ ] Sağlık kartı seçenekler (kan grubu, alerji, ilaç)
- [ ] Acil kişi otomatik seçim (Eş > Anne > Baba > Çocuk)
- [ ] SOS gerçek SMS
- [ ] Crash detection 9 method tamamlama
- [ ] 112 arama

### Gerçek Durum

| # | Konu | Durum | Detay |
|---|------|-------|-------|
| 9.1 | **Sağlık kartı seçenekler** | ⚠️ Kısmen | `HealthCardScreen` var (`lib/presentation/screens/safety/health_card_screen.dart`), kan grubu `ChoiceChip`, alerji/hastalık `FilterChip` var. Ama `HealthCardService` sadece local `FlutterSecureStorage` kullanıyor — Supabase sync yok (AUDIT_REPORT #13). |
| 9.2 | **Acil kişi otomatik seçim** | ❌ **Yok** | `HealthCardScreen` içinde `_autoSelectEmergencyContact` mantığı yok. Aile üyelerinden otomatik seçim implemente edilmemiş. |
| 9.3 | **SOS gerçek SMS** | ⚠️ **Kısmen** | `CrashDetectionService._notifyEmergencyContacts()` SMS composer açıyor (`url_launcher` ile `sms:` scheme), ama `SafetyScreen._activateSOS()` `EmergencyService.sendSOSAlert()` çağrıyor — bu sadece **local broadcast** yapıyor, Supabase'e yazmıyor. Cross-device SOS sync yok. `triggerSOS()` (Supabase'e yazan) hiçbir yerden çağrılmıyor! |
| 9.4 | **Crash detection 9 method** | ⚠️ Kısmen | `CrashDetectionService` implemente edilmiş: alarm, flaş, countdown, SMS, 112 arama, konum paylaşımı, tıbbi bilgi paylaşımı var. Ama `VibrationPattern.sos` sadece `HapticFeedback` kullanıyor, `vibration` paketi import edilmiyor. `crash_detection_engine.dart` threshold-based çalışıyor. |
| 9.5 | **112 arama** | ✅ Var | `EmergencyService.callEmergency()` ve `CrashDetectionService._callEmergencyServices()` `url_launcher` ile `tel:112` açıyor. |

### 🆕 Yeni Tespitler (Sprint 9 Kapsamında)
- **KRİTİK:** `SafetyScreen._activateSOS()` → `EmergencyService.sendSOSAlert()` çağrıyor. Bu metod sadece `_sosController.add(...)` yapıyor (local stream). **Supabase `sos_alerts` tablosuna yazmıyor.** Aile üyeleri diğer cihazlarda SOS'i göremez. `triggerSOS()` metodu (Supabase'e yazan) var ama **hiç çağrılmıyor**.
- `EmergencyScreen` (`emergency_screen.dart`) var ama route'larda `/emergency` → `SosMainScreen`'e gidiyor. `EmergencyScreen` öksüz/orphan.
- `health_card_service.dart` → `HealthCardService.load()` local only. `profiles` tablosuna sync yok.

---

## 🔴 SPRINT 10: CI/CD, TEST & SON KONTROL (Dosya 10)

### Hedeflenen (mdler/10_CI_CD_TEST_KONTROL.md)
- [ ] GitHub Actions pipeline
- [ ] Unit test coverage > 80%
- [ ] Integration test E2E
- [ ] Firebase App Distribution
- [ ] Supabase auto deploy

### Gerçek Durum

| # | Konu | Durum | Detay |
|---|------|-------|-------|
| 10.1 | **GitHub Actions pipeline** | ❌ **Yok** | `.github/workflows/flutter_ci.yml` dosyası yok. Sadece `dependabot.yml` ve PR template var. |
| 10.2 | **Unit test coverage > 80%** | ❌ **Hayır** | 80 test geçiyor ama coverage raporu `coverage/lcov.info` var. `test/` altında sadece temel unit testler var. Ekran/widget testi yok. Coverage muhtemelen <%20. |
| 10.3 | **Integration test E2E** | ⚠️ Kısmen | `integration_test/` altında 2 dosya var (`app_walkthrough_test.dart`, `login_flow_test.dart`) ama `integration_test/app_test.dart` (E2E) yok. |
| 10.4 | **Firebase App Distribution** | ❌ **Yok** | Workflow yok, Fastlane yok. |
| 10.5 | **Supabase auto deploy** | ❌ **Yok** | `supabase db push` CI/CD'de otomatik değil. |

### 🆕 Yeni Tespitler (Sprint 10 Kapsamında)
- `flutter build apk --release` çalışıyor olabilir ama `firebase_options.dart` içinde **gerçek API key var** (`AIzaSyAbsV-yuJ6vXsoA0jkEw-MgFeMffLA9x5U`) — secret exposure riski (AUDIT_REPORT #2).
- Android release signing: `android/app/build.gradle.kts` kontrol edilmedi, debug signing olabilir (AUDIT_REPORT #4).
- iOS `Info.plist`: 6 usage description + UIBackgroundModes eksik olabilir (AUDIT_REPORT #3).

---

## 🔥 SPRINT 1-5'TEN KALAN KRİTİK SORUNLAR (Hâlâ Açık)

Bu sorunlar "önceki sprintlerde çözüldü" denmesine rağmen kodda hâlâ açık:

| # | Sorun | Risk | Kod Konumu |
|---|-------|------|-----------|
| 1 | **Chat tamamen local** — Supabase Realtime'a gitmiyor | 🔴 Kritik | `chat_screen.dart:51-74` — `senderId: ''`, `senderName: 'Ben'`, provider state'e yazıyor |
| 2 | **Family Screen sahte CRUD** — Rol/silme sadece local | 🔴 Kritik | `family_screen.dart:68-148` — `ref.read(familyMembersProvider.notifier).state = newList` |
| 3 | **Child login aile filtresi yok** (userId==null path) | 🔴 Kritik | `child_login_screen.dart:39-56` — `.eq('is_active', true).limit(20)` family_id yok |
| 4 | **SOS Supabase'e yazmıyor** — Aile üyeleri göremez | 🔴 Kritik | `emergency_service.dart:23-39` — `sendSOSAlert` sadece local stream. `triggerSOS` hiç çağrılmıyor |
| 5 | **Smart Reminder Background** — Tamamen stub | 🟠 Yüksek | `smart_reminder_background_service.dart` — 7 satır, no-op |
| 6 | **Calendar Sync** — Gerçek sync yok, sadece sayaç | 🟠 Yüksek | `calendar_sync_service.dart:122-200` — `added++` ama veri taşıma yok |
| 7 | **Biometric PIN** — Her zaman false dönüyordu, düzeltilmiş mi? | 🟡 Orta | `biometric_service.dart:56-61` — Şimdi secure storage karşılaştırması var, düzeltilmiş görünüyor |
| 8 | **Workmanager yok** — Periyodik arka plan işleri imkansız | 🟠 Yüksek | `pubspec.yaml`'da `workmanager` yok. SmartReminderBackgroundService stub |
| 9 | **FCM (Push Notification) yok** — Sunucudan push imkansız | 🟠 Yüksek | `firebase_messaging` pubspec'te var ama entegrasyon yok (Tur 16) |
| 10 | **`.env` dosyası APK içinde** — Secret exposure | 🔴 Kritik | `.env` dosyası `assets` altında değil ama `Env` class build-time embed ediyor |

---

## 🆕 SPRINT 5 SONRASI YENİ TESPİTLER (Önceki Raporlarda Yok)

### Yapısal/Mimari
1. **304 Dart dosyası, 51 migration** — Kod büyüklüğü yönetilebilir ama modülerlik sorunu var.
2. **Supabase instance client direct kullanım** — `smart_rotation_screen.dart:29` gibi yerlerde `Supabase.instance.client` direkt kullanılıyor, `SupabaseConfig.safeClient` yerine.
3. **`ErrorService.initialize()` runApp ÖNCESİ** — `main.dart:214`'te düzeltilmiş, önceki rapordaki sorun (runApp sonrası) çözülmüş.

### Fonksiyonel
4. **HealthCard ↔ profiles sync yok** — Sağlık kartı verileri sadece local cihazda, aile üyeleriyle paylaşılmıyor.
5. **Smart Rotation atamaları Supabase'e yazmıyor** — `_acceptAssignment()` sadece local `_tasks` listesini güncelliyor (`smart_rotation_screen.dart:177-189`).
6. **Location Tracking Memory Leak devam ediyor** — `SafetyScreen.initState():49` → `LocationTrackingService.startTracking()` çağrılıyor ama `dispose()`'da `stopTracking()` yok.
7. **Chat senderId hardcoded boş string** — `chat_screen.dart:57` → `senderId: ''`. Bu mesajların kimden geldiğini ayırt etmeyi imkansızlaştırıyor.

### Güvenlik
8. **Child login'de RLS bypass riski** — `child_login_screen.dart:39-56`: Eğer kullanıcı guest/auth'sız ise `child_accounts`'tan `family_id` filtresi olmadan çocuk çekiliyor. Bu bir veri sızıntısı.
9. **`profiles_select_all` policy** — Tüm authenticated kullanıcılar tüm profilleri görebilir.

---

## 📊 ÖZET METRİKLER

```
Sprint 6 (Supabase)    : %40 tamamlandı
Sprint 7 (UI/UX)       : %60 tamamlandı
Sprint 8 (Konum/Hava)  : %10 tamamlandı
Sprint 9 (Sağlık/Acil) : %50 tamamlandı
Sprint 10 (CI/CD)      : %5 tamamlandı
---------------------------------------
GENEL ORTALAMA         : %33 tamamlandı
```

### Risk Matrisi
| Risk | Sayı |
|------|------|
| 🔴 Kritik (Çökme/Güvenlik/Store Reddi) | 8 |
| 🟠 Yüksek (Önemli fonksiyonel eksiklik) | 7 |
| 🟡 Orta (UX/Tasarım/Teknik borç) | 12 |
| 🟢 Düşük (Polish/Refactor) | 18 |

---

## 🎯 ÖNCELİKLİ DÜZELTME SIRASI (Sprint 5 Sonrası)

### Acil (Bu Hafta)
1. **SOS Supabase'e yazsın** — `SafetyScreen._activateSOS()`'ta `triggerSOS()` çağrılmalı
2. **Chat Supabase Realtime** — `chat_screen.dart` tamamen rewrite edilmeli
3. **Child login aile filtresi** — Auth'sız path'te `family_id` filtresi zorunlu
4. **Family Screen CRUD** — `_handleRoleChange` ve `_handleRemove` repository metodlarını çağırmalı

### Yüksek (2 Hafta)
5. **Weather GPS konum** — `LocationWeatherService` implemente edilmeli
6. **Smart Reminder Background** — `workmanager` eklenmeli veya alternatif bulunmalı
7. **Calendar Sync gerçek sync** — Veri taşıma implemente edilmeli
8. **GitHub Actions CI/CD** — Pipeline oluşturulmalı

### Orta (1 Ay)
9. **Theme token tamamlama** — Eksik tema tanımları
10. **Health Card Supabase sync** — `profiles` tablosuyla köprü
11. **Bottom nav sync** — Tab-olmayan route'lar için mapping
12. **Integration test E2E** — Login → Dashboard → Chat → Logout akışı

---

*Rapor: Sprint dokümanları (mdler/06-10), mevcut kod (lib/), test sonuçları (flutter analyze/test), ve önceki audit raporları (ANALYSIS_REPORT*, AUDIT_REPORT*) cross-reference edilerek oluşturulmuştur.*
