# 🔬 TUR 12 - INTERNATIONALIZATION & LOCALIZATION
**Tarih:** 2026-05-03 | Derinlik Seviyesi: 12/∞

**⚠️ KRİTİK BULGU: Uygulama tamamen hardcoded Türkçe string'lerle yazılmış, i18n altyapısı yok.**

---

## 🎯 BU TURUN HEDEFİ
Mevcut: `intl` paketi tanımlı ama sınırlı kullanımda
Hedef: Çoklu dil desteği ve kültürel adaptasyon durumunu analiz etmek
Strateji: Document/Audit - Mevcut dil yapısı korunarak inceleniyor
Korunan: Tüm mevcut string ve format kullanımları

---

## 🌍 I18N DURUMU ÖZETİ

### Kullanılan Dil
- **Primary:** Türkçe (100%)
- **Secondary:** Yok
- **ARB Dosyaları:** 0
- **l10n Klasörü:** Yok

### `intl` Paketi Kullanımı: 83
- `DateFormat`, `NumberFormat` için kullanılıyor
- Ama string localization için kullanılmıyor

---

## 🔍 TESPİTLER (8 Adet)

### Tespit 1: [I18N] - 4,653 Hardcoded String (KRİTİK)
**Kategori:** String Management
**Detay:** 4,653 hardcoded string var. Hiçbiri `AppLocalizations` veya benzeri bir sistem üzerinden gelmiyor. Uygulamayı başka bir dile çevirmek için 4,653 dosya düzenlenmeli.
**Risk:** ÇOK YÜKSEK - Global pazara çıkış imkansız.
**Refinement:** `flutter gen-l10n` ile ARB altyapısı kurulmalı ve tüm string'ler extract edilmeli.

### Tespit 2: [I18N] - `initializeDateFormatting('tr_TR')` Hardcoded
**Kategori:** Date Localization
**Detay:** `main.dart`'ta `initializeDateFormatting('tr_TR', null)` çağrılıyor. Bu sadece Türkçe tarih formatını init ediyor.
**Risk:** Orta - Diğer dillerde tarih formatı yanlış görünecek.

### Tespit 3: [I18N] - RTL Desteği Yok
**Kategori:** RTL Support
**Detay:** Arapça, İbranice, Farsça gibi RTL diller için hiçbir destek yok. `Directionality` widget'ı kullanılmıyor.
**Risk:** Orta - Ortadoğu pazarı kapanıyor.

### Tespit 4: [I18N] - `languageSettings` Ekranı Mevcut Ama Fonksiyonel Değil
**Kategori:** Settings UX
**Detay:** `language_settings_screen.dart` mevcut. Ama dil değiştirme fonksiyonu implemente edilmemiş. Sadece placeholder.
**Risk:** Düşük - UI var ama backend yok.

### Tespit 5: [I18N] - Number/Decimal Format Tutarsız
**Kategori:** Number Localization
**Detay:** `NumberFormat` kullanımı var (83 `intl` kullanımından bazıları). Ama tutarlı değil. Bazı yerlerde `toStringAsFixed(2)`, bazı yerlerde `NumberFormat.currency()` kullanılıyor.
**Risk:** Düşük - Para birimi formatı tutarsız.

### Tespit 6: [I18N] - Currency Hardcoded
**Kategori:** Currency
**Detay:** Uygulamada `TL`, `₺`, `TRY` gibi Türk Lirası referansları var. Döviz desteği yok.
**Risk:** Düşük - Aile uygulaması için TL yeterli olabilir.

### Tespit 7: [I18N] - Content Adaptation Yok
**Kategori:** Cultural
**Detay:** Onboarding görselleri, içerik önerileri, örnek data (meal_planning.json, household.json) tamamen Türk kültürüne göre. Diğer kültürlere adaptasyon yok.
**Risk:** Düşük - Aile uygulaması için yerelleştirilmiş içerik normal.

### Tespit 8: [I18N] - `intl` Paketi Kullanılmıyor String için
**Kategori:** Framework
**Detay:** `intl: ^0.20.2` tanımlı ama sadece date/number formatting için kullanılıyor. `Intl.message()`, `Intl.plural()`, `Intl.gender()` hiç kullanılmıyor.
**Risk:** Orta - Paket var ama i18n için kullanılmıyor.

---

## 🛠️ UYGULANAN REFINEMENT'LAR

Bu turda **aktif kod değişikliği yapılmadı** (I18N audit turu). Tespitler dokümante edildi.

---

## 📊 METRİKLER

| Metrik | Tur Başlangıcı | Tur Sonu | Değişim |
|--------|---------------|----------|---------|
| Hardcoded String | 4,653 | 4,653 | 0 |
| ARB Dosyası | 0 | 0 | 0 |
| Supported Language | 1 (TR) | 1 (TR) | 0 |
| RTL Support | 0 | 0 | 0 |
| `intl` String Usage | 0 | 0 | 0 |

---

## 🧬 KEŞFEDİLEN YENİ DERİNLİK

**"Monolingual Prison":** Uygulama Türkçe olarak tasarlanmış ve hiçbir i18n altyapısı düşünülmemiş. 4,653 string'in extract edilmesi ve çevrilmesi büyük bir refactor gerektirir. Bu, projenin global pazara çıkışını ciddi şekilde geciktirecek.

---

## 🎯 SONRAKİ TUR TAHMİNİ

**Tur 13 Hedefi:** Accessibility Derinliği
**Beklenen Derinlik:** Screen reader compatibility, keyboard navigation, color blindness, font scaling, voice control
**Potansiyel Tespitler:** Eksik Semantics widget'ları, düşük contrast, touch target boyutları

---

✅ **TUR 12 TAMAMLANDI**
Sonraki İşlem: OTOMATİK DEVAM -> Tur 13
Durum: Kullanıcı "DUR" demediği sürece devam ediyor...
