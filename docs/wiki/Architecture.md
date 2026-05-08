# 🏗️ Architecture

## Katmanlı Mimari

FamilyHub, **Clean Architecture** prensiplerine dayalı katmanlı bir mimari kullanır.

```
┌──────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                      │
│  • Screens (Stateful/Stateless widgets)                 │
│  • Reusable Components                                  │
│  • Riverpod Providers (State Management)                │
├──────────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                            │
│  • Entity Models (immutable, freezed)                   │
│  • Use Cases (business logic)                           │
│  • Repository Interfaces                                │
├──────────────────────────────────────────────────────────┤
│  DATA LAYER                                              │
│  • Repository Implementations                           │
│  • Data Transfer Objects (DTOs)                         │
│  • Data Mappers                                         │
│  • Remote (Supabase, Firebase) & Local (Hive)           │
├──────────────────────────────────────────────────────────┤
│  CORE LAYER                                              │
│  • Analytics Service                                    │
│  • Error Handler                                        │
│  • Validation Utilities                                 │
│  • Dependency Injection                                 │
│  • Logging & Crash Reporting                            │
└──────────────────────────────────────────────────────────┘
```

## Bağımlılık Kuralı

**İç katmanlar dış katmanları bilmez.**

```dart
// ✅ DO: Domain layer knows nothing about Flutter
class User {
  final String id;
  final String email;
  // No BuildContext, no Widget, no import 'package:flutter'
}

// ❌ DON'T: Domain layer depending on presentation
dependency cycle detected!
```

## State Management: Riverpod

```dart
// Provider
final userProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// Consumer
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    return userAsync.when(
      data: (user) => ProfileView(user: user),
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => ErrorStateWidget(message: err.toString()),
    );
  }
}
```

## Routing: GoRouter

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/family/:id',
      builder: (_, state) => FamilyDetailScreen(id: state.pathParameters['id']!),
    ),
  ],
  redirect: (context, state) => authGuard(ref, state),
);
```

## Repository Pattern

```dart
// Interface (Domain Layer)
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> updateUser(User user);
}

// Implementation (Data Layer)
class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _client;
  SupabaseUserRepository(this._client);

  @override
  Future<User> getUser(String id) async {
    final response = await _client.from('profiles').select().eq('id', id).single();
    return UserMapper.fromJson(response);
  }
}
```

## Error Handling

```dart
// BaseRepository handles common errors
class BaseRepository {
  Future<T> execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw RepositoryError.fromSupabase(e);
    } on SocketException {
      throw const RepositoryError.network();
    } catch (e, stack) {
      ErrorHandler.report(e, stack);
      throw RepositoryError.unknown(e.toString());
    }
  }
}
```

## Dependency Injection

```dart
// Provider definitions
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => SupabaseUserRepository(ref.watch(supabaseClientProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(userRepositoryProvider)),
);
```

## Testing Strategy

| Test Tipi | Kapsam | Araçlar |
|-----------|--------|---------|
| Unit Test | Services, Use Cases, Mappers | `flutter_test`, `mockito` |
| Widget Test | UI Components, Screens | `flutter_test`, `golden_toolkit` |
| Integration Test | E2E Flows | `integration_test` |

---

*Detaylı mimari kararları için [ARCHITECTURE.md](https://github.com/mcemkoca/familyhub/blob/main/ARCHITECTURE.md) dosyasına bakın.*
