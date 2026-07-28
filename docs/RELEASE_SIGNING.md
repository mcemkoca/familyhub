# Release İmzalama Kurulumu (Android)

FamilyHub'ın release signing config'i **environment değişkenleri** ile çalışır
(`android/app/build.gradle.kts`). Repo'da hiçbir keystore veya şifre bulunmaz —
`.gitignore` `*.jks`, `*.keystore`, `android/key.properties`, `.env.prod`'u engeller.

## Gerekli environment değişkenleri

| Değişken | Açıklama |
|---|---|
| `KEYSTORE_PATH` | `.jks` dosyasının mutlak yolu |
| `KEYSTORE_PASSWORD` | Keystore şifresi |
| `KEY_ALIAS` | Anahtar alias'ı (ör. `familyhub`) |
| `KEY_PASSWORD` | Alias şifresi |

`KEYSTORE_PATH` **tanımlı değilse** release build imzasız kalır (build.gradle.kts
signing config'i atlar) — bu yüzden CI'da release job yalnızca secret'lar varken
çalıştırılmalı.

## Keystore oluşturma (keystore sahibi yapar — repoya KOYULMAZ)

```bash
keytool -genkeypair -v \
  -keystore familyhub-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias familyhub
```

Windows PowerShell'de `keytool` JDK ile gelir (`$env:JAVA_HOME\bin\keytool`).

## Yerel release build

```bash
export KEYSTORE_PATH=/güvenli/yol/familyhub-release.jks
export KEYSTORE_PASSWORD=***
export KEY_ALIAS=familyhub
export KEY_PASSWORD=***

flutter build apk --release --dart-define-from-file=.env.prod
flutter build appbundle --release --dart-define-from-file=.env.prod
```

## CI (GitHub Actions)

Release job (`flutter.yml` → `build-android`, yalnızca `v*` tag'lerinde) için
şu **secret'ları** GitHub repo ayarlarından ekle (değerleri commit ETME):
`SUPABASE_URL`, `SUPABASE_ANON_KEY` (anon key public'tir), `FIREBASE_*`,
`STRIPE_PUBLISHABLE_KEY`, `OPENWEATHER_API_KEY`. Keystore secret'ları için
ayrıca `KEYSTORE_PATH`/`KEYSTORE_PASSWORD`/`KEY_ALIAS`/`KEY_PASSWORD` eklenmeli
ve keystore dosyası bir base64 secret'tan runtime'da çözülmelidir.

## İmza doğrulama

```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
```

## Durum (bu ortamda)

- Signing config: ✅ env-var tabanlı, secret repo'da yok
- `.gitignore`: ✅ keystore/key.properties/.env.prod engelli
- Keystore dosyası: ⛔ **BLOCKED** — fiziksel keystore sahibi tarafından
  sağlanmalı; bu ortamda üretilemez/commit edilemez.
- Release build çalıştırma + `apksigner verify`: ⛔ keystore olmadan NOT_RUN.
