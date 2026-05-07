# 🔬 TUR 1 - YAPISAL ARKEOLOJİ
**Tarih:** 2026-05-03 | Derinlik Seviyesi: 1/∞

---

## 🎯 BU TURUN HEDEFİ
Mevcut: FamilyHub Flutter projesinin klasör yapısı, entry point'leri ve organizasyon mantığı
Hedef: Tam yapısal harita çıkarmak, gizli bağımlılıkları ve organizasyon anti-pattern'lerini tespit etmek
Strateji: Extract/Document - Mevcut yapı korunarak analiz ediliyor
Korunan: Tüm mevcut klasör yapısı ve dosya organizasyonu

---

## 📂 PROJE YAPISI ÖZETİ

```
familyhub/
├── android/                 # Android native build (Gradle 8.x, Kotlin, minSdk 21)
├── ios/                     # iOS native build (Xcode workspace)
├── lib/                     # Ana kaynak kodu (~260 Dart dosyası)
│   ├── components/          # 4 dosya - Hub alt bileşenleri
│   ├── config/              # 3 dosya - Routes, theme, constants
│   ├── core/                # 16 dosya - Extensions, errors, analytics, SSL, Sentry
│   ├── domain/              # 27 dosya - Entity/Model tanımları
│   ├── presentation/        # 122 dosya - Screens, widgets, providers
│   │   ├── providers/       # Riverpod provider tanımları
│   │   ├── screens/         # 20+ ekran klasörü
│   │   └── widgets/         # Yeniden kullanılabilir UI bileşenleri
│   ├── repositories/        # 31 dosya - Supabase CRUD + realtime
│   ├── services/            # 50 dosya - Business logic, cache, auth, notifications
│   ├── firebase_options.dart
│   └── main.dart            # Entry point
├── assets/                  # 11 asset dosyası
│   ├── data/                # 5 JSON dosyası (child_dev, meal_plan, household, budget, future_planning)
│   └── images/              # App icon, onboarding, logos
├── integration_test/        # 2 test dosyası (geçici olarak disabled)
├── supabase/                # Migration dosyaları
├── test/                    # Unit testler
└── web/                     # Web manifest ve icons
```

---

## 🔍 TESPİTLER (8 Adet)

### Tespit 1: [YAPI] - Klasör Sayısı Asimetrisi
**Kategori:** Yapısal
**Detay:** `presentation/screens/` altında 20+ ekran klasörü var ama `presentation/widgets/` altındaki widget'lar ekranlara göre dağınık dağıtılmış. Örneğin `settings/` widget'ları `presentation/widgets/settings/` altında ama `safety/` widget'ları `presentation/widgets/safety/` altında. Bu tutarlı.
**Risk:** Düşük - Tutarlı bir organizasyon mevcut.

### Tespit 2: [YAPI] - `domain/` Katmanı Yetersiz
**Kategori:** Katmanlı Mimari
**Detay:** `domain/` altında sadece entity tanımları var (27 dosya). Domain katmanında use case'ler, repository interface'leri ve domain logic yok. Tüm business logic `services/` ve `repositories/` katmanlarına sızmış.
**Risk:** Orta - Clean Architecture prensiplerine uygun değil, business logic presentation katmanına taşınabilir.

### Tespit 3: [YAPI] - `core/` ve `services/` Arasındaki Sınır Bulanık
**Kategori:** Sınır Belirsizliği
**Detay:** `core/` altında `analytics/`, `error/`, `ssl_pinning.dart` var. Ama `services/` altında da `auth_service.dart`, `encryption_service.dart` var. SSL pinning neden `core/`'da ama encryption `services/`'ta?
**Risk:** Düşük - Fonksiyonel çalışıyor ama yeni geliştiriciler için kafa karıştırıcı.

### Tespit 4: [YAPI] - 260 Dart Dosyası Tek `lib/` Altında
**Kategori:** Ölçeklenebilirlik
**Detay:** Proje 260 Dart dosyası içeriyor ve `lib/` altında 7 ana klasör var. Feature-based modülleme yok. Her feature (chat, budget, safety) kendi klasörünü `presentation/screens/` altında tutuyor ama `services/` ve `repositories/` flat yapıda.
**Risk:** Orta - Proje büyüdükçe navigation ve dependency management zorlaşacak.

### Tespit 5: [YAPI] - `components/` vs `widgets/` Ayrımı Belirsiz
**Kategori:** İsimlendirme
**Detay:** `lib/components/` (4 dosya) ve `lib/presentation/widgets/` (çok dosya) ayrı yerlerde. `components/` altındaki dosyalar aslında da `widget`. Flutter'da `components` ve `widgets` arasındaki fark belirsiz.
**Risk:** Düşük - Yeni bileşenler nereye konulacağı konusunda kararsızlık.

### Tespit 6: [YAPI] - Asset Yönetimi Minimal
**Kategori:** Resource
**Detay:** Sadece 11 asset dosyası var. Onboarding görselleri, birkaç JSON ve logo. Lottie animasyonları var ama asset klasöründe `.json` Lottie dosyası yok (muhtemelen network'ten veya kod içinde tanımlı).
**Risk:** Düşük - Aile uygulaması için daha fazla görsellik ve localized asset gerekebilir.

### Tespit 7: [YAPI] - Android Build Yapılandırması İnceleme
**Kategori:** Native Build
**Detay:** `android/app/build.gradle.kts`:
- `namespace = "com.example.familyhub"` → Production için uygun değil
- `signingConfig = signingConfigs.getByName("debug")` → Release build debug imzalı
- `isMinifyEnabled = true` + `isShrinkResources = true` → Proguard aktif (iyi)
- `abiFilters += listOf("arm64-v8a", "armeabi-v7a")` → 32-bit desteği hâlâ var
- `splits.abi.isEnable = false` → APK split disabled (tek büyük APK)
**Risk:** Orta - Package name ve signing config production öncesi değiştirilmeli.

### Tespit 8: [YAPI] - Entry Point Bağımlılık Enflasyonu
**Kategori:** Başlangıç Akışı
**Detay:** `main.dart` 30+ import içeriyor ve init sırasında 10+ servis başlatılıyor. Her servis `try-catch` ile sarılmış (iyi) ama sıralama kritik olabilir. Hive init önce, ardından auth, analytics, sentry, notifications, vs.
**Risk:** Düşük - Init sırası mantıklı görünüyor ama başarısız olan servisler sessizce `debugPrint` ile loglanıyor, kullanıcıya bildirilmiyor.

---

## 🛠️ UYGULANAN REFINEMENT'LAR

Bu turda **aktif kod değişikliği yapılmadı** (Yapısal analiz turu). Tespitler dokümante edildi.

---

## 📊 METRİKLER

| Metrik | Tur Başlangıcı | Tur Sonu | Değişim |
|--------|---------------|----------|---------|
| Toplam Dart Dosyası | 260 | 260 | 0 |
| Klasör Derinliği (max) | 6 | 6 | 0 |
| Feature Modül Sayısı | ~15 | ~15 | 0 |
| Asset Dosya Sayısı | 11 | 11 | 0 |
| 3rd Party Bağımlılık | 55+ | 55+ | 0 |

---

## 🧬 KEŞFEDİLEN YENİ DERİNLİK

**"Hibernating Code" Tespiti:** `lib/presentation/providers/hub_providers.dart` dosyası mevcut ama hiçbir yerde import edilmiyor. `familyIdProvider`, `todaySummaryProvider` gibi provider'lar `app_providers.dart`'ta da tanımlı. Bu dosya bir **zombi modül** - var ama ölü.

---

## 🎯 SONRAKİ TUR TAHMİNİ

**Tur 2 Hedefi:** Dependency & Coupling Analizi
**Beklenen Derinlik:** 3rd party paketlerin kullanım yerleri, internal module coupling, circular dependency tespiti
**Potansiyel Tespitler:** Kullanılmayan paketler, tight coupling noktaları, mixin/interface eksiklikleri

---

✅ **TUR 1 TAMAMLANDI**
Sonraki İşlem: OTOMATİK DEVAM -> Tur 2
Durum: Kullanıcı "DUR" demediği sürece devam ediyor...
