# 🏠 FamilyHub Wiki

> **FamilyHub** — Aile organizasyonu, iletişim ve güvenlik uygulaması.
> Flutter • Supabase • Firebase • AI-powered

---

## 🚀 Hızlı Başlangıç

| Platform | Komut |
|----------|-------|
| Android (Debug) | `flutter run` |
| Android (Release) | `flutter build apk --release` |
| iOS | `flutter build ios --release` |
| Web | `flutter build web --release` |

## 📚 Wiki Sayfaları

| Sayfa | Açıklama |
|-------|----------|
| [🏗️ Architecture](Architecture) | Katmanlı mimari, state management, klasör yapısı |
| [🔒 Security](Security) | Güvenlik özellikleri, RLS, secret yönetimi |
| [🤝 Contributing](Contributing) | Geliştirme kuralları, PR süreci |
| [📡 API](API) | Backend API dokümantasyonu |
| [🚀 Deployment](Deployment) | Build, release, CI/CD rehberi |

## 🏗️ Mimari Özeti

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                 │
│  Screens → Widgets → Riverpod Providers     │
├─────────────────────────────────────────────┤
│           Domain Layer                       │
│  Models → Use Cases → Repository Interfaces │
├─────────────────────────────────────────────┤
│           Data Layer                         │
│  Repositories → Services → Remote/Local     │
├─────────────────────────────────────────────┤
│           Core Layer                         │
│  Analytics → Error → Validation → DI        │
└─────────────────────────────────────────────┘
```

## 🔧 Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| **Framework** | Flutter 3.41+ |
| **State** | Riverpod 2.6 |
| **Routing** | GoRouter 14.x |
| **Backend** | Supabase (Auth + DB + Storage) |
| **Push** | Firebase Cloud Messaging |
| **Analytics** | Firebase Analytics + Mixpanel |
| **Crash** | Firebase Crashlytics + Sentry |
| **Payments** | Stripe + RevenueCat |
| **AI** | OpenAI + Anthropic + Gemini |

## 📁 Klasör Yapısı

```
lib/
├── components/      # Reusable UI widgets
├── core/           # Analytics, error, validation, DI
├── data/           # DTOs, mappers
├── domain/         # Models, use cases
├── l10n/           # Localization (ARB files)
├── presentation/   # Screens + Riverpod providers
├── repositories/   # Data access layer
└── services/       # Business logic services
```

## 🛡️ Güvenlik Özeti

- ✅ Compile-time secret obfuscation (`envied`)
- ✅ Secure local storage (Android Keystore / iOS Keychain)
- ✅ Row Level Security (RLS) policies
- ✅ Biometric authentication
- ✅ HTTPS-only API communication
- ✅ Certificate pinning

## 📞 İletişim

| Kanal | Bağlantı |
|-------|----------|
| GitHub Issues | [Issues](https://github.com/mcemkoca/familyhub/issues) |
| Security | [SECURITY.md](https://github.com/mcemkoca/familyhub/blob/main/SECURITY.md) |
| Changelog | [CHANGELOG.md](https://github.com/mcemkoca/familyhub/blob/main/CHANGELOG.md) |

---

*Bu wiki, proje geliştikçe güncellenmektedir. Son güncelleme: 2026-05-08*
