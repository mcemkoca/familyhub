# FamilyHub — Technical Audit Report

**Date:** 2026-04-27
**Auditor:** Principal Engineer Review
**Scope:** Full-stack Flutter application (`familyhub/`)

---

## 1. Executive Summary

### What This System Actually Does
FamilyHub is a **single-device family management mobile app** built in Flutter. It attempts to cover tasks, calendar, budget, chat, streak tracking, safety/location, health cards, memories, and weather — all in one UI. However, beneath the polished Material 3 interface, the majority of features rely on **hardcoded mock data** or **in-memory state** with no backend, no real authentication, and minimal local persistence.

### Current Maturity Level: **UI Prototype / Demo**
This is not an MVP. It is a **visual prototype** with real-looking screens that simulate a working product. Only 4 out of 15+ features have real data persistence. There is no cloud sync, no user accounts, no backend API, and no multi-device capability.

### Key Strengths
- Clean Material 3 UI with consistent design tokens (`AppColors`, `AppSpacing`)
- Real Open-Meteo weather integration with GPS + geocoding + OSM map picker
- Local Hive persistence for Tasks, Budget transactions, Chat, and Streaks
- `flutter_local_notifications` with exact alarm scheduling for calendar reminders
- Turkish localization (`intl`, `tr_TR`) properly wired
- GoRouter navigation with 34 routes

### Critical Weaknesses
- **No real authentication** — login is a `Future.delayed` + boolean flag
- **No backend** — 100% local; data is trapped on a single device
- **Most features are mock** — Calendar, Shopping, Family, Mood, Memories, Activities are all in-memory with hardcoded seed data
- **Fake encryption** — Health card "encryption" is a trivial XOR cipher with a predictable key
- **PII hardcoded in source** — Default health card contains real-looking names, phone numbers, and medical data
- **No CI/CD, no tests, no Docker, no build automation**

---

## 2. System Overview

### Architecture Style
**Monolithic client-side app** — single Flutter codebase with no backend service layer. All data lives locally on the device. No microservices, no BFF, no API gateway.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart 3.11) |
| State Management | Riverpod 2.6.1 (basic StateProvider/FutureProvider) |
| Navigation | GoRouter 14.8.1 |
| Local DB | Hive 2.2.3 (NoSQL, JSON-in-String boxes) |
| Secure Storage | `flutter_secure_storage` 8.1.0 (used with broken XOR cipher) |
| HTTP | `http` 1.3.0 (only for Open-Meteo) |
| Maps | `flutter_map` 8.0.0 + OpenStreetMap tiles |
| Geolocation | `geolocator` 13.0.4 + `geocoding` 3.0.0 |
| Notifications | `flutter_local_notifications` 19.0.0 |
| Charts | `fl_chart` 0.71.0 |
| Calendar | `table_calendar` 3.2.0 |
| UI | Material 3, `google_fonts` (Inter) |

### Core Modules Breakdown

| Module | Description | Data Layer |
|--------|-------------|------------|
| Auth | Splash, onboarding, login, register, biometric | ❌ Mock boolean flag |
| Hub Dashboard | Family avatars, 4 feature cards, weather badge, activity feed | ❌ Mock cards + mock activities |
| Tasks | CRUD, status toggle, filter, Slidable actions | ✅ Hive persisted |
| Calendar | Monthly view, event CRUD, local notifications | ❌ In-memory only (mock seed) |
| Shopping List | Item CRUD, category chips | ❌ In-memory only (mock seed) |
| Budget | Transaction CRUD, dynamic pie chart, category totals | ✅ Hive persisted |
| Family | Member list, roles, avatars | ❌ In-memory only (mock seed) |
| Chat | Empty start, send/reply/reactions/pin/delete | ✅ Hive persisted |
| Mood Tracker | Emoji picker, history list | ❌ In-memory only (mock seed) |
| Streak | Daily entry history, consecutive streak calc | ✅ Hive persisted |
| Safety / SOS | Emergency call (112), GPS location sharing | ⚠️ Real GPS, mock family status |
| Health Card | QR code, medications, allergies, emergency contacts | ⚠️ Secure storage + broken XOR |
| Weather | Open-Meteo API, GPS, OSM map picker, 7-day forecast | ✅ Real API + Hive settings |
| Memories / Album | Photo grid, memory creation | ❌ UI placeholders only |
| Settings | 17 sub-screens (appearance, weather, backup, etc.) | ⚠️ Partial persistence |

---

## 3. Feature Inventory

| Feature | Status | Demo? | Missing Parts |
|---------|--------|-------|---------------|
| Authentication | **Broken / Mock** | Yes | No backend, no tokens, no session |
| Onboarding | **Working** | No | Auto-generated gradient PNGs (not user photos) |
| Tasks | **Working** | No | Full Hive CRUD, edit modal, Slidable actions |
| Calendar | **Partial** | Yes (seed) | Events are in-memory; lost on restart |
| Shopping List | **Partial** | Yes (seed) | Items in-memory; lost on restart |
| Budget | **Working** | No | Real transactions, dynamic pie chart, Hive persisted |
| Family Members | **Partial** | Yes (seed) | Members in-memory; lost on restart |
| Chat | **Working** | No | Empty start, full CRUD, reactions, pin, Hive persisted |
| Mood Tracker | **Partial** | Yes (seed) | Entries in-memory; lost on restart |
| Streak | **Working** | No | Real consecutive calc, weekly circles, Hive persisted |
| Safety / SOS | **Partial** | Yes (status) | 112 call works, GPS works, family status is mock |
| Health Card | **Partial** | Yes (defaults) | XOR encryption is fake; default PII hardcoded |
| Weather | **Working** | No | Open-Meteo, GPS, OSM map, geocoding, 7-day forecast |
| Notifications | **Working** | No | Exact alarm scheduling, boot receiver |
| Memories / Album | **Mock** | Yes | No real photo storage; UI placeholders |
| Activities Feed | **Mock** | Yes | Hardcoded 4 items |
| Appearance Settings | **Working** | No | Theme mode, accent color, font scale — Hive persisted |
| Google Drive Backup | **Mock** | Yes | Fake stats, simulated backup UI |
| Premium Screen | **Mock** | Yes | UI only; no payment integration |

---

## 4. What Actually Works (Reality Check)

### Verified End-to-End Flows

1. **Task Lifecycle**
   - Add task → Bottom sheet → Title/due date/assignee/priority → Save → Hive persists
   - Edit task → Slidable "Edit" → Pre-filled modal → Update → Hive persists
   - Toggle complete → `completedAt` timestamp → Hive persists
   - Delete task → Slidable "Delete" → Hive persists

2. **Budget Lifecycle**
   - Add transaction → Bottom sheet → Amount/category/type → Save → Hive persists
   - Pie chart dynamically recalculates from real transaction totals
   - Budget header shows real spent amount
   - Delete transaction → Hive persists

3. **Chat Lifecycle**
   - Starts empty (no mock seed)
   - Send message → Appends to provider → Hive persists
   - Reply, reactions, pin, delete → All mutate provider → Hive persists

4. **Streak Lifecycle**
   - Add today's entry → `StreakEntry` with date/note → Hive persists
   - Current streak calculated from consecutive calendar days
   - Best streak tracked dynamically
   - Weekly circles built from real entry history

5. **Weather Flow**
   - GPS permission → `Geolocator.getCurrentPosition` → Open-Meteo API
   - Or OSM map picker → Pin placement → `geocoding` reverse lookup → Address display
   - 7-day forecast rendered from real API response
   - Settings (city, °C/°F, location toggle) persisted in Hive

6. **Calendar Notifications**
   - Create event with reminder time → `zonedSchedule` exact alarm
   - Notification fires at correct time via `flutter_local_notifications`
   - Android permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`

7. **Emergency Call**
   - SOS button → `url_launcher` dials 112
   - Cancel broadcasts to stream
   - Location permission handled for Safety module

---

## 5. Mocked / Incomplete / Fake Logic

### Hardcoded Data
- `mock_data.dart` (292 lines) seeds 10 different entity lists
- Family name: `"Yılmaz Ailesi"` — hardcoded in Hub, Family, Settings screens
- Family ID: `'f1'`, User ID: `'m1'` — hardcoded across Chat, Tasks, Budget, Family
- Currency: `EUR` / `€` — hardcoded in Budget
- App version: `"v2.1.0 (Build 2100)"` — hardcoded in Settings

### Placeholder APIs
- **Google Drive Backup Screen** — Shows fake progress bars, simulated stats, no real Google Drive API
- **Premium Screen** — UI only; no Stripe, no in-app purchase, no payment gateway
- **Health Card** — `health_card_service.dart` contains `_defaultData()` with:
  - Blood type: `A+`
  - Allergies: `['Polen', 'Fıstık']`
  - Emergency contact: `Hilal Yılmaz`, phone `+32 4XX XX XX`
  - Doctor: `Dr. Ahmet Yılmaz`, `Saint Luc Hospital`

### UI Without Backend
- **Memories / Album / Growth** — Screens exist but have no data storage
- **Activities Feed** — Always shows the same 4 hardcoded items
- **Mood Tracker** — Emoji picker works but data is lost on restart

### Simulated Flows
- **Login** — `Future.delayed(Duration(seconds: 1))` then `authUserProvider = true`
- **Register** — Comment literally says `// Mock: accept any non-empty input`
- **Biometric** — Real `local_auth` plugin, but success just sets local boolean
- **Health Card Encryption** — XOR cipher with key derived from `DateTime.now().millisecondsSinceEpoch`:
  ```dart
  // Simple XOR encryption for demo purposes
  encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
  ```

### "Yakında..." (Coming Soon) Placeholders
- Budget: "Doküman ekleme yakında geliyor"
- Safety: "Fener özelliği yakında geliyor" (`torch_light` imported but unused)
- Chat: "Bu özellik yakında geliyor" (voice call)
- Settings: 4x `SnackBar(content: Text('Yakında...'))` for Permissions, Screen Time, Security, App Rating

---

## 6. Data Requirements for Full Production

### Missing Data Models / Schemas
| Entity | Current | Production Need |
|--------|---------|-----------------|
| User | None (mock boolean) | Full user auth schema (email, password hash, MFA, session tokens) |
| Family Group | Hardcoded `'f1'` | Family entity with admin, members, invite codes, roles |
| Cloud Sync | None | Backend API + sync protocol (delta sync, conflict resolution) |
| Calendar Events | In-memory | Persisted schema with recurrence, timezones, reminders |
| Shopping Items | In-memory | Persisted schema with categories, quantities, check status |
| Family Members | In-memory | Persisted schema with avatars, roles, online status |
| Mood Entries | In-memory | Persisted schema with timestamp, note, trend analysis |
| Memories / Photos | None | File storage (S3/Cloudinary) + metadata schema |
| Activities Feed | Hardcoded | Event-sourced activity log with aggregation |

### External Integrations Needed
| Integration | Purpose | Current Status |
|-------------|---------|----------------|
| Backend API (Firebase/Supabase/Custom) | User auth, cloud sync, real-time chat | ❌ Missing |
| Firebase Cloud Messaging | Push notifications | ❌ Only local notifications exist |
| Google Drive API | Backup/restore | ❌ Mock UI only |
| Payment Gateway (Stripe/RevenueCat) | Premium subscriptions | ❌ Missing |
| Image CDN (Cloudinary/S3) | Photo storage | ❌ Missing |
| Crashlytics / Sentry | Error tracking | ❌ Missing |
| Analytics (Firebase/Amplitude) | User behavior | ❌ Missing |

### Data Consistency Risks
- **Hive JSON-in-String approach** is fragile — schema changes break deserialization with no migration strategy
- **No versioning** on persisted data — adding a new field to `Task` will crash on load
- **Full list replacement** on every mutation — O(n²) write amplification for large lists
- **No sync protocol** — if user installs on second device, all data is empty

---

## 7. Code Quality Analysis

### Structure: **C-Grade (Messy but navigable)**
- Standard Flutter folder structure (`screens/`, `widgets/`, `services/`, `domain/`)
- 34 routes in a single `routes.dart` file — manageable but will grow unwieldy
- `services/` layer mixes concerns: persistence (Hive), API (weather), security (health card), platform (notifications)
- No `data/` or `repository/` layer — screens talk directly to `HiveService`

### Modularity: **C-Grade**
- Screens are large (500–800 lines each) with business logic embedded in `State` classes
- Widgets are reasonably extracted (~25 reusable widgets)
- No use-case or domain-service abstraction
- All providers in a single 82-line file

### Naming Conventions: **B-Grade**
- Generally consistent Hungarian-ish Flutter naming
- Some confusion: `LocationService` vs `weather_service.dart`'s `fetchWeatherForLocation`
- Turkish strings mixed with English code — acceptable for a TR-targeted app

### Reusability: **C-Grade**
- Bottom sheet pattern copy-pasted 6+ times with identical padding/shape/button styling
- Dark-mode conditional (`isDark ? AppColors.darkCard : Colors.white`) repeated in every screen
- No shared `AppCard`, `AppBottomSheet`, or `AppSection` widgets

### Dead Code / Duplication
- `torch_light` imported in `pubspec.yaml` and `safety_screen.dart` but never used
- `lottie` and `shimmer` dependencies imported but barely used
- Multiple `Yakında...` placeholder handlers that will never be implemented
- Zero `TODO` or `FIXME` comments found in entire codebase

---

## 8. Architecture Problems

### Tight Coupling
```dart
// screens directly call HiveService
ref.read(tasksProvider.notifier).state = updatedTasks;
HiveService.saveTasks(updatedTasks);
```
- No repository pattern — if Hive is replaced with SQLite or a backend, every screen must change
- No dependency injection — `WeatherService`, `EmergencyService`, `LocationService` are all static classes

### Missing Layers
| Layer | Status | Impact |
|-------|--------|--------|
| Repository Layer | ❌ Missing | Business logic mixed with UI |
| Use Case / Interactor | ❌ Missing | Cannot unit test business logic |
| DTO / Model Mapper | ❌ Missing | JSON serialization scattered across `HiveService` |
| API Client Abstraction | ❌ Missing | Only one API exists, but no abstraction for future |
| Error Boundary / Retry | ❌ Missing | API failures show generic error with no retry |

### Bad State Management
- All providers in one file — no feature-based modularization
- No `StateNotifier` or `AsyncNotifier` — complex async logic (weather, location) is not properly managed
- `weatherProvider` reads from `Hive.box('settings')` directly inside the provider body — side effect in provider creation
- `ref.invalidate(weatherProvider)` is used as a blunt force refresh instead of reactive updates

### Scalability Risks
- **Hive full-list replacement** — saving 1000 tasks will rewrite entire JSON string every time
- **No pagination** — Chat loads all messages into memory; will crash with long histories
- **No image caching strategy** — `ImagePicker` picks photos but no thumbnail or compression
- **OSM tile loading** — No tile cache configuration in `flutter_map`

---

## 9. Security Analysis

### Authentication: **F-Grade**
- No password hashing (plaintext `123456` in login screen)
- No JWT, no refresh tokens, no session expiry
- `authUserProvider` is a simple boolean — trivial to bypass
- Biometric auth has no server-side validation

### Authorization: **F-Grade**
- No role-based access control beyond UI labels
- `MemberRole` enum exists but is not enforced anywhere
- No API to validate permissions

### Data Exposure Risks
- **Health card PII hardcoded in source** — names, phone numbers, hospital names in `health_card_service.dart`
- **XOR encryption is trivially breakable** — key is predictable timestamp string
- **Hive data is unencrypted at rest** — device root access exposes all task/chat/budget data
- **No certificate pinning** — MITM possible on Open-Meteo API calls

### Input Sanitization
- No input validation beyond `isNotEmpty` checks
- No SQL injection risk (no SQL), but XSS possible if chat messages are rendered as HTML
- No rate limiting on any operation

### AndroidManifest Permissions
- Reasonable set: location, notifications, internet, foreground service
- No over-permissioning (no contacts, SMS, camera without cause)

---

## 10. Performance Risks

### Bottlenecks
- **Hive full-list serialization** — `jsonEncode` on entire task/chat list on every mutation
- **Chat message list** — all messages loaded into `ListView`; no pagination, no virtual scrolling optimization
- **Weather fetch** — `FutureProvider` rebuilds on every settings change; no caching

### Inefficient Queries
- No queries exist — everything is in-memory list traversal
- `budget_screen.dart` iterates all transactions on every build to compute pie chart sections
- `chat_screen.dart` scans all messages to find pinned message on every build

### UI Performance Issues
- `CustomScrollView` with `SliverList` is used correctly
- No `RepaintBoundary` usage — complex screens may repaint unnecessarily
- `shimmer` dependency present but not actively used for loading states

### Network Inefficiencies
- Weather API called with no caching — every app open hits Open-Meteo
- No HTTP client configuration (no connection pooling, no retry logic)
- OSM map tiles have no local cache configured

---

## 11. DevOps & Deployment

### CI/CD: **F-Grade (None)**
- No `.github/workflows/`
- No `.gitlab-ci.yml`
- No `Dockerfile`
- No Fastlane
- No build scripts

### Environment Configs
- No `.env` file or environment-specific config
- No flavor configuration (dev/staging/prod)
- API endpoints hardcoded in service files

### Build Process
- Manual `flutter build apk --release`
- OneDrive locks `.dart_tool` — workaround: `robocopy` to `C:\temp\familyhub_build\`
- Gradle memory set to `-Xmx4G` to prevent Windows thread creation failures
- APK size: ~61.4 MB (reasonable for Flutter + dependencies)

### Production Readiness
- **Not deployable** to app stores without:
  - Real backend + auth
  - Privacy policy compliance (GDPR/KVKK for health data)
  - Data encryption at rest
  - Automated build pipeline

---

## 12. UX / Product Issues

### Inconsistent Flows
- Login has hardcoded credentials pre-filled — looks like a demo, not a real app
- Onboarding uses auto-generated gradient PNGs instead of real screenshots
- Chat starts empty (good) but other features start with fake data (confusing)

### Missing States
- No empty state for Calendar when no events exist (always shows mock seed)
- No empty state for Shopping List
- No loading state for weather — just generic `CircularProgressIndicator`
- No offline state — app crashes or shows generic error when no internet

### Confusing UX Decisions
- **"Yakında..." placeholders** scattered across settings — makes app feel unfinished
- **Premium screen** exists with no payment flow — user confusion risk
- **Google Drive Backup** is fake UI — user may think data is backed up when it's not
- Health card shows hardcoded PII on first launch — privacy violation impression

---

## 13. Missing Critical Features

| Feature | Why It Matters | Current State |
|---------|---------------|---------------|
| **Real Authentication** | User identity, data isolation, security | ❌ Mock boolean |
| **Cloud Sync** | Multi-device, data backup, family sharing | ❌ 100% local |
| **Backend API** | Real user accounts, family groups, real-time | ❌ None |
| **Error Logging** | Production debugging, crash analysis | ❌ No Sentry/Firebase Crashlytics |
| **Analytics** | User behavior, feature usage, retention | ❌ None |
| **Offline Support** | Graceful degradation, sync queue | ❌ No offline detection |
| **Data Migration** | Schema evolution without data loss | ❌ No versioning |
| **Input Validation** | Prevent bad data, security | ❌ Minimal |
| **Rate Limiting** | Prevent abuse | ❌ None |
| **Unit Tests** | Code correctness, regression prevention | ❌ `test/` folder empty |
| **Integration Tests** | End-to-end flow verification | ❌ None |
| **Accessibility** | Screen readers, large fonts, contrast | ❌ Not evaluated |

---

## 14. Technical Debt

### Shortcuts Taken
1. **Mock auth** instead of real authentication — will require complete rewrite
2. **XOR encryption** on health data — must be replaced with AES or removed
3. **JSON-in-String Hive approach** — no type safety, no migration, brittle
4. **Static service classes** — no testability, no mocking
5. **Hardcoded PII** in source — must be scrubbed before any public release
6. **Full-list replacement** persistence pattern — O(n²) writes, won't scale

### Risky Implementations
- `flutter_local_notifications` with `SCHEDULE_EXACT_ALARM` — requires Android 12+ special permission handling
- `geocoding` reverse lookup on main thread — can block UI for slow responses
- `url_launcher` for emergency calls — no verification that dialer actually opened
- `flutter_secure_storage` with XOR — gives false sense of security

### Future Problems
- Adding any new field to a Hive-persisted entity will break existing user data
- No sync protocol means impossible to add multi-device support later without data migration
- 34 routes in one file will become unmaintainable
- No backend means impossible to add family invite codes, real-time chat, or push notifications

---

## 15. Roadmap (Senior-Level)

### Short-Term (1–2 weeks)

1. **Scrub all PII from source**
   - Remove hardcoded names, phone numbers, hospital names from `health_card_service.dart`
   - Replace with empty defaults or `"Bilinmiyor"` placeholders

2. **Fix broken encryption**
   - Remove XOR cipher entirely OR implement real AES encryption
   - Never ship health data with fake security

3. **Remove all mock seed data**
   - Delete `mock_data.dart` imports from `app_providers.dart`
   - Initialize all non-persisted providers with `[]` instead of mock lists
   - Add proper empty states for Calendar, Shopping, Family, Mood

4. **Add missing Hive persistence**
   - Calendar events → Hive
   - Shopping items → Hive
   - Family members → Hive
   - Mood entries → Hive

5. **Stabilize build**
   - Fix all compile errors (import issues, type mismatches)
   - Ensure `flutter build apk --release` passes consistently

### Mid-Term (1–2 months)

1. **Implement real authentication**
   - Integrate Firebase Auth or Supabase Auth
   - Email/password + Google Sign-In
   - JWT token storage in secure storage
   - Session management with refresh tokens

2. **Build backend API**
   - Firebase Firestore or Supabase Realtime
   - User profiles, family groups, invite codes
   - Cloud sync for all entities
   - Real-time chat with WebSockets

3. **Refactor data layer**
   - Introduce Repository pattern (`TaskRepository`, `ChatRepository`, etc.)
   - Abstract Hive behind Repository interfaces
   - Add DTOs and model mappers

4. **Add production tooling**
   - Firebase Crashlytics for error tracking
   - Firebase Analytics for user behavior
   - CI/CD pipeline (GitHub Actions + Codemagic/Fastlane)

5. **Implement real backup**
   - Replace mock Google Drive screen with actual Google Sign-In + Drive API
   - Or use backend's built-in backup

### Long-Term (3–6 months)

1. **Multi-device sync architecture**
   - Delta sync protocol
   - Conflict resolution (last-write-wins or CRDT)
   - Offline-first with sync queue

2. **Scalability improvements**
   - Paginated lists for Chat, Activities, Calendar
   - Image compression and CDN integration
   - Hive → SQLite or Isar migration for large datasets

3. **Security hardening**
   - Certificate pinning for API calls
   - Data encryption at rest (SQLCipher or similar)
   - OWASP Mobile Top 10 audit
   - KVKK/GDPR compliance for health data

4. **Feature completion**
   - Real payment integration (RevenueCat for subscriptions)
   - Push notifications via FCM
   - Deep linking
   - Widgets / home screen shortcuts

5. **Testing strategy**
   - Unit tests for Repository and Service layers
   - Widget tests for critical screens
   - Integration tests for end-to-end flows
   - Golden tests for UI regression

---

## 16. Final Verdict

### Can This Scale?
**No.** The current architecture is a single-device prototype. There is no backend, no real auth, no sync, and no data layer abstraction. Scaling to even 100 real users would require a complete rewrite of the data and auth layers.

### Can This Be Shipped?
**Not to production.** It could be released as a **closed demo** or **internal prototype** for stakeholder review, but:
- App stores will reject it due to non-functional features (Premium, Google Drive Backup)
- Health data handling violates medical data privacy regulations
- Fake auth is a security liability
- Data loss on restart for 60% of features is unacceptable for users

### What Is the Real Risk Level?
**HIGH** for production, **LOW** for demo/POC.

| Risk | Severity | Mitigation |
|------|----------|------------|
| Fake auth | Critical | Implement real auth before any release |
| Fake health encryption | Critical | Remove XOR, implement AES or backend encryption |
| PII in source | Critical | Scrub all hardcoded personal data |
| Data loss on restart | High | Add Hive persistence for all entities |
| No backend / cloud sync | High | Design and implement backend API |
| No CI/CD | Medium | Set up GitHub Actions + Codemagic |
| No tests | Medium | Add unit/widget tests |
| Performance (full-list writes) | Medium | Implement pagination, optimize persistence |

### Bottom Line
FamilyHub is a **well-designed UI prototype** with a polished Material 3 interface and a few genuinely working local features (Tasks, Budget, Chat, Streak, Weather). However, it is fundamentally a **demo application** masquerading as a product. The gap between "what looks working" and "what is actually working" is enormous. **Do not ship this to users without first implementing real authentication, a backend, and fixing the security vulnerabilities.**
