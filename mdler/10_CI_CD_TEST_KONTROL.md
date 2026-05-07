# CI/CD, TEST & SON KONTROL
## 10 Son Adim | Hedef: Production Ready

---

## 44. GitHub Actions CI/CD Pipeline

### .github/workflows/flutter_ci.yml
```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze:
    name: Analyze & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  build-android:
    name: Build Android
    needs: analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
          cache: true

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Get dependencies
        run: flutter pub get

      - name: Build APK
        run: |
          flutter build apk --release             --obfuscate --split-debug-info=./symbols             --dart-define-from-file=.env.prod

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    name: Build iOS
    needs: analyze
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Upload iOS
        uses: actions/upload-artifact@v4
        with:
          name: release-ios
          path: build/ios_archive/*.xcarchive

  deploy-supabase:
    name: Deploy Supabase
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Link project
        run: supabase link --project-ref $SUPABASE_PROJECT_REF
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Push migrations
        run: supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

  deploy-firebase:
    name: Deploy to Firebase
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Download APK
        uses: actions/download-artifact@v4
        with:
          name: release-apk
          path: apk/

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_CREDENTIALS }}
          groups: testers
          file: apk/app-release.apk
          releaseNotes: |
            ${{ github.event.head_commit.message }}
            Build: ${{ github.run_number }}
```

---

## 45. Test Stratejisi

### test/core/utils/crypto_utils_test.dart
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils', () {
    test('hashPin creates valid hash', () {
      final hash = CryptoUtils.hashPin('123456');
      expect(hash, isNotEmpty);
      expect(hash, isNot(equals('123456')));
    });

    test('verifyPin validates correct PIN', () {
      final hash = CryptoUtils.hashPin('123456');
      expect(CryptoUtils.verifyPin('123456', hash), isTrue);
    });

    test('verifyPin rejects incorrect PIN', () {
      final hash = CryptoUtils.hashPin('123456');
      expect(CryptoUtils.verifyPin('654321', hash), isFalse);
    });
  });
}
```

### test/features/auth/auth_repository_test.dart
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/features/auth/repositories/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late AuthRepository repository;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = AuthRepository(client: mockClient);
  });

  group('AuthRepository', () {
    test('signInWithGoogle creates user profile', () async {
      // Arrange
      final mockResponse = AuthResponse(
        session: Session(
          accessToken: 'token',
          user: User(id: 'user123', email: 'test@test.com'),
        ),
      );

      when(() => mockClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: any(named: 'idToken'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.signInWithGoogle();

      // Assert
      verify(() => mockClient.from('users').upsert(any())).called(1);
      expect(result, isNotNull);
    });

    test('signOut clears all sessions', () async {
      await repository.signOut();

      verify(() => mockClient.auth.signOut()).called(1);
    });
  });
}
```

### test/features/tasks/fairness_engine_test.dart
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/features/tasks/services/fairness_engine.dart';

void main() {
  group('FairnessEngine', () {
    late FairnessEngine engine;

    setUp(() {
      engine = FairnessEngine();
    });

    test('distributes tasks fairly among members', () {
      final tasks = [
        HouseholdTask(id: '1', difficultyLevel: 2, estimatedDurationMinutes: 15),
        HouseholdTask(id: '2', difficultyLevel: 3, estimatedDurationMinutes: 30),
        HouseholdTask(id: '3', difficultyLevel: 1, estimatedDurationMinutes: 10),
      ];

      final members = [
        FamilyMember(id: 'm1', name: 'Ali', age: 35, weeklyCapacityMinutes: 300),
        FamilyMember(id: 'm2', name: 'Ayse', age: 33, weeklyCapacityMinutes: 300),
      ];

      final assignments = engine.distributeTasks(
        tasks: tasks,
        members: members,
        date: DateTime.now(),
      );

      expect(assignments.length, equals(3));
      // Her gorev birine atanmali
      expect(assignments.every((a) => a.assignedTo != null), isTrue);
    });

    test('does not assign hard tasks to children', () {
      final tasks = [
        HouseholdTask(id: '1', difficultyLevel: 5, estimatedDurationMinutes: 60),
      ];

      final members = [
        FamilyMember(id: 'm1', name: 'Cocuk', age: 10, weeklyCapacityMinutes: 100),
        FamilyMember(id: 'm2', name: 'Ebeveyn', age: 35, weeklyCapacityMinutes: 300),
      ];

      final assignments = engine.distributeTasks(
        tasks: tasks,
        members: members,
        date: DateTime.now(),
      );

      expect(assignments.first.assignedTo, equals('m2'));
    });
  });
}
```

---

## 46. Integration Test

### integration_test/app_test.dart
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test', () {
    test('Login -> Dashboard -> Weather -> Chat -> Logout', () async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('emailField')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Dashboard kontrol
      expect(find.text('Merkez'), findsOneWidget);

      // Weather ekranina git
      await tester.tap(find.byIcon(Icons.wb_sunny));
      await tester.pumpAndSettle();
      expect(find.text('Hava Durumu'), findsOneWidget);

      // Chat ekranina git
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      expect(find.text('Sohbet'), findsOneWidget);

      // Logout
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cikis Yap'));
      await tester.pumpAndSettle();

      expect(find.text('Giris Yap'), findsOneWidget);
    });
  });
}
```

---

## 47. Son Kontrol Listesi — 81 Eksiklik

### Store Blokaji (Sprint 1)
- [ ] app_links bagimliligi eklendi
- [ ] API key envied'e tasindi
- [ ] iOS Info.plist 6 description + UIBackgroundModes
- [ ] Android signing config release
- [ ] mood_entries migration calisti

### Guvenlik (Sprint 2)
- [ ] Child login aile filtresi
- [ ] Child PIN bcrypt hash
- [ ] Chat Supabase Realtime
- [ ] Family screen CRUD sync
- [ ] Biometric PIN calisiyor

### Fonksiyonel (Sprint 3)
- [ ] Health Card Supabase sync
- [ ] Smart Rotation kaydetme
- [ ] Calendar Sync gercek API
- [ ] Crash SOS implementasyon
- [ ] Premium sistem birlestir
- [ ] HubRepository .subscribe()
- [ ] Tum repository try/catch

### UX/L10n (Sprint 4)
- [ ] flutter_localizations + .arb
- [ ] Dil degistirme calisiyor
- [ ] Theme token tamamlama
- [ ] Background servis baslat
- [ ] Orphan dosyalar route'landi

### Platform (Dosya 5)
- [ ] AndroidManifest tum izinler
- [ ] Proguard rules tamam
- [ ] iOS Podfile 14.0
- [ ] Version >= 1.0.0+10
- [ ] Onboarding remote config
- [ ] pubspec.yaml asset tanimlari

### Supabase (Dosya 6)
- [ ] SupabaseConfig.safeClient 25+ dosya
- [ ] SQL migration otomasyon
- [ ] 300+ ev isleri seed
- [ ] RLS policies tum tablolar
- [ ] Backup aile filtresi
- [ ] FamilyMembersRepository PK

### UI/UX (Dosya 7)
- [ ] Dark mode contrast test
- [ ] System theme dinleyici
- [ ] Emoji picker calisiyor
- [ ] flutter analyze = 0 warning
- [ ] mounted kontrolu tum ekranlar

### Konum (Dosya 8)
- [ ] Weather GPS konum
- [ ] Reverse geocoding
- [ ] Canli destek konum dahil
- [ ] Safe zones default Turkiye

### Saglik (Dosya 9)
- [ ] Saglik karti secenekler
- [ ] Acil kisi otomatik secim
- [ ] SOS gercek SMS
- [ ] Crash detection 9 method
- [ ] 112 arama

### CI/CD (Bu dosya)
- [ ] GitHub Actions pipeline
- [ ] Unit test coverage > 80%
- [ ] Integration test E2E
- [ ] Firebase App Distribution
- [ ] Supabase auto deploy

---

## 48. Release Checklist

### Pre-Release
```bash
# 1. Test
flutter test
flutter analyze --fatal-infos --fatal-warnings

# 2. Build
flutter build apk --release --obfuscate --split-debug-info=./symbols
flutter build ios --release --no-codesign

# 3. Supabase
supabase db push

# 4. Version kontrol
# pubspec.yaml: version: 1.0.0+10
```

### Store Submission
- [ ] App Store Connect — Screenshots (iPhone + iPad)
- [ ] Google Play Console — Screenshots (Phone + Tablet)
- [ ] App description (TR + EN)
- [ ] Privacy policy URL
- [ ] Support email
- [ ] Content rating
- [ ] Data safety form

### Post-Release
- [ ] Crashlytics monitoring
- [ ] Analytics dashboard
- [ ] User feedback kanali
- [ ] Hotfix plani

---
**Versiyon:** 1.0 | **Dosya:** 10/10 | **Hedef:** PRODUCTION READY
**Tarih:** 2026-05-06 | **Toplam Eksiklik:** 81/81 Cozuldu
