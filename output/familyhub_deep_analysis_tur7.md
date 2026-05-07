# 🔬 TUR 7 - GÜVENLİK ARKEOLOJİSİ
**Tarih:** 2026-05-03 | Derinlik Seviyesi: 7/∞

**⚠️ KRİTİK GÜVENLİK UYARISI: Bu turda yüksek riskli tespitler bulundu.**

---

## 🎯 BU TURUN HEDEFİ
Mevcut: Supabase backend, Firebase services, local encryption, RLS policies
Hedef: Security boundary'leri ve attack surface'ı tespit etmek
Strateji: Document/Audit - Mevcut güvenlik yapısı korunarak inceleniyor
Korunan: Tüm auth, encryption ve access control mekanizmaları

---

## 🔐 KONFİGÜRASYON ANALİZİ

### `.env` Dosyası İçeriği (ASSET OLARAK PAKETLENİYOR)

```yaml
# pubspec.yaml
assets:
  - .env
```

**🚨 KRİTİK BULGU:** `.env` dosyası `pubspec.yaml`'da asset olarak tanımlı. Bu, APK decompile edildiğinde:
- Supabase URL: `https://thnkpvbqiiuonqxlpgvb.supabase.co`
- Supabase ANON KEY: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- Stripe Publishable Key: `pk_test_your-publishable-key`

...hepsinin **plain text** olarak erişilebilir olması demek.

---

## 🛡️ RLS (ROW LEVEL SECURITY) POLİTİKALARI

**Toplam Policy Tanımı:** 218 satır SQL

| Migration | Policy Sayısı | Durum |
|-----------|--------------|-------|
| 034, 036, ve diğerleri | 218+ satır | Aktif |

**Tespit:** RLS politikaları tanımlı. Ama `PostgrestException: infinite recursion detected in policy for relation "family_members"` hatası önceki loglarda görüldü. Bu, RLS politikalarında circular reference olduğunu gösteriyor.

---

## 🔍 TESPİTLER (8 Adet)

### Tespit 1: [SECURITY] - `.env` Dosyası APK İçinde Plain Text (KRİTİK)
**Kategori:** Secret Exposure
**Detay:** `pubspec.yaml`'da `assets: - .env` tanımı var. `flutter_dotenv` runtime'da okuyor ama APK içinde `.env` plain text olarak bulunuyor. Supabase ANON KEY ve Stripe key herkes tarafından görülebilir.
**Risk:** ÇOK YÜKSEK - API key'ler public. Malicious user bu key'leri kullanarak Supabase'e doğrudan istek atabilir.
**Refinement:** `.env` asset listesinden çıkarılmalı. Secret'lar native `BuildConfig` veya `Keychain`/`Keystore`'ta saklanmalı.

### Tespit 2: [SECURITY] - Supabase ANON KEY JWT İmza Algoritması
**Kategori:** Token Security
**Detay:** ANON KEY bir JWT token. `alg: HS256` kullanıyor. Bu normal. Ama key APK içinde açık olduğu için, biri bu key'i alıp kendi JWT token'ını imzalayabilir (eğer `service_role` key değilse risk düşük, ama yine de exposure kötü).
**Risk:** Orta - ANON key sadece anonim erişim için. Ama RLS bypass edilemez ( teorik olarak ).

### Tespit 3: [SECURITY] - Stripe Test Key Production'da
**Kategori:** Payment Security
**Detay:** `.env`'de `STRIPE_PUBLISHABLE_KEY=pk_test_your-publishable-key`. Bu bir **test key**. Production build'te test key kullanılıyor olabilir.
**Risk:** Yüksek - Production'da test key kullanımı ödeme işlemlerini etkileyebilir.

### Tespit 4: [SECURITY] - Input Sanitization Eksikliği
**Kategori:** Input Validation
**Detay:** 324 form/input kullanımı var ama merkezi sanitization yok. Supabase parametrik query kullanıyor (sql injection riski düşük) ama XSS veya NoSQL injection riski var.
**Risk:** Düşük-Orta - Supabase client parametrik query kullanıyor, SQL injection riski minimal.

### Tespit 5: [SECURITY] - `flutter_secure_storage` Kullanımı Var
**Kategori:** Local Data Security
**Detay:** `flutter_secure_storage` paketi tanımlı ve kullanılıyor. Bu iyi - hassas data (token'lar, şifreler) encrypted storage'da saklanıyor.
**Risk:** Düşük - Doğru kullanılıyor.

### Tespit 6: [SECURITY] - Biometric Auth Mevcut
**Kategori:** Authentication
**Detay:** `local_auth` ve `biometric_service.dart` mevcut. Aile uygulamasında çocuk profiline erişimi kısıtlamak için biometric auth kullanılıyor.
**Risk:** Düşük - İyi bir güvenlik katmanı.

### Tespit 7: [SECURITY] - `encrypt` Paketi Kullanımı
**Kategori:** Data Encryption
**Detay:** `encrypt: ^5.0.3` paketi tanımlı. 96 yerde encrypt/hash kullanımı var. `encryption_service.dart` muhtemelen local data encryption yönetiyor.
**Risk:** Düşük - Encryption implementasyonu var.

### Tespit 8: [SECURITY] - RLS Infinite Recursion Hatası
**Kategori:** Backend Security
**Detay:** Önceki loglarda `PostgrestException: infinite recursion detected in policy for relation "family_members"` hatası görüldü. Bu, RLS politikalarında circular reference olduğunu gösteriyor. `family_members` tablosunun SELECT policy'si kendini recursive çağırıyor olabilir.
**Risk:** Yüksek - Bu hata tüm `family_members` sorgularını başarısız kılıyor. Aile üyesi listesi, çocuk dashboard, vs. etkileniyor.
**Refinement:** Backend RLS politikaları review edilmeli (ama Flutter tarafında çözülemez).

---

## 🛠️ UYGULANAN REFINEMENT'LAR

Bu turda **aktif kod değişikliği yapılmadı** (Güvenlik audit turu). Tespitler dokümante edildi.

---

## 📊 METRİKLER

| Metrik | Tur Başlangıcı | Tur Sonu | Değişim |
|--------|---------------|----------|---------|
| RLS Policy Satırı | 218 | 218 | 0 |
| Encryption Kullanımı | 96 | 96 | 0 |
| Input/Form Kullanımı | 324 | 324 | 0 |
| `.env` Asset Olarak | 1 | 1 | 0 |
| Secure Storage Kullanımı | Var | Var | 0 |
| Biometric Auth | Var | Var | 0 |

---

## 🧬 KEŞFEDİLEN YENİ DERİNLİK

**"APK Decompile = Full Database Access":** `.env` dosyası APK içinde plain text olarak bulunduğu için, APK'yı decompile eden herkes:
1. Supabase URL ve ANON KEY'i alır
2. Doğrudan Supabase REST API'ye istek atabilir
3. RLS politikaları bypass edilemez (teorik olarak) ama brute force veya enumeration attack yapılabilir

Bu, **CWE-798: Use of Hard-coded Credentials** kategorisine girer.

---

## 🎯 SONRAKİ TUR TAHMİNİ

**Tur 8 Hedefi:** Test Arkeolojisi
**Beklenen Derinlik:** Unit test coverage, integration test senaryoları, E2E test kritik path'leri
**Potansiyel Tespitler:** Test coverage boşlukları, mock stratejisi eksiklikleri, flaky test'ler

---

✅ **TUR 7 TAMAMLANDI**
Sonraki İşlem: OTOMATİK DEVAM -> Tur 8
Durum: Kullanıcı "DUR" demediği sürece devam ediyor...
