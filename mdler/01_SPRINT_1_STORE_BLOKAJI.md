# SPRINT 1: STORE BLOKAJI — ACIL
## 5 Kritik Sorun | Hedef: Derleme + Store Onayi

---

## 1. app_links Bagimliligi Ekle

**Sorun:** `deep_link_service.dart` import ediyor ama `pubspec.yaml`'da yok → **Derleme hatasi**

### pubspec.yaml
```yaml
dependencies:
  app_links: ^6.3.2
```

### lib/core/services/deep_link_service.dart
```dart
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;

  Future<void> init() async {
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleDeepLink(initialUri);
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    switch (uri.path) {
      case '/verify-email':
        // Email verification
        break;
      case '/reset-password':
        // Password reset
        break;
    }
  }
}
```

---

## 2. Firebase API Key — envied'e Tasi

**Sorun:** `firebase_options.dart:44` gercek API key exposed → **Secret leak**

### pubspec.yaml
```yaml
dependencies:
  envied: ^1.1.0
dev_dependencies:
  envied_generator: ^1.1.0
  build_runner: ^2.4.0
```

### .env (gitignore'a ekle!)
```
FIREBASE_ANDROID_API_KEY=your_android_key_here
FIREBASE_IOS_API_KEY=your_ios_key_here
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### lib/core/config/env.dart
```dart
import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY', obfuscate: true)
  static final String firebaseAndroidApiKey = _Env.firebaseAndroidApiKey;

  @EnviedField(varName: 'FIREBASE_IOS_API_KEY', obfuscate: true)
  static final String firebaseIosApiKey = _Env.firebaseIosApiKey;

  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static final String supabaseAnonKey = _Env.supabaseAnonKey;
}
```

### Build komutu
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release --obfuscate --split-debug-info=./symbols
```

### .gitignore ekle
```
.env
env.g.dart
```

---

## 3. iOS Info.plist — 6 Usage Description + UIBackgroundModes

**Sorun:** App Store red — eksik privacy descriptions

### ios/Runner/Info.plist
```xml
<dict>
    <!-- Mevcut key'lerin altina ekle -->

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Uygulama, acil durumlarda ve hava durumu icin konumunuza ihtiyac duyar.</string>

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Hava durumu ve canli destek icin konum bilginiz kullanilir.</string>

    <key>NSCameraUsageDescription</key>
    <string>Profil fotografi ve acil durum goruntuleri icin kamera erisimi gerekli.</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>Profil fotografi secimi icin fotograf kutuphanesine erisim gerekli.</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>Ambiyans dinleme ve canli destek icin mikrofon erisimi gerekli.</string>

    <key>NSFaceIDUsageDescription</key>
    <string>Uygulamaya guvenli giris icin Face ID kullanilir.</string>

    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>location</string>
        <string>processing</string>
        <string>remote-notification</string>
    </array>
</dict>
```

---

## 4. Android Signing Config — Release Build

**Sorun:** `signingConfig = debug` → **Play Store'a yuklenemez**

### android/app/build.gradle.kts
```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("RELEASE_STORE_FILE") ?: "release.keystore")
            storePassword = System.getenv("RELEASE_STORE_PASSWORD")
            keyAlias = System.getenv("RELEASE_KEY_ALIAS")
            keyPassword = System.getenv("RELEASE_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### android/app/proguard-rules.pro
```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Supabase
-keep class io.supabase.** { *; }

# Crashlytics line numbers
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

---

## 5. mood_entries Migration Olustur

**Sorun:** Tablo yok → **Runtime crash**

### supabase/migrations/047_mood_entries.sql
```sql
CREATE TABLE IF NOT EXISTS mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    mood_score INT CHECK (mood_score BETWEEN 1 AND 10),
    mood_label VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own mood entries"
ON mood_entries FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

### Calistirma
```bash
supabase db push
# VEYA Supabase Dashboard → SQL Editor → New Query → Run
```

---

## Kontrol Listesi

- [ ] `app_links` pubspec.yaml'da
- [ ] `envied` kurulu, `.env` gitignore'da
- [ ] `env.g.dart` gitignore'da
- [ ] Build `--obfuscate` ile
- [ ] iOS Info.plist 6 description + UIBackgroundModes
- [ ] Android signingConfig = release
- [ ] Proguard rules tamam
- [ ] `mood_entries` migration calisti
- [ ] `flutter build` hatasiz

---
**Versiyon:** 1.0 | **Sprint:** 1/4 | **Hedef:** Store Blokaji Kalkti
