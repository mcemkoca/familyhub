# 🚀 Deployment Rehberi

## Geliştirme Ortamı

```bash
# Debug build (hızlı)
flutter run

# Profil build (performans analizi)
flutter run --profile
```

## Android Release

### 1. Keystore Oluşturma

```bash
keytool -genkey -v \
  -keystore ~/familyhub-release.keystore \
  -alias familyhub \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 2. Ortam Değişkenleri

```bash
export KEYSTORE_PATH=~/familyhub-release.keystore
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=familyhub
export KEY_PASSWORD=your_password
```

### 3. Release Build

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./symbols

# veya App Bundle (Google Play için)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=./symbols
```

### 4. CI/CD (GitHub Actions)

```yaml
# .github/workflows/release.yml (basitleştirilmiş)
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
      - run: |
          flutter build appbundle --release \
            --obfuscate \
            --split-debug-info=./symbols \
            --dart-define-from-file=.env.prod
      - uses: actions/upload-artifact@v4
        with:
          name: appbundle
          path: build/app/outputs/bundle/release/app-release.aab
```

## iOS Release

### 1. Sertifikalar

- Apple Developer Account
- Distribution certificate
- Provisioning profile

### 2. Build

```bash
flutter build ios --release

# Archive (Xcode)
open ios/Runner.xcworkspace
# Product → Archive
```

### 3. App Store Connect

- Xcode Organizer'dan upload
- veya `fastlane` ile otomasyon

## Supabase Deployment

### Migration Çalıştırma

```bash
# CLI ile
supabase db push

# Veya tek tek
supabase migration up
```

### Edge Functions

```bash
# Deploy
supabase functions deploy verify-child-pin
supabase functions deploy delete-user-account

# Logs
supabase functions logs verify-child-pin
```

## Firebase Deployment

### Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### Remote Config

```bash
firebase remoteconfig:get -o remote_config.json
# Düzenle
firebase remoteconfig:publish
```

## Versiyonlama

### Semantic Versioning

```
1.2.3
│ │ │
│ │ └── Patch (bugfix)
│ └──── Minor (feature)
└────── Major (breaking change)
```

### Versiyon Tag'leme

```bash
# pubspec.yaml'da versiyonu güncelle
# version: 1.2.3+10  # +10 = build number

git add pubspec.yaml CHANGELOG.md
git commit -m "chore(release): v1.2.3"
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin main --tags
```

### CI Otomasyonu

Tag push'landığında otomatik release build:

```yaml
# .github/workflows/flutter.yml
build-android:
  if: startsWith(github.ref, 'refs/tags/v')
  # ... release build + artifact upload
```

## Rollback Stratejisi

| Durum | Aksiyon | Süre |
|-------|---------|------|
| Kritik bug | Hotfix branch → PR → Hızlı merge | < 2 saat |
| Veritabanı hatası | Önceki migration'ı down yap | < 1 saat |
| Performans düşüşü | Önceki APK'ya geri dön | < 30 dk |

## Checklist

### Release Öncesi

- [ ] `flutter analyze` temiz
- [ ] `flutter test` geçiyor
- [ ] Version bump yapıldı
- [ ] CHANGELOG.md güncellendi
- [ ] `pubspec.yaml` version güncel
- [ ] Keystore erişilebilir
- [ ] `.env.prod` değerleri doğru

### Release Sonrası

- [ ] Smoke test (login, kayıt, temel akışlar)
- [ ] Crashlytics izleme aktif
- [ ] Analytics event'leri geliyor
- [ ] Push notification test edildi
- [ ] IAP / abonelik test edildi

---

*Detaylı deployment bilgisi için [DEPLOYMENT.md](https://github.com/mcemkoca/familyhub/blob/main/DEPLOYMENT.md) dosyasına bakın.*
