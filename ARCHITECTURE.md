# FamilyHub Architecture

## Overview
FamilyHub is a Flutter application built with Clean Architecture principles, using Riverpod for state management and Supabase as the primary backend.

## Layers

### Presentation Layer
- **Screens**: `lib/presentation/screens/`
- **Widgets**: `lib/presentation/widgets/`
- **Providers**: `lib/presentation/providers/`

### Domain Layer
- **Models**: `lib/domain/models/`
- **Entities**: `lib/domain/entities.dart`

### Data Layer
- **Repositories**: `lib/repositories/`
- **Services**: `lib/services/`

### Core Layer
- **Config**: `lib/core/config/`
- **Supabase Client**: `lib/core/supabase_client.dart`
- **Theme**: `lib/config/theme.dart`
- **Routing**: `lib/config/routes.dart`

## Dependency Flow
```
UI (Screens/Widgets)
  ↓
Providers (Riverpod)
  ↓
Repositories (Data access abstraction)
  ↓
Services (Business logic, external APIs)
  ↓
Supabase / Firebase / Local Storage
```

## Key Decisions
- **Supabase** is the single source of truth for user data.
- **Firebase** is used only for push notifications (FCM), analytics, and crashlytics.
- **Hive** and **FlutterSecureStorage** are used for local caching and sensitive data.
- **Google Sign-In** feeds into Supabase Auth via `signInWithIdToken`.

## Security
- API keys are obfuscated using `envied` with `--obfuscate` flag.
- Supabase RLS policies enforce row-level access control.
- `SupabaseConfig.safeClient` provides null-safe client access with session validation.
