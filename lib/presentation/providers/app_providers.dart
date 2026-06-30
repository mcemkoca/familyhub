import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants.dart';
import '../../domain/entities.dart';
import '../../repositories/hub_repository.dart';
import '../../repositories/shopping_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/family_members_repository.dart';
import '../../services/auth_service.dart';
import '../../services/weather_service.dart';
import '../../services/location_weather_service.dart';
import '../../services/hive_service.dart';
import '../../repositories/mood_repository.dart';
import '../../domain/models/hub_state.dart';

// Re-export auth providers from auth_service.dart
export '../../services/auth_service.dart'
    show authStateProvider, authUserProvider, currentUserProvider;

// Re-export child auth providers
export '../../services/child_auth_service.dart' show ChildAuthService;

// ── Auth (exported from auth_service.dart) ──
// authStateProvider, authUserProvider, currentUserProvider

final localeProvider = StateProvider<Locale>((ref) {
  final lang = HiveService.getSetting('language') ?? 'Türkçe';
  switch (lang) {
    case 'English':
      return const Locale('en', 'US');
    case 'Deutsch':
      return const Locale('de', 'DE');
    case 'Nederlands':
      return const Locale('nl', 'NL');
    case 'Türkçe':
    default:
      return const Locale('tr', 'TR');
  }
});

final familyIdProvider = FutureProvider<String?>((ref) async {
  final userId = AuthService.currentUserId;
  if (userId == null) return null;

  // 1. Try profiles first (fastest)
  try {
    final profile = await SupabaseConfig.safeClient
        ?.from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    final familyId = profile?['family_id'] as String?;
    if (familyId != null && familyId.isNotEmpty) return familyId;
  } catch (e) {
    debugPrint('familyIdProvider: profiles query error: $e');
  }

  // 2. Fallback to family_members (useful when profiles RLS fails)
  try {
    final fm = await SupabaseConfig.safeClient
        ?.from('family_members')
        .select('family_id')
        .eq('user_id', userId)
        .maybeSingle();
    final familyId = fm?['family_id'] as String?;
    if (familyId != null && familyId.isNotEmpty) return familyId;
  } catch (e) {
    debugPrint('familyIdProvider: family_members query error: $e');
  }

  return null;
});

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

// ── Hub (Real Data) ──

final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) {
    return const TodaySummary(
      eventCount: 0,
      taskCount: 0,
      unreadMessages: 0,
      onlineMembers: 0,
      totalMembers: 0,
    );
  }
  return HubRepository().getTodaySummary(familyId);
});

final upcomingEventsProvider = FutureProvider<List<HubEvent>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  return HubRepository().getUpcomingEvents(familyId);
});

final myTasksProvider = FutureProvider<List<HubTask>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  return HubRepository().getMyTasks(familyId);
});

final familyMoodsProvider = FutureProvider<List<FamilyMood>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  return HubRepository().getRecentMoods(familyId);
});

/// Combined hub data provider — fetches all hub data in parallel via Future.wait.
/// Use this when you need the entire hub state at once (e.g. HubScreen).
final hubDataProvider = FutureProvider.autoDispose<HubState>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return HubState.empty();

  final repo = HubRepository();

  final results = await Future.wait([
    repo.getTodaySummary(familyId),
    repo.getUpcomingEvents(familyId),
    repo.getMyTasks(familyId),
    repo.getRecentMoods(familyId),
  ]);

  return HubState(
    todaySummary: results[0] as TodaySummary,
    upcomingEvents: results[1] as List<HubEvent>,
    myTasks: results[2] as List<HubTask>,
    familyMoods: results[3] as List<FamilyMood>,
    familyMembers:
        [], // Populated by familyMembersProvider separately (realtime stream)
    familyId: familyId,
  );
});

// ── Legacy Hub UI ──

final _familyMembersStreamProvider = StreamProvider<List<FamilyMember>>((ref) {
  return FamilyMembersRepository().watchMembers();
});

final familyMembersProvider = StateProvider<List<FamilyMember>>((ref) {
  final asyncValue = ref.watch(_familyMembersStreamProvider);
  return asyncValue.valueOrNull ?? [];
});

final hubCardsProvider = Provider<List<HubCard>>((ref) {
  return [
    HubCard(
      id: 'tasks',
      type: HubCardType.tasks,
      title: 'Görevler',
      subtitle: 'Aile görevlerini yönet',
      progress: 0,
      gradient: [AppColors.purple, AppColors.cobalt],
      icon: Icons.task_alt,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'calendar',
      type: HubCardType.calendar,
      title: 'Takvim',
      subtitle: 'Etkinlikleri planla',
      progress: 0,
      gradient: [AppColors.orange, AppColors.red],
      icon: Icons.calendar_today,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'budget',
      type: HubCardType.budget,
      title: 'Bütçe',
      subtitle: 'Harcamaları takip et',
      progress: 0,
      gradient: [AppColors.green, AppColors.cobalt],
      icon: Icons.account_balance_wallet,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'contacts',
      type: HubCardType.contacts,
      title: 'Rehber',
      subtitle: 'Aile rehberi',
      progress: 0,
      gradient: [AppColors.blue, AppColors.purple],
      icon: Icons.contacts,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'gallery',
      type: HubCardType.gallery,
      title: 'Galeri',
      subtitle: 'Fotoğraf ve videolar',
      progress: 0,
      gradient: [AppColors.pink, AppColors.orange],
      icon: Icons.photo_library,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'documents',
      type: HubCardType.documents,
      title: 'Belgeler',
      subtitle: 'OCR ve belge yönetimi',
      progress: 0,
      gradient: [AppColors.slate, AppColors.dark],
      icon: Icons.folder_open,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'kitchen',
      type: HubCardType.kitchen,
      title: 'Mutfak',
      subtitle: 'Tarif & yemek önerileri',
      progress: 0,
      gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
      icon: Icons.restaurant,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'education',
      type: HubCardType.education,
      title: 'Eğitim',
      subtitle: 'Aktivite & öğrenme',
      progress: 0,
      gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
      icon: Icons.school,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'shopping',
      type: HubCardType.shopping,
      title: 'Alışveriş',
      subtitle: 'Alışveriş listesi',
      progress: 0,
      gradient: [AppColors.softMint, AppColors.cobalt],
      icon: Icons.shopping_cart_outlined,
      updatedAt: DateTime.now(),
    ),
    HubCard(
      id: 'childDev',
      type: HubCardType.childDev,
      title: 'Çocuk',
      subtitle: 'Gelişim ve görevler',
      progress: 0,
      gradient: [AppColors.pink, Color(0xFFEC4899)],
      icon: Icons.child_care,
      updatedAt: DateTime.now(),
    ),
  ];
});

final recentActivityProvider = FutureProvider<List<Activity>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  // TODO: Replace with ActivityRepository when available
  return [];
});

// ── Tasks ──

final tasksProvider = StateProvider<List<Task>>((ref) => []);
final taskFilterProvider = StateProvider<String>((ref) => 'all');

// ── Calendar ──

class CalendarNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  CalendarNotifier() : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await CalendarRepository().getEvents();
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    try {
      final created = await CalendarRepository().createEvent(event);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, created]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await CalendarRepository().updateEvent(event);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((e) => e.id == event.id ? event : e).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await CalendarRepository().deleteEvent(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((e) => e.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final eventsProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<List<CalendarEvent>>>(
      (ref) => CalendarNotifier(),
    );

// ── Shopping ──

class ShoppingNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  ShoppingNotifier() : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await ShoppingRepository().getItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(
    String name, {
    ShoppingCategory category = ShoppingCategory.grocery,
  }) async {
    try {
      final item = await ShoppingRepository().createItem(
        name,
        category: category,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([item, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleItem(ShoppingItem item) async {
    try {
      final newValue = !item.isCompleted;
      await ShoppingRepository().toggleItem(item.id, newValue);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((i) {
          if (i.id == item.id) {
            return i.copyWith(
              isCompleted: newValue,
              completedBy: newValue ? '' : null,
            );
          }
          return i;
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await ShoppingRepository().deleteItem(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((i) => i.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addItems(List<ShoppingItem> items) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, ...items]);
  }
}

final shoppingItemsProvider =
    StateNotifierProvider<ShoppingNotifier, AsyncValue<List<ShoppingItem>>>(
      (ref) => ShoppingNotifier(),
    );

// ── Budget ──

class BudgetNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  BudgetNotifier() : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final txs = await BudgetRepository().getTransactions();
      state = AsyncValue.data(txs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    try {
      final created = await BudgetRepository().createTransaction(
        amount: tx.type == TransactionType.income ? tx.amount : -tx.amount,
        category: tx.category,
        description: tx.description,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([created, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTransaction(Transaction tx) async {
    // Budget entries table doesn't support direct update in our simple schema,
    // so we delete and recreate for now
    try {
      await BudgetRepository().deleteTransaction(tx.id);
      final created = await BudgetRepository().createTransaction(
        amount: tx.type == TransactionType.income ? tx.amount : -tx.amount,
        category: tx.category,
        description: tx.description,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((t) => t.id == tx.id ? created : t).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await BudgetRepository().deleteTransaction(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((t) => t.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<Transaction>>>(
      (ref) => BudgetNotifier(),
    );

class CurrentBudgetNotifier extends StateNotifier<AsyncValue<Budget>> {
  CurrentBudgetNotifier() : super(const AsyncValue.loading()) {
    loadBudget();
  }

  Future<void> loadBudget() async {
    state = const AsyncValue.loading();
    try {
      final budget = await BudgetRepository().getCurrentBudget();
      state = AsyncValue.data(budget);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final budgetProvider =
    StateNotifierProvider<CurrentBudgetNotifier, AsyncValue<Budget>>(
      (ref) => CurrentBudgetNotifier(),
    );

// ── Chat ──

final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

// ── Mood ──

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  MoodNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await MoodRepository().getEntries();
      state = entries;
    } catch (e) {
      debugPrint('Mood load error: $e');
    }
  }

  Future<void> addEntry(String emoji, {String? note}) async {
    try {
      final entry = await MoodRepository().createEntry(emoji, note: note);
      state = [entry, ...state];
    } catch (e) {
      debugPrint('Mood add error: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    await MoodRepository().deleteEntry(id);
    state = state.where((e) => e.id != id).toList();
  }
}

final moodEntriesProvider =
    StateNotifierProvider<MoodNotifier, List<MoodEntry>>(
      (ref) => MoodNotifier(),
    );

// ── Streak ──

final streakEntriesProvider = StateProvider<List<StreakEntry>>((ref) => []);

// ── Weather ──

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final useLocation = HiveService.getBoolSetting(
    'weatherUseLocation',
    defaultValue: true,
  );
  final cityName = HiveService.getSetting('weatherCity') ?? 'İstanbul';
  final celsius = HiveService.getBoolSetting(
    'weatherCelsius',
    defaultValue: true,
  );

  // 1. Saved manual location from map picker
  final savedLoc = HiveService.getLocation();
  if (savedLoc != null && !useLocation) {
    return WeatherService.fetchWeather(
      savedLoc.latitude,
      savedLoc.longitude,
      celsius: celsius,
    );
  }

  // 2. GPS current location
  if (useLocation) {
    try {
      return await LocationWeatherService.getCurrentLocationWeather(
        celsius: celsius,
      );
    } catch (_) {
      // fallback
    }
  }

  // 3. Fallback to selected city
  final city = WeatherService.cities.firstWhere(
    (c) => c['name'] == cityName,
    orElse: () => WeatherService.cities.first,
  );
  return WeatherService.fetchWeather(
    city['lat'] as double,
    city['lon'] as double,
    celsius: celsius,
  );
});

// ── Theme & Appearance ──

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final accentColorProvider = StateProvider<Color>((ref) => AppColors.cobalt);
final fontScaleProvider = StateProvider<double>((ref) => 1.0);
