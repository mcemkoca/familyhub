# 🔬 Sprint 6 Öncesi Genel Deep Analiz Raporu
> **Tarih:** 2026-05-09  
> **Kapsam:** Sprint 1-5 Tamamlama Durumu + Sprint 6 Hazırlık  
> **Hedef:** Sprint 6'ya geçmeden önce tüm yapısal ve veri katmanı sorunlarını tespit etmek

---

## 📊 SPRINT 1-5 GENEL DURUM ÖZETİ

| Sprint | Hedef | Tamamlanma | Kalan Kritik |
|--------|-------|-----------|--------------|
| **1** Store Blokajı | Derleme, env, mood_entries, app_links | ✅ %100 | — |
| **2** Güvenlik & Veri | Child login filtresi, PIN hash, Chat realtime, Family CRUD, Biometric | ✅ %100 | — |
| **3** Fonksiyonel | Health Card sync, Smart Rotation, Calendar Sync, Crash SOS, Premium, HubRepository.subscribe, try/catch | ⚠️ %65 | Repository try/catch yok, Health Card local, Calendar sync sahte |
| **4** UX/L10N | flutter_localizations, .arb, dil değiştirme, theme token, background servis, orphan dosyalar | ⚠️ %55 | Theme tokenlar eksik, background servisler stub |
| **5** Android/iOS | Manifest, Proguard, Podfile, version, onboarding remote config, assets | ✅ %100 | — |

**Not:** Sprint 2 ve Sprint 5 tamamen bitti. Sprint 3 ve 4'ten ciddi teknik borç kaldı. Sprint 6'ya geçmeden bu borçların bir kısmını ele almak gerekli.

---

## 🔴 SPRINT 6 ÖNCESİ KRİTİK TESPİTLER

### T1. `Supabase.instance.client` Direkt Kullanımı — 9 Dosya, 15+ Yer

`SupabaseConfig.safeClient` tanımlı olmasına rağmen 9 dosya hâlâ direkt `Supabase.instance.client` kullanıyor. Bu:
- **Singleton pattern ihlali** — her yerde farklı client instance riski
- **Error handling yetersizliği** — `safeClient` null check ve exception wrap yapıyor, direkt kullanım yapmıyor
- **Test edilemezlik** — mock client inject edilemiyor

| Dosya | Satır | Kullanım Yeri |
|-------|-------|---------------|
| `smart_rotation_screen.dart` | 29 | `final _client = Supabase.instance.client;` |
| `child_detail_screen.dart` | 45, 257, 529, 914, 1173 | 5 farklı tab/state'te direkt client |
| `safe_arrival_screen.dart` | 39 | `final client = Supabase.instance.client;` |
| `premium_screen.dart` | 124, 174 | Functions invoke + .from query |
| `routines_screen.dart` | — | Direkt client kullanımı |
| `smart_reminders_screen.dart` | — | Direkt client kullanımı |
| `smart_reminder_create_screen.dart` | — | Direkt client kullanımı |
| `crash_history_screen.dart` | 17 | `final profile = await Supabase.instance.client.from('profiles')...` |
| `supabase_client.dart` | 50 | `initializeListener()` içinde `Supabase.instance.client.auth.onAuthStateChange` |

**Risk:** 🔴 Yüksek — Auth state değişikliğinde race condition, null client crash riski.

---

### T2. `RepositoryErrorHandler` Mixin'i Ölü Kod — Hiçbir Repository Kullanmıyor

`lib/core/utils/repository_mixin.dart` var ama **sadece test dosyasında** (`test/core/utils/repository_mixin_test.dart`) kullanılıyor. 30+ repository'nin hiçbiri `with RepositoryErrorHandler` yapmamış.

**Sonuç:**
- `EventRepository`, `TaskRepository`, `ChatRepository`, `BudgetRepository`, `CalendarRepository` vb. tüm CRUD metodları **try/catch içermiyor**
- Supabase bağlantı hatası, RLS reddi, network kesintisi → **uygulama çöker**
- `AUDIT_REPORT_LAUNCH_READINESS.md #25`'te listelenen 20+ repository hâlâ korunmasız

**Risk:** 🔴 Kritik — Herhangi bir network/RLS hatası uygulamayı çökertir.

---

### T3. Seed Data — SQL'de Sadece 18 Görev, 300+ Yok

`supabase/seed_household_tasks.sql`:
- Satır 1: "Seed 300+ Household Tasks (truncated sample; full data loaded from application assets)"
- Gerçek INSERT sayısı: **18 görev** (daily: 7, weekly: 2, monthly: 3, yearly: 3)
- Satır 61: "Full 300+ task seed is loaded from assets/data/household_tasks.json via application logic"

**Ama** `assets/data/household_tasks.json` dosyası **yok**! `pubspec.yaml`'da `assets/data/household.json` var ama `household_tasks.json` yoktu (şimdi eklendi).

`household_tasks` tablosu migration'larında var (`047_household_tasks.sql`). Ama uygulama bu tabloyu kullanıyor mu emin değiliz.

**Risk:** 🟡 Orta — Smart Rotation ve görev dağılımı için yeterli seed data yok.

---

### T4. RLS Policies — Kapsamlı Ama Bakım Yükü Yüksek

`supabase/migrations/` altında **52 SQL dosyası**, bunların ~15'i doğrudan RLS fix'leri:
- `034_fix_family_members_rls.sql`
- `036_fix_rls_and_theme.sql`
- `037_fix_family_members_rls.sql`
- `038_fix_all_rls_and_schema.sql`
- `039_fix_remaining_rls.sql`
- `040_fix_all_remaining_rls.sql`
- `042_fix_families_insert_policy.sql`
- `043_comprehensive_rls_fix.sql`
- `044_fix_everything.sql`
- `045_add_child_age.sql`
- `046_final_rls_and_users.sql`
- `047_fix_family_members_recursion.sql`
- `049_rls_auto_enable.sql`
- `052_security_fixes.sql`

**Olumlu:**
- `profiles_insert_own` policy var (kendi profilini ekleme)
- `family_members_select_by_family` recursive olmayan sorgu
- `families_select_by_member` policy var
- `RLS auto-enable` event trigger var (`049_rls_auto_enable.sql`)

**Olumsuz:**
- 15 RLS fix migration'ı var → **RLS sürekli kırılıp düzeltilmiş**, kararsız bir geçmiş
- `profiles_select_all` policy `USING (true)` **kaldırılmış** görünüyor (046'da düzeltilmiş)
- Yeni tablo eklendiğinde otomatik RLS var ama policy'leri manuel yazmak gerekiyor

**Risk:** 🟡 Orta — RLS kararlı ama geçmişte çok kırılmış, yeni geliştirici için bakım zor.

---

### T5. SQL Migration Otomasyonu — CI/CD Yok

`.github/workflows/` altında:
- `flutter.yml` var (build)
- `supabase-deploy.yml` **YOK**
- `supabase db push` manuel çalıştırılıyor

**Risk:** 🟡 Orta — Production deploy'lerde migration atlanma riski.

---

### T6. Backup Repository Aile Filtresi — Düzeltilmiş ✅

`lib/repositories/backup_repository.dart:185-201`:
```dart
Stream<List<Map<String, dynamic>>> watchBackups() async* {
  final familyId = await _getFamilyId();
  if (familyId == null) { yield []; return; }
  yield* _client.from('family_backups').stream(primaryKey: ['id'])
      .eq('family_id', familyId)
      ...
}
```

**Durum:** ✅ Düzeltilmiş — AUDIT_REPORT #23 çözülmüş.

---

### T7. FamilyMembersRepository PK — Düzeltilmiş ✅

`lib/repositories/family_members_repository.dart:143`:
```dart
.stream(primaryKey: ['id'])  // Doğru
```

**Durum:** ✅ Düzeltilmiş — `['family_id', 'user_id']` yerine `['id']` kullanılıyor.

---

### T8. `SupabaseConfig` Yetersizlikleri

`lib/core/supabase_client.dart`:
- `safeClient` null dönebiliyor — çağıranlar null check yapmak zorunda
- `client` getter `StateError` atıyor — bu da crash riski
- `initializeListener()` hâlâ `Supabase.instance.client` kullanıyor
- `isAuthenticated` ve `currentUser` `client` getter'ını kullanıyor → uninitialized durumda crash

**Risk:** 🟠 Yüksek — App açılışında Supabase initialize edilmeden erişim crash edebilir.

---

## 🟠 SPRINT 3-4'TEN KALAN TEKNİK BORÇ

| # | Sorun | Durum | Sprint |
|---|-------|-------|--------|
| 1 | Health Card sadece local | `HealthCardService.load()` secure storage kullanıyor, Supabase sync yok | 3 |
| 2 | Calendar Sync sahte | `added++` ama gerçek veri taşıma yok | 3 |
| 3 | Smart Reminder Background stub | `workmanager` yok, `initialize()` no-op | 4 |
| 4 | Theme tokenlar eksik | `snackBarTheme`, `bottomSheetTheme`, `chipTheme`, `tooltipTheme`, `sliderTheme` vb. | 4 |
| 5 | FCM entegrasyonu yok | `firebase_messaging` pubspec'te ama entegrasyon yok | 4 |
| 6 | `Workmanager` yok | Periyodik arka plan işleri imkansız | 4 |

---

## 📊 RİSK MATRİSİ (Sprint 6 Öncesi)

| Seviye | Sayı | Başlıca Konular |
|--------|------|-----------------|
| 🔴 Kritik | 2 | RepositoryErrorHandler kullanılmıyor, Supabase.instance.client direkt kullanımı |
| 🟠 Yüksek | 3 | SupabaseConfig crash riski, seed data eksikliği, FCM yok |
| 🟡 Orta | 4 | RLS bakım yükü, migration otomasyonu yok, teknik borç, theme eksikliği |
| 🟢 Düşük | 6 | Polish, refactor, dokümantasyon |

---

## 🎯 SPRINT 6 YOL HARİTASI (Önerilen)

### Phase 1: Supabase Client Refactor (2 gün)
1. Tüm `Supabase.instance.client` kullanımlarını `SupabaseConfig.safeClient` veya `SupabaseConfig.client` ile değiştir
2. `SupabaseConfig.initializeListener()` içindeki direkt kullanımı düzelt
3. `smart_rotation_screen.dart`, `child_detail_screen.dart`, `safe_arrival_screen.dart`, `premium_screen.dart`, `crash_history_screen.dart` vb.

### Phase 2: Repository Error Handling (2 gün)
4. Tüm repository'leri `with RepositoryErrorHandler` yap
5. CRUD metodlarını `handleRepositoryCall(() async { ... }, 'operationName')` ile sarmala
6. `EventRepository`, `TaskRepository`, `ChatRepository`, `BudgetRepository`, `CalendarRepository`, `Child*Repository`, `ShoppingRepository` vb.

### Phase 3: Seed Data & Migration (1 gün)
7. `assets/data/household_tasks.json` oluştur (300+ görev)
8. `seed_household_tasks.sql`'i genişlet veya JSON'dan migration oluştur
9. GitHub Actions workflow ekle: `supabase-deploy.yml`

### Phase 4: RLS Cleanup & Validation (1 gün)
10. Tüm migration'ları tek bir `all_migrations.sql`'de birleştir
11. `supabase db push` ile production'a uygula
12. RLS policies'leri test et (RLS test script'i çalıştır)

### Phase 5: SupabaseConfig Güçlendirme (1 gün)
13. `safeClient`'i null-safe hale getir
14. `isAuthenticated` ve `currentUser` uninitialized durumda gracefully handle etsin
15. `initializeListener()`'ı `safeClient` üzerinden çalıştır

---

## 📋 SPRINT 6 KONTROL LİSTESİ (Definition of Done)

- [ ] `Supabase.instance.client` kullanan 0 dosya kaldı
- [ ] Tüm repository'ler `RepositoryErrorHandler` mixin'i kullanıyor
- [ ] 300+ ev işi seed data yüklü (SQL veya JSON)
- [ ] `supabase db push` CI/CD pipeline aktif
- [ ] RLS policies tüm tablolarda çalışıyor ve test edilmiş
- [ ] `SupabaseConfig.safeClient` uninitialized durumda crash etmiyor
- [ ] `flutter analyze` 0 hata
- [ ] `flutter test` 80/80 geçiyor

---

*Rapor: Kod tabanı otomatik tarama (Grep, Shell), manuel dosya incelemesi, ve mevcut audit raporları cross-reference edilerek oluşturulmuştur.*
