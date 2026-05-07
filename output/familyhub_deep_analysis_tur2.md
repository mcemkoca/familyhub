# 🔬 TUR 2 - DEPENDENCY & COUPLING ANALİZİ
**Tarih:** 2026-05-03 | Derinlik Seviyesi: 2/∞

---

## 🎯 BU TURUN HEDEFİ
Mevcut: 55+ 3rd party paket, 1318 import satırı, flat repository/services yapısı
Hedef: Bağımlılık matrisini çıkarmak, tight coupling ve circular dependency'leri tespit etmek
Strateji: Document/Map - Mevcut bağımlılıklar korunarak haritalanıyor
Korunan: Tüm mevcut import zincirleri ve paket kullanımları

---

## 📦 3RD PARTY PAKET KULLANIM MATRİSİ

**Toplam Import Satırı:** 1,318

| Paket | Kullanım Sayısı | Kategori |
|-------|----------------|----------|
| `flutter` (SDK) | 219x | Core Framework |
| `supabase_flutter` | 60x | Backend/Database |
| `go_router` | 52x | Navigation |
| `flutter_riverpod` | 39x | State Management |
| `intl` | 10x | Localization/Formatting |
| `geolocator` | 10x | Location Services |
| `hive` / `hive_flutter` | 15x | Local Cache |
| `image_picker` | 6x | Media Selection |
| `permission_handler` | 5x | Runtime Permissions |
| `flutter_secure_storage` | 5x | Secure Storage |
| `local_auth` | 4x | Biometric Auth |
| `google_sign_in` | 4x | OAuth |
| `amplitude_flutter` | 4x | Analytics |
| `flutter_stripe` | 2x | Payments |
| `http` | 2x | HTTP Client |
| `sentry` | 2x | Error Tracking |

**Dikkat Çeken Bulgu:** `supabase_flutter` 60x import edilmiş - bu veritabanı katmanının her yerden erişilebilir olduğunu gösteriyor (tight coupling).

---

## 🔗 INTERNAL MODULE COUPLING

### Layer Crossing Analysis

```
presentation/screens/  ──imports──>  repositories/    (22 ekran dosyası)
presentation/screens/  ──imports──>  services/        (~35 ekran dosyası)
presentation/providers/──imports──>  repositories/    (Tüm major provider'lar)
services/              ──imports──>  repositories/    (~20 service dosyası)
```

**Coupling Skoru: YÜKSEK** ⚠️
- Presentation katmanı doğrudan Repository katmanına bağımlı
- `Domain` katmanı sadece entity'lerden oluşuyor, interface/arayüz yok
- `Services` → `Repositories` → `Supabase` zinciri tek yönlü ama sıkı

---

## 🔍 TESPİTLER (8 Adet)

### Tespit 1: [DEPENDENCY] - Supabase Tight Coupling
**Kategori:** Backend Coupling
**Detay:** `supabase_flutter` 60 farklı dosyada import edilmiş. `BaseRepository` ve tüm alt repository'ler doğrudan `Supabase.instance.client`'a bağımlı. Eğer Supabase değişirse veya offline-first bir çözüme geçilirse, 60+ dosya değişmeli.
**Risk:** Yüksek - Vendor lock-in oluşmuş durumda.
**Refinement Önerisi:** Repository interface'leri `domain/` altına taşınmalı, `BaseRepository` abstract hale getirilmeli.

### Tespit 2: [DEPENDENCY] - GoRouter vs Flutter Navigator Karışıklığı
**Kategori:** Navigation
**Detay:** `go_router` 52x kullanılıyor. Ama bazı yerlerde `Navigator.of(context).push(MaterialPageRoute(...))` kullanımı var (`call_service.dart` gibi). İki navigation sistemi paralel çalışıyor.
**Risk:** Orta - Tutarsız navigation pattern kullanıcı deneyimini etkileyebilir.

### Tespit 3: [DEPENDENCY] - Kullanılmayan Paket Şüphesi
**Kategori:** Dead Weight
**Detay:** `purchases_flutter` (RevenueCat) tanımlı ama kullanımı sınırlı görünüyor. `flutter_stripe` da sadece 2 dosyada import edilmiş. `google_mlkit_text_recognition` OCR için tanımlı ama belirgin bir kullanım yeri yok (gerekirse kontrol edilmeli).
**Risk:** Düşük - APK boyutunu artırıyor olabilir.

### Tespit 4: [COUPLING] - Presentation → Repository Direkt Bağlantı
**Kategori:** Layer Violation
**Detay:** 22 ekran dosyası doğrudan `repositories/` import ediyor. Clean Architecture'da presentation → service → repository olmalı. Ama bu projede presentation bazen repository'yi doğrudan çağırıyor (özellikle `hub_screen.dart` ve `budget_screen.dart`).
**Risk:** Orta - Business logic ekranlara sızmış durumda.

### Tespit 5: [COUPLING] - Analytics Çoklu Enstrümantasyon
**Kategori:** Analytics Sprawl
**Detay:** 3 farklı analytics paketi var:
- `firebase_analytics` (Google)
- `amplitude_flutter` (Amplitude)
- `mixpanel_flutter` (Mixpanel)

Hepsi muhtemelen farklı event'leri track ediyor. Bu, event isimlendirme tutarsızlığına yol açabilir.
**Risk:** Orta - Data fragmentation, aynı event 3 farklı yere gidiyor olabilir.

### Tespit 6: [COUPLING] - `main.dart` God Object Tendency
**Kategori:** Entry Point Coupling
**Detay:** `main.dart` 30+ import içeriyor. Sentry, Firebase, Stripe, Hive, Notifications, Analytics hepsi `main()` içinde init ediliyor. `main.dart` uygulamanın "god object"'i haline gelmiş.
**Risk:** Orta - Yeni servis eklemek `main.dart`'ı daha da şişirecek.
**Refinement Önerisi:** `AppInitializer` sınıfı oluşturulup init zinciri oraya taşınmalı.

### Tespit 7: [COUPLING] - Circular Dependency Potansiyeli
**Kategori:** Circular Import
**Detay:** `app_providers.dart` → `HubRepository()` → `HiveService` → `app_providers.dart` (indirect). `services/` ve `repositories/` arasındaki sınır bulanık. `AuthService` hem `presentation/` hem `repositories/` tarafından kullanılıyor.
**Risk:** Düşük-Orta - Şu an compile ediyor ama gelecekte circular import hatası çıkabilir.

### Tespit 8: [DEPENDENCY] - `flutter_dotenv` ile `.env` Yönetimi
**Kategori:** Secret Management
**Detay:** `.env` dosyası `assets:` altında tanımlı (`- .env`). Bu, APK içinde `.env` dosyasının plain text olarak paketlenmesi anlamına geliyor. `flutter_dotenv` runtime'da okuyor ama APK decompile edilebilir.
**Risk:** Yüksek - API key'ler ve secret'lar APK içinde açık metin olarak bulunabilir.
**Refinement Önerisi:** Native Android `local.properties` veya `BuildConfig` kullanılmalı, `.env` asset olarak eklenmemeli.

---

## 🛠️ UYGULANAN REFINEMENT'LAR

Bu turda **aktif kod değişikliği yapılmadı** (Dependency mapping turu). Tespitler dokümante edildi.

---

## 📊 METRİKLER

| Metrik | Tur Başlangıcı | Tur Sonu | Değişim |
|--------|---------------|----------|---------|
| 3rd Party Paket Sayısı | 55+ | 55+ | 0 |
| Toplam Import Satırı | 1,318 | 1,318 | 0 |
| Supabase Import Sayısı | 60 | 60 | 0 |
| Layer Violation (Presentation→Repo) | 22 | 22 | 0 |
| Analytics Paket Sayısı | 3 | 3 | 0 |

---

## 🧬 KEŞFEDİLEN YENİ DERİNLİK

**`.env` Asset Olarak Paketleniyor:** `pubspec.yaml`'da `assets: - .env` tanımı var. Bu, uygulama dağıtımındaki en kritik güvenlik açığı olabilir. Supabase URL ve anon key gibi değerler APK içinde plain text olarak mevcut.

---

## 🎯 SONRAKİ TUR TAHMİNİ

**Tur 3 Hedefi:** State Yönetimi Arkeolojisi
**Beklenen Derinlik:** Riverpod provider ağacının tam haritası, global vs local state ayrımı, async state handling pattern'leri
**Potansiyel Tespitler:** Provider invalidate stratejileri, memory leak potansiyelli provider'lar, state mutation anti-pattern'leri

---

✅ **TUR 2 TAMAMLANDI**
Sonraki İşlem: OTOMATİK DEVAM -> Tur 3
Durum: Kullanıcı "DUR" demediği sürece devam ediyor...
