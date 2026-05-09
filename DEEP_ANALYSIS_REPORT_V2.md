# FamilyHub Flutter Projesi — Kapsamlı Derin Analiz Raporu v2

> Tarih: 2026-05-08  
> Flutter: 3.41.1 (stable) • Dart SDK ^3.11.0  
> Gradle: 8.13 • Android SDK 36.1.0  
> Toplam Dart dosyası: 288 (lib/) + 4 test dosyası  
> APK boyutu: 172 MB (minify/shrink kapalı)

---

## 📊 Risk Özeti (Öncelik Sırasına Göre)

| # | Bulgu | Risk | Sorumlu Alan |
|---|-------|------|-------------|
| 1 | `lib/core/config/env.g.dart` repo'da — XOR obfuscation kırılabilir | **🔴 Kritik** | Güvenlik |
| 2 | `profiles` RLS policy `using(true)` → tüm profiller herkese açık | **🔴 Kritik** | Güvenlik |
| 3 | `android/app/google-services.json` WD'de, gerçek key, ignore edilmemiş | **🔴 Kritik** | Güvenlik |
| 4 | Test kapsamı %1.4 (4 test / 288 dosya) | **🔴 Yüksek** | Mimari |
| 5 | `isMinifyEnabled=false`, `isShrinkResources=false` | **🔴 Yüksek** | Build |
| 6 | Release signing env yoksa debug signing'e düşüyor | **🔴 Yüksek** | Build |
| 7 | `production.yml` CI'da secret injection + obfuscation yok | **🔴 Yüksek** | CI/CD |
| 8 | Client-side `isAdmin()` / `isPremium()` — sunucu doğrulaması yok | **🔴 Yüksek** | Güvenlik |
| 9 | `ScaffoldMessenger.showSnackBar` 128× tekrar, `CircularProgressIndicator` 75× | **🟡 Orta** | UI/UX |
| 10 | Static service classes (DI yok) — `AuthService.signIn()` | **🟡 Orta** | Mimari |
| 11 | `empty_catches: ignore` — sessiz hata yutma | **🟡 Orta** | Kod Kalitesi |
| 12 | `main.dart` 320+ satır — `AppInitializer` extraction gerekli | **🟡 Orta** | Mimari |
| 13 | `analysis_options.yaml` çok gevşek | **🟡 Orta** | Kod Kalitesi |
| 14 | `com.example.familyhub` paket adı | **🟡 Orta** | Build |
| 15 | Inline dark-mode ternary `isDark ? ... : ...` ~40+ kez | **🟡 Orta** | UI/UX |
| 16 | 500+ satırlık ekran dosyaları | **🟡 Orta** | UI/UX |
| 17 | Accessibility eksikliği (semanticLabel, FocusNode) | **🟡 Orta** | UI/UX |
| 18 | Asset boyutu: app_icon 1.4 MB, PNG'ler WebP'ye dönüştürülebilir | **🟢 Düşük** | UI/UX |
| 19 | `BaseRepository` + `RepositoryErrorHandler` — iyi yapılandırılmış | **🟢 Düşük** ✅ | Mimari |
| 20 | Core modülleri (analytics, error, validation) ayrılmış | **🟢 Düşük** ✅ | Mimari |

---

## 🔴 Kritik Bulgular (Acil Eylem Gerekli)

### 1. `env.g.dart` Repo'da — Obfuscated Secret'lar Açıkta

**Durum:** `lib/core/config/env.g.dart` Git repo'suna eklenmiş. `Envied` XOR obfuscation kullanıyor (`data[i] ^ key[i]`), ancak bu kırılabilir. APK decompile edilerek secret'lar (Supabase URL, anon key, Stripe key) elde edilebilir.

**Neden kritik:** Production Supabase URL ve anon key'i ele geçiren herkes veritabanına erişebilir. RLS policy'lerdeki açıklar (bkz. Bulgu #2) bunu daha da tehlikeli kılar.

**Çözüm:**
```bash
git rm --cached lib/core/config/env.g.dart
echo "lib/core/config/env.g.dart" >> .gitignore
```
CI'da `build_runner` ile generate et:
```yaml
# .github/workflows/flutter.yml
cd $GITHUB_WORKSPACE
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

### 2. RLS Policy Açığı — Tüm Profiller Herkese Açık

**Dosya:** `supabase/migrations/006_profiles_and_premium.sql`

```sql
create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);
```

**Etki:** `profiles` tablosunda `email`, `phone`, `is_admin`, `is_premium`, `subscription_tier`, `fcm_token`, `emergency_contact_*`, `blood_type`, `allergies` gibi PII ve güvenlik verileri var. **Herhangi bir authenticated kullanıcı diğer tüm kullanıcıların bu verilerini okuyabilir.**

**Çözüm:**
```sql
-- Kullanıcı kendi profilini okuyabilir
create policy "Profiles are viewable by owner"
  on public.profiles for select
  using (auth.uid() = id);

-- Aile üyeleri birbirlerinin profillerini okuyabilir
create policy "Profiles are viewable by family members"
  on public.profiles for select
  using (
    exists (
      select 1 from family_members
      where family_members.user_id = auth.uid()
        and family_members.family_id = (
          select family_id from family_members where user_id = profiles.id limit 1
        )
    )
  );
```

---

### 3. `google-services.json` .gitignore'da Yok

**Durum:** `android/app/google-services.json` working directory'de mevcut ve gerçek Firebase API key (`AIzaSyAbsV-yuJ6vXsoA0jkEw-MgFeMffLA9x5U`) içeriyor. `.gitignore`'da `google-services.json` ignore edilmemiş.

**Not:** Şu an `git ls-files` ile tracked değil, ancak `git add android/app/` ile yanlışlıkla commit edilebilir.

**Çözüm:**
```bash
echo "android/app/google-services.json" >> .gitignore
echo "ios/Runner/GoogleService-Info.plist" >> .gitignore
```
Mevcut dosyayı repo'dan kaldır (eğer tracked ise):
```bash
git rm --cached android/app/google-services.json 2>/dev/null || true
```

---

## 🔴 Yüksek Risk Bulguları

### 4. Test Kapsamı %1.4

- **4 test dosyası** var, **288 lib dosyası** var.
- **Kritik test edilmemiş alanlar:** `AuthService`, `SupabaseConfig`, `BaseRepository`, ödeme akışları, RLS policy'leri.

**Öneri:** Öncelikle `AuthService`, `SupabaseConfig`, `BaseRepository`, `RepositoryErrorHandler` için unit test yazın. Sonra widget test'leri (login form, registration flow) ekleyin.

---

### 5-6. Android Release Build Güvenliği

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        isMinifyEnabled = false          // ← ProGuard/R8 kapalı
        isShrinkResources = false        // ← Kullanılmayan kaynaklar kalmıyor
        signingConfig = if (...) { ... } else { signingConfigs.getByName("debug") }
                                         // ← Env yoksa debug signing!
    }
}
```

**Etkiler:**
- `isMinifyEnabled=false` → Reverse engineering çok kolay (Dart kodu reflection'a açık).
- Debug signing fallback → CI'da env var eksikse release build debug imzalı APK üretir (Google Play Red'ler).

**Çözüm:**
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        signingConfig = signingConfigs.getByName("release")
        // ProGuard rules ekle
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```
Release signing env yoksa build hatası:
```kotlin
signingConfigs {
    create("release") {
        storeFile = file(System.getenv("KEYSTORE_PATH") ?: error("KEYSTORE_PATH not set"))
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: error("KEYSTORE_PASSWORD not set")
        keyAlias = System.getenv("KEY_ALIAS") ?: error("KEY_ALIAS not set")
        keyPassword = System.getenv("KEY_PASSWORD") ?: error("KEY_PASSWORD not set")
    }
}
```

---

### 7. `production.yml` Eksik Secret Injection

**Dosya:** `.github/workflows/production.yml`

- `--dart-define` veya `--dart-define-from-file` ile secret injection yok.
- `--obfuscate --split-debug-info` yok.
- `env.g.dart` repo'da olduğu için Supabase/Stripe key'ler çalışır, ancak Firebase/AI/Analytics servisleri dummy değerlerle çalışacak.

**Çözüm:** `flutter.yml` ile aynı secret injection pattern'ini `production.yml`'e de uygulayın.

---

### 8. Client-Side Admin/Premium Kontrolü

**Durum:** `AuthService.isAdmin()` ve `AuthService.isPremium()` sadece client-side `profiles.is_admin == true` / `is_premium == true` kontrolü yapıyor. Sunucu tarafında doğrulama yok.

**Etki:** Reverse engineering ile client-side kod değiştirilebilir → admin/premium yetkisi kazanılabilir.

**Çözüm:**
1. Admin işlemleri için Supabase RPC kullanın (örn: `admin_delete_user`, `admin_approve_premium`).
2. RLS policy'lerde `is_admin` kontrolü ekleyin:
   ```sql
   create policy "Only admins can update family settings"
     on public.families for update
     using (
       exists (
         select 1 from profiles
         where profiles.id = auth.uid() and profiles.is_admin = true
       )
     );
   ```
3. Premium feature gate'leri için server-side `can_access_feature(user_id, feature_name)` RPC fonksiyonu oluşturun.

---

## 🟡 Orta Risk Bulguları

### 9. UI Kod Tekrarları

| Widget/Pattern | Tekrar Sayısı | Dosya Sayısı | Öneri |
|---------------|---------------|--------------|-------|
| `ScaffoldMessenger.showSnackBar` | 128 | 47 | `AppMessenger` servisi |
| `CircularProgressIndicator` | 75 | 48 | `AppLoadingIndicator` widget'ı |
| `isDark ? Colors.white : Colors.black` | ~40+ | - | `AppCard`, `AppText` tema widget'ları |

**Örnek `AppMessenger`:**
```dart
class AppMessenger {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  static void showError(BuildContext context, String message) { ... }
  static void showInfo(BuildContext context, String message) { ... }
}
```

---

### 10. Static Service Classes (DI Yok)

**Durum:** `AuthService.signIn()`, `SupabaseConfig.client`, `AnalyticsService.instance` gibi static singleton'lar var. `auth_guard` ve ekranlar static state'e bağımlı.

**Etki:** Unit test'te mock'lamak zor. Riverpod provider'larıyla değiştirilmesi gerekli.

**Çözüm:**
```dart
// Mevcut: static
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

// auth_guard'da:
final user = ref.watch(authUserProvider);
```

---

### 11. `empty_catches: ignore` — Sessiz Hata Yutma

```yaml
# analysis_options.yaml
errors:
  empty_catches: ignore        # ← Exception'lar sessizce yutuluyor
  deprecated_member_use: ignore # ← Teknik borç birikimi
  unused_import: ignore         # ← Kod kalitesi düşüyor
```

**Etki:** Auth failure, RLS violation, network error gibi güvenlik olayları gizlenebilir.

**Çözüm:**
```yaml
errors:
  empty_catches: error
  deprecated_member_use: warning
  unused_import: warning
  unawaited_futures: warning
  avoid_print: warning
```

---

### 12. `main.dart` Bloat (320+ Satır)

**Durum:** `main()` 80+ satır, `_initAndRunApp()` 240+ satır. Servis init, error handling, widget binding hepsi tek fonksiyonda.

**Çözüm:** `AppInitializer` sınıfı oluşturun:
```dart
class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _initFirebase();
    await _initSupabase();
    await _initAnalytics();
    await _initSentry();
    await _initHive();
  }
}
```

---

### 13. `analysis_options.yaml` Çok Gevşek

**Eksik kurallar:**
- `avoid_print`
- `unawaited_futures`
- `always_specify_types` (opsiyonel)
- `avoid_slow_async_io`
- `avoid_dynamic_calls`
- `avoid_web_libraries_in_flutter`

**Önerilen config:**
```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  exclude: ["**/*.g.dart", "integration_test/**"]
  errors:
    depend_on_referenced_packages: ignore
```

---

### 14. `com.example.familyhub` Paket Adı

**Durum:** `namespace = "com.example.familyhub"` — `example` yerine gerçek domain kullanılmalı.

**Etki:** Google Play'de yayınlanamaz (example paket adları reddedilir).

**Çözüm:**
```kotlin
namespace = "com.mcemkoca.familyhub"
applicationId = "com.mcemkoca.familyhub"
```
Not: Paket adı değişikliği mevcut kullanıcıları etkiler (yeni uygulama olarak görünür). Veri migration stratejisi planlayın.

---

### 15-17. UI/UX İyileştirmeleri

- **15. Inline dark-mode ternary:** Her ekranda `Theme.of(context).brightness == Brightness.dark ? ... : ...` tekrarı. `AppCard`, `AppText`, `AppButton` gibi tema-bilinçli widget'lar oluşturun.
- **16. 500+ satırlık ekranlar:** `DashboardScreen`, `SettingsScreen` gibi dosyalar çok büyük. Extract private widget'lar, ayrı dosyalara bölün.
- **17. Accessibility:**
  - Tüm butonlara `semanticLabel` ekleyin.
  - Formlara `FocusNode` ve `TextInputAction.next` ekleyin.
  - Ekranlara `Semantics` wrapper ekleyin.

---

## 🟢 Düşük Risk / Olumlu Bulgular

- **BaseRepository + RepositoryErrorHandler:** İyi yapılandırılmış, genişletilebilir.
- **Core modülleri:** Analytics, error, validation sorumlulukları ayrılmış.
- **Defansif init:** `main.dart`'ta servis init hataları uygulamayı çökertmiyor.
- **Sentry PII scrubbing:** Email maskeleme, secret tag temizleme — iyi uygulama.
- **Firebase config:** `String.fromEnvironment` ile dummy değerler, güvenli pattern.
- **CI/CD:** `flutter.yml` çalışıyor, debug APK her push'ta üretiliyor.

---

## ✅ Önerilen Eylem Planı (Öncelik Sırası)

### Sprint 1: Güvenlik (1-2 gün)
- [ ] `git rm --cached lib/core/config/env.g.dart` + `.gitignore` güncelle
- [ ] `android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist` `.gitignore`'a ekle
- [ ] `profiles` RLS policy'sini `using(true)` → `auth.uid() = id` olarak değiştir
- [ ] `family_members` tablosuna RLS policy ekle (default deny → uygulama erişemez)
- [ ] Admin/premium kontrolleri için Supabase RPC + RLS policy oluştur

### Sprint 2: Build & CI (1-2 gün)
- [ ] `isMinifyEnabled = true`, `isShrinkResources = true` + ProGuard rules
- [ ] Release signing fallback kaldır → env yoksa build hatası
- [ ] `production.yml`'e secret injection + `--obfuscate` ekle
- [ ] Paket adını `com.example.familyhub` → gerçek domain olarak değiştir
- [ ] `x86_64` ABI filtresine ekle (emülatör desteği)

### Sprint 3: Kod Kalitesi (2-3 gün)
- [ ] `analysis_options.yaml` güncelle (`very_good_analysis` önerilir)
- [ ] `empty_catches: ignore` → `error`
- [ ] `main.dart` → `AppInitializer` extraction
- [ ] Static service'ler → Riverpod provider'a dönüştür
- [ ] `AppMessenger`, `AppLoadingIndicator`, `AppCard`, `AppText` merkezi widget'ları oluştur

### Sprint 4: Test (1-2 hafta)
- [ ] `AuthService` unit test
- [ ] `BaseRepository` + `RepositoryErrorHandler` unit test
- [ ] Login form widget test
- [ ] Registration flow widget test
- [ ] RLS policy integration test (Supabase test client ile)

### Sprint 5: UI/UX (1-2 hafta)
- [ ] 500+ satırlık ekranları parçala
- [ ] Accessibility (semanticLabel, FocusNode, Semantics)
- [ ] Asset optimizasyonu (PNG → WebP, app_icon 1.4 MB → <200 KB)
- [ ] Tablet desteği (OrientationBuilder + adaptif grid)
- [ ] İngilizce ARB dosyası (`app_en.arb`)

---

## 📁 İlgili Dosyalar

| Dosya | Bulgu | Risk |
|-------|-------|------|
| `lib/core/config/env.g.dart` | Repo'da XOR obfuscated secret | Kritik |
| `supabase/migrations/006_profiles_and_premium.sql` | RLS `using(true)` | Kritik |
| `android/app/google-services.json` | Gerçek key, ignore edilmemiş | Kritik |
| `android/app/build.gradle.kts` | minify/shrink kapalı, debug signing fallback | Yüksek |
| `.github/workflows/production.yml` | Secret injection yok | Yüksek |
| `lib/services/auth_service.dart` | Client-side admin/premium | Yüksek |
| `analysis_options.yaml` | Gevşek lint kuralları | Orta |
| `lib/main.dart` | 320+ satır monolit | Orta |
| `lib/services/ai/ai_engine.dart` | Gemini key URL query param | Orta |
| `lib/services/invite_service.dart` | `invite_used` schema uyumsuzluğu | Orta |
| `lib/core/ssl_pinning.dart` | SSL pinning tamamlanmamış | Düşük |
| `pubspec.yaml` | Hive şifrelenmemiş | Düşük |

---

*Rapor, 4 paralel analiz agent'ının çıktılarından derlenmiştir: Mimari, Güvenlik/Dependency, UI/UX/Localization, Build/CI.*
