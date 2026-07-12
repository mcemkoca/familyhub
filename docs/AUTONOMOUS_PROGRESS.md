# FamilyHub — Otonom Geliştirme İlerleme Raporu

_Son güncelleme: 2026-07-12 (Europe/Brussels) · Otonom oturum_

## Depo
- **Remote:** https://github.com/mcemkoca/familyhub  _(hedef `familyhubkalan` erişilemedi; kullanıcı onayıyla `familyhub` kullanıldı — bkz. Blokerler)_
- **Branch:** `feat/productization-session`
- **HEAD (başlangıç):** a568d59
- **Flutter:** /c/flutter (stable) · Dart bundled

## Başlangıç envanteri

| Öğe | Değer | Statü |
|---|---|---|
| Build (analyze) | `No issues found` (tüm proje) | DONE |
| Test | 214 geçti | DONE |
| flutter gen-l10n | temiz üretiliyor | DONE |
| ARB anahtar sayısı (tr/en/fr/nl) | 1783 / 1783 / 1783 / 1783 | DONE |
| ARB key parity | %100 (4 dil eşit) | DONE |
| Boş çeviri | 0 | DONE |
| Placeholder uyumsuzluğu | 0 kritik | DONE |
| l10n audit | 0 kritik, 51 uyarı (marka/özel ad — Plus, Complete, GIF, SOS…) | DONE |
| Hard-coded kullanıcı metni | 379 (830'dan düştü, 46 dosya) | IN_PROGRESS |
| TODO/FIXME/HACK | 6 | NOT_STARTED |
| Locale kodları | tr_TR, en_US, fr_BE, nl_BE (talimat en_GB/nl_BE/fr_BE istiyor) | IN_PROGRESS |
| Çok-dilli içerik modeli | yok → ekleniyor | IN_PROGRESS |
| Haftalık içerik sync workflow | yok → scaffold ekleniyor | IN_PROGRESS |
| Çeviri sağlayıcı | yapılandırılmamış | DEFERRED |

## Localization ilerlemesi (P1)
Kök neden (önceki oturum): locale state ZATEN reaktif (`localeProvider` StateProvider, kökte `MaterialApp.router` izliyor). Sorun hard-coded stringler.

**43 dosya AppLocalizations'a taşındı** — 830 → 395 hard-coded (%52 azalma). Her slice: analyze temiz · l10n audit 0 kritik · 214 test geçti. CI'da hard-coded ratchet (395) yeni sızıntıyı engelliyor. `test/features/i18n_locale_switch_test.dart` dil değişimini 4 dilde doğruluyor.

### Bilinçli ayrılanlar (farklı yaklaşım gerektirir)
- **İçerik ekranları** (masallar, makaleler, oyun tema adları): çok-dilli içerik kaydı gerektirir → Faz içerik modeli.
- **`app_providers` seed metinleri** (21): provider'da `BuildContext` yok; UI katmanında çözülmeli.
- **Kurum adları** (WHO/CDC/Kind en Gezin), rol/kategori config'leri (member_card, event_card): veri/context-bağlı.

## İçerik sistemi
- **Canonical model:** `lib/features/content/domain/localized_content.dart` (+ validator) — EKLENİYOR
- **Kaynak registry:** `config/content_sources.yaml` — EKLENİYOR
- **Haftalık workflow:** `.github/workflows/weekly-content-sync.yml` — SCAFFOLD
- **Çeviri sağlayıcı:** abstraction eklenecek; gerçek API secret gerektirir → DEFERRED (sahte "tamamlandı" iddiası yok)

## Doğrulama araçları
- `tool/hardcoded_string_scan.dart` — hard-coded tarayıcı + CI ratchet
- `tool/localization_audit.dart` — ARB parity/placeholder/boş değer (0 kritik → exit 0)

## Blokerler
- **Hedef depo `mcemkoca/familyhubkalan` erişilemedi** (`gh`: repository not found; yerel kopya yok). Kullanıcı `familyhub`'da devam onayı verdi. Eğer `familyhubkalan` ayrı bir depoysa, bu daldaki commit'ler oraya taşınmalı.

## Kalan öncelikler
1. Hard-coded 395 → azaltmaya devam (küçük widget/ekranlar).
2. Locale kodu `en_US` → `en_GB` (talimat gereği) — düşük riskli config.
3. İçerik modeli + testleri.
4. Haftalık sync workflow scaffold + config testi.
5. TODO/FIXME (6) değerlendirmesi.
