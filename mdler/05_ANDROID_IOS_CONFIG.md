# ANDROID & iOS KONFIGURASYON
## 16 Konfigurasyon Sorunu | Hedef: Platform Uyumlulugu

---

## 23. AndroidManifest.xml — Eksik Izinler

**Sorun:** ACTIVITY_RECOGNITION, HIGH_SAMPLING_RATE_SENSORS, WAKE_LOCK, FOREGROUND_SERVICE_MICROPHONE, enableOnBackInvokedCallback eksik

### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Mevcut izinler -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

    <!-- EKSIK IZINLER EKLENDI: -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
    <uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.SEND_SMS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="Aile Asistani"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">  <!-- ← EKLENDI -->

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep linking -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="aileasistani" android:host="app"/>
            </intent-filter>
        </activity>

        <!-- Background services -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="location|microphone"
            android:exported="true"/>

        <receiver
            android:name="androidx.work.impl.diagnostics.DiagnosticsReceiver"
            android:permission="android.permission.DUMP"
            android:exported="true"/>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
```

---

## 24. Proguard Rules — Tamamlama

**Sorun:** Crashlytics line number rules eksik, flutter_contacts keep rule eksik

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
-keep class com.google.firebase.crashlytics.** { *; }

# Crashlytics line numbers
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Supabase
-keep class io.supabase.** { *; }
-keep class com.postgrest.** { *; }

# flutter_contacts
-keep class com.github.sarbagyastha.** { *; }
-keep class kotlin.** { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.api.client.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local Auth
-keep class androidx.biometric.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }

# Prevent obfuscation of model classes
-keep class your.app.package.models.** { *; }
-keepclassmembers class your.app.package.models.** { *; }
```

---

## 25. iOS Podfile — Platform Version

**Sorun:** Eski iOS versiyonu destegi

### ios/Podfile
```ruby
platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(
    File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist"
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # RevenueCat
  pod 'PurchasesHybridCommon', '13.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

---

## 26. Version Yukseltme

**Sorun:** `0.1.0+1` cok dusuk

### pubspec.yaml
```yaml
name: aile_asistani
description: Aile Asistani - Akilli Ev Yonetimi

publish_to: 'none'

version: 1.0.0+10  # ← YUKSELTILDI (1.0.0 sürüm, +10 build number)

environment:
  sdk: '>=3.0.0 <4.0.0'
```

---

## 27. Onboarding — Remote Config ile

**Sorun:** Content hardcoded, remote A/B imkansiz

### lib/features/onboarding/models/onboarding_content.dart
```dart
class OnboardingContent {
  final String title;
  final String description;
  final String imageAsset;
  final String? actionButtonText;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.actionButtonText,
  });

  factory OnboardingContent.fromJson(Map<String, dynamic> json) {
    return OnboardingContent(
      title: json['title'],
      description: json['description'],
      imageAsset: json['image_asset'],
      actionButtonText: json['action_button_text'],
    );
  }
}
```

### lib/features/onboarding/services/onboarding_service.dart
```dart
class OnboardingService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<List<OnboardingContent>> getOnboardingContent() async {
    try {
      // Once remote config'ten dene
      await _remoteConfig.fetchAndActivate();
      final jsonString = _remoteConfig.getString('onboarding_content');

      if (jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((e) => OnboardingContent.fromJson(e)).toList();
      }
    } catch (e) {
      // Remote config basarisiz olursa local fallback
    }

    // Local fallback
    return _getLocalFallbackContent();
  }

  List<OnboardingContent> _getLocalFallbackContent() {
    return [
      OnboardingContent(
        title: AppLocalizations.of(navigatorKey.currentContext!)!.onboardingStep1,
        description: 'Ailenizi olusturun ve uyeleri ekleyin',
        imageAsset: 'assets/onboarding/family.png',
      ),
      OnboardingContent(
        title: AppLocalizations.of(navigatorKey.currentContext!)!.onboardingStep2,
        description: 'Gorevleri akilli sekilde dagitin',
        imageAsset: 'assets/onboarding/tasks.png',
      ),
      OnboardingContent(
        title: AppLocalizations.of(navigatorKey.currentContext!)!.onboardingStep3,
        description: 'Acil durumlar icin guvenli kalin',
        imageAsset: 'assets/onboarding/safety.png',
      ),
    ];
  }
}
```

### Firebase Remote Config Console:
```json
{
  "onboarding_content": [
    {
      "title": "Ailenizi Olusturun",
      "description": "Ailenizi olusturun ve uyeleri ekleyin",
      "image_asset": "assets/onboarding/family.png"
    },
    {
      "title": "Gorevleri Dagitin",
      "description": "Gorevleri akilli sekilde dagitin",
      "image_asset": "assets/onboarding/tasks.png"
    }
  ]
}
```

---

## 28. pubspec.yaml — Asset Tanimlari

**Sorun:** `household_tasks.json` asset olarak tanimli degil

### pubspec.yaml
```yaml
flutter:
  uses-material-design: true
  generate: true

  assets:
    # Onboarding
    - assets/onboarding/

    # Data
    - assets/data/household_tasks.json
    - assets/data/categories.json

    # Icons
    - assets/icons/

    # Images
    - assets/images/

    # Sounds
    - assets/sounds/emergency_alarm.mp3
    - assets/sounds/notification.mp3

    # Animations
    - assets/animations/loading.json
    - assets/animations/success.json
    - assets/animations/error.json

    # Fonts
    - assets/fonts/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## Kontrol Listesi

- [ ] AndroidManifest.xml tum izinler tamam
- [ ] Proguard rules Crashlytics + flutter_contacts
- [ ] iOS Podfile platform 14.0
- [ ] iOS Info.plist usage descriptions 6 adet
- [ ] iOS UIBackgroundModes aktif
- [ ] Version >= 1.0.0+10
- [ ] Onboarding remote config ile
- [ ] pubspec.yaml asset tanimlari tamam
- [ ] `flutter build apk --release` basarili
- [ ] `flutter build ios --release` basarili

---
**Versiyon:** 1.0 | **Dosya:** 5/10 | **Hedef:** Platform Uyumlulugu
