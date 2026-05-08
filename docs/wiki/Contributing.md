# 🤝 Contributing Guide

Teşekkürler! FamilyHub'a katkıda bulunmak istediğiniz için.

## 🚀 Başlangıç

### Gereksinimler

| Araç | Minimum Versiyon |
|------|-----------------|
| Flutter | 3.41.1 |
| Dart | 3.11.0 |
| Android SDK | 36.1.0 |
| JDK | 17 |
| Gradle | 8.13 |

### Kurulum

```bash
# Repoyu klonla
git clone https://github.com/mcemkoca/familyhub.git
cd familyhub

# Bağımlılıkları yükle
flutter pub get

# Code generation (env.g.dart, freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Çalıştır
flutter run
```

## 🌿 Branch Stratejisi

```
main          → Production-ready kod
  │
  ├── develop → Aktif geliştirme
  │     │
  │     ├── feature/auth-biometric
  │     ├── feature/dark-mode
  │     └── bugfix/rls-policy
  │
  └── hotfix/security-patch
```

## 📝 Commit Mesajları

[Conventional Commits](https://www.conventionalcommits.org/) formatı kullanıyoruz.

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Türler

| Tür | Kullanım |
|-----|----------|
| `feat` | Yeni özellik |
| `fix` | Bug düzeltmesi |
| `docs` | Dokümantasyon |
| `style` | Kod formatı (boşluk, noktalı virgül) |
| `refactor` | Kod yeniden yapılandırma |
| `test` | Test ekleme/güncelleme |
| `chore` | Build, CI, bağımlılık güncellemeleri |
| `perf` | Performans iyileştirmesi |
| `security` | Güvenlik düzeltmesi |

### Örnekler

```
feat(auth): add biometric login support

- Implement local_auth plugin
- Add BiometricAuthService
- Update login screen with fingerprint button

Closes #123
```

```
security(rls): restrict profiles table access

- Replace using(true) with auth.uid() = id
- Add family member visibility policy

BREAKING CHANGE: profiles are no longer public
```

## 🔍 Pull Request Süreci

1. **Branch oluştur**: `git checkout -b feature/xyz`
2. **Kod yaz**: Testlerle birlikte
3. **Lint kontrolü**: `flutter analyze`
4. **Test çalıştır**: `flutter test`
5. **Commit**: Conventional Commits formatında
6. **Push**: `git push origin feature/xyz`
7. **PR aç**: Template'i doldur
8. **Review**: En az 1 approval gerekli
9. **Merge**: Squash merge (main/develop'a)

### PR Checklist

- [ ] Kod `flutter analyze` ile temiz
- [ ] Tüm testler geçiyor
- [ ] Yeni özellik için test yazıldı
- [ ] Dokümantasyon güncellendi
- [ ] CHANGELOG.md güncellendi
- [ ] `pubspec.yaml` version güncel
- [ ] Security kontrolü yapıldı (hardcoded secret yok)
- [ ] RLS policy kontrolü yapıldı (yeni tablo varsa)

## 🧪 Test Yazma

### Unit Test

```dart
// test/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    test('signIn returns User on success', () async {
      final mockRepo = MockAuthRepository();
      when(mockRepo.signIn(any, any)).thenAnswer((_) async => testUser);
      
      final service = AuthService(mockRepo);
      final result = await service.signIn('test@example.com', 'password');
      
      expect(result, equals(testUser));
    });
  });
}
```

### Widget Test

```dart
// test/widgets/login_form_test.dart
void main() {
  testWidgets('LoginForm validates email', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    
    await tester.enterText(find.byType(TextField).first, 'invalid-email');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    expect(find.text('Geçerli bir e-posta girin'), findsOneWidget);
  });
}
```

## 🎨 Kod Stili

### Dart Format Kuralları

- Line length: **100 karakter**
- Trailing comma: **her liste/map sonunda**
- Import sırası: Dart → Flutter → Third-party → Local (alfabetik)

### Naming Conventions

| Tip | Convention | Örnek |
|-----|-----------|-------|
| Classes | PascalCase | `UserRepository` |
| Files | snake_case | `user_repository.dart` |
| Functions/Variables | camelCase | `getUserById` |
| Constants | camelCase | `defaultTimeout` |
| Enums | PascalCase | `AuthState` |
| Private | önden `_` | `_privateField` |

### Widget Yapısı

```dart
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        data: (user) => _ProfileContent(user: user),
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => ErrorStateWidget(message: err.toString()),
      ),
    );
  }
}
```

## 🐛 Bug Raporlama

[GitHub Issues](https://github.com/mcemkoca/familyhub/issues) kullanın.

### Şablon

```markdown
**Açıklama:** Kısa özeti buraya yaz

**Adımlar:**
1. Adım 1
2. Adım 2
3. Adım 3

**Beklenen:** Ne olması gerekiyor
**Gerçekleşen:** Ne oldu
**Ekran Görüntüsü:** Varsa ekle
**Ortam:** Flutter 3.41.1, Android 14, Pixel 7
```

## 📞 İletişim

- **Discord**: [Katıl](https://discord.gg/familyhub) *(varsa)*
- **GitHub Discussions**: [Aç](https://github.com/mcemkoca/familyhub/discussions)
- **Email**: `dev@mcemkoca.dev`

---

*Katkınız için teşekkürler! ❤️*
