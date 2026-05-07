# Deployment Guide

## Prerequisites
- Flutter SDK ^3.19.0
- Android Studio / Xcode
- Supabase CLI (for migrations)
- Firebase project (for FCM, Analytics, Crashlytics)

## Environment Setup
1. Copy `.env.example` to `.env` for development.
2. For production, use `--dart-define-from-file=.env.prod` or compile-time env vars.
3. Run code generation for envied:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## Build Commands

### Android Release (with obfuscation)
```bash
flutter build apk --release \
  --obfuscate --split-debug-info=./symbols \
  --dart-define-from-file=.env.prod
```

### iOS Release
```bash
flutter build ios --release --no-codesign
```

## CI/CD Pipeline
- **Flutter CI**: Runs on every push/PR (`flutter analyze`, `flutter test`).
- **Supabase Deploy**: Runs on push to `main` when migrations change.
- **Release Build**: Triggered on tags `v*`.

## Store Submission
1. Update `pubspec.yaml` version.
2. Tag release: `git tag v1.0.0 && git push origin v1.0.0`.
3. Download artifacts from GitHub Actions.
4. Upload to Google Play Console / App Store Connect.

## Security Checklist
- [ ] `.env` and `lib/env.g.dart` are in `.gitignore`.
- [ ] Production builds use `--obfuscate`.
- [ ] Android ProGuard rules are configured.
- [ ] iOS Keychain is used for sensitive data (handled by `flutter_secure_storage`).
- [ ] RLS policies are active on all tables.
