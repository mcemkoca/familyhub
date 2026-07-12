import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities.dart';
import '../../repositories/hub_repository.dart';
import '../../repositories/shopping_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/family_members_repository.dart';
import '../../services/auth_service.dart';
import '../../services/localization/locale_service.dart';
import '../../services/weather_service.dart';
import '../../services/location_weather_service.dart';
import '../../services/location_service.dart';
import '../../services/hive_service.dart';
import '../../services/notification_service.dart';
import '../../services/koca_seed.dart';
import '../../repositories/mood_repository.dart';
import '../../repositories/activity_repository.dart';
import '../../domain/models/hub_state.dart';

// Re-export auth providers from auth_service.dart
export '../../services/auth_service.dart'
    show authStateProvider, authUserProvider, currentUserProvider;

// Re-export child auth providers
export '../../services/child_auth_service.dart' show ChildAuthService;

// ── Auth (exported from auth_service.dart) ──
// authStateProvider, authUserProvider, currentUserProvider

/// Uygulama dili. Başlangıç değeri LocaleService ile YAN-ETKİSİZ çözülür
/// (sağlayıcı içinde Hive'a yazılmaz; kalıcılık açık kullanıcı eylemlerinde).
final localeProvider = StateProvider<Locale>((ref) {
  return LocaleService.resolveInitialLocale();
});

/// Seçili ülke kodu (BE/TR/NL/FR/DE) — register'da belirlenir, ayarlardan değişir.
/// Ülkeye bağlı içerik (dil, para birimi, gider şablonu, market) bunu kullanır.
final countryProvider = StateProvider<String>((ref) {
  return HiveService.getSetting('country') ?? 'BE';
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

/// Cihazın internet bağlantısı var mı — çevrimdışı rozeti için canlı akış.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  bool has(List<ConnectivityResult> r) =>
      r.isNotEmpty && !r.contains(ConnectivityResult.none);
  try {
    yield has(await Connectivity().checkConnectivity());
    yield* Connectivity().onConnectivityChanged.map(has);
  } catch (_) {
    yield true; // tespit edilemezse çevrimiçi varsay
  }
});

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


/// Hub realtime senkronu — events + family_moods tablolarındaki değişimleri
/// dinleyip ilgili FutureProvider'ları invalidate eder. Böylece BAŞKA bir aile
/// üyesi/cihaz etkinlik veya ruh hali eklediğinde hub anında güncellenir.
/// Ekran build'inde watch edilerek canlı tutulur.
final hubRealtimeSyncProvider = Provider.autoDispose<void>((ref) {
  final familyId = ref.watch(familyIdProvider).valueOrNull;
  final client = SupabaseConfig.safeClient;
  if (familyId == null || client == null) return;

  final subs = <StreamSubscription<dynamic>>[];
  try {
    // Not: family_moods hub'da gösterilmiyor (ölü kod) → abone olmuyoruz.
    subs.add(client
        .from('events')
        .stream(primaryKey: ['id'])
        .listen((_) {
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(todaySummaryProvider);
        }, onError: (_) {}));
    subs.add(client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .listen((_) {
          ref.invalidate(myTasksProvider);
          ref.invalidate(todaySummaryProvider);
        }, onError: (_) {}));
  } catch (_) {}

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
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
  final remote = asyncValue.valueOrNull ?? [];
  // Supabase erişilemez/boşsa (ör. RLS/çevrimdışı) yerel aile üyelerine düş —
  // böylece üyeler tüm bölümlerde tutarlı görünür ve kullanılabilir.
  if (remote.isNotEmpty) return remote;
  return localFamilyMembers();
});

/// Yerel (Hive) aile üyelerini FamilyMember listesine çevirir.
/// Aile Yönetimi ekranından düzenlenir; Supabase boşken tüm bölümler bunu
/// kullanır (harita, sağlık, konum, davet vb.).
List<FamilyMember> localFamilyMembers() {
  const palette = [
    Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFF10B981),
    Color(0xFFF97316), Color(0xFF8B5CF6), Color(0xFF14B8A6),
  ];
  final raw = KocaSeed.localMembers();
  return List.generate(raw.length, (i) {
    final m = raw[i];
    final name = (m['name'] ?? '').toString();
    final roleStr = (m['role'] ?? '').toString().toLowerCase();
    MemberRole role;
    if (roleStr.contains('çocuk') || roleStr.contains('cocuk')) {
      role = MemberRole.child;
    } else if (roleStr.contains('bebek')) {
      role = MemberRole.baby;
    } else if (roleStr.contains('yönetici') || roleStr.contains('yonetici') ||
        roleStr.contains('admin')) {
      role = MemberRole.admin;
    } else if (roleStr.contains('genç') || roleStr.contains('genc') ||
        roleStr.contains('teen')) {
      role = MemberRole.teen;
    } else if (roleStr.contains('büyük') || roleStr.contains('buyuk') ||
        roleStr.contains('elder') || roleStr.contains('dede') ||
        roleStr.contains('nine')) {
      role = MemberRole.elder;
    } else if (roleStr.contains('misafir') || roleStr.contains('guest')) {
      role = MemberRole.guest;
    } else {
      role = MemberRole.parent;
    }
    return FamilyMember(
      id: 'local_$i',
      name: name,
      initial: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
      color: palette[i % palette.length],
      role: role,
      isOnline: m['online'] == true,
    );
  });
}

/// Current authenticated user's role in the family.
/// Falls back to [MemberRole.parent] if not found (e.g. during loading).
final currentMemberRoleProvider = Provider<MemberRole>((ref) {
  final members = ref.watch(familyMembersProvider);
  final userId = AuthService.currentUserId;
  if (userId == null || members.isEmpty) return MemberRole.parent;
  try {
    return members.firstWhere((m) => m.id == userId).role;
  } catch (_) {
    return MemberRole.parent;
  }
});

final recentActivityProvider = FutureProvider<List<Activity>>((ref) async {
  final familyId = await ref.watch(familyIdProvider.future);
  if (familyId == null) return [];
  return ActivityRepository().getRecentActivities();
});

// ── Tasks ──

final tasksProvider = StateProvider<List<Task>>((ref) => []);
final taskFilterProvider = StateProvider<String>((ref) => 'all');

// ── Calendar ──

class CalendarNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  CalendarNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadEvents();
    _subscribeRealtime();
  }

  final Ref _ref;
  StreamSubscription<dynamic>? _rt;

  /// Hub/Plan da aynı 'events' tablosunu okur (upcomingEventsProvider) — takvim
  /// değişince onu da tazele ki plan anında güncellensin.
  void _refreshDependents() {
    _ref.invalidate(upcomingEventsProvider);
  }

  void _subscribeRealtime() {
    try {
      _rt = CalendarRepository().watchEvents().listen(
            (_) => _reloadSilent(),
            onError: (_) {},
          );
    } catch (_) {}
  }

  Future<void> _reloadSilent() async {
    try {
      final events = await CalendarRepository().getEvents();
      if (mounted) state = AsyncValue.data(events);
      _refreshDependents();
    } catch (_) {}
  }

  @override
  void dispose() {
    _rt?.cancel();
    super.dispose();
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
      _refreshDependents();
      unawaited(_scheduleEventReminders(created));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Etkinliğin hatırlatıcıları için gerçek yerel bildirim zamanlar.
  /// reminders boşsa varsayılan olarak 30 dk önce hatırlatır.
  Future<void> _scheduleEventReminders(CalendarEvent event) async {
    try {
      final now = DateTime.now();
      if (event.start.isBefore(now)) return;
      await NotificationService.requestPermission();
      final mins = event.reminders.isNotEmpty ? event.reminders : const [30];
      for (final m in mins) {
        final when = event.start.subtract(Duration(minutes: m));
        if (when.isBefore(now)) continue;
        final base = event.id.hashCode & 0x7fffff;
        await NotificationService.scheduleNotification(
          id: (base + m) % 2147483647,
          title: '📅 ${event.title}',
          body: m == 0
              ? 'Şimdi başlıyor'
              : '$m dakika içinde başlıyor'
                  '${event.location != null && event.location!.isNotEmpty ? ' · ${event.location}' : ''}',
          scheduledDate: when,
          payload: 'event:${event.id}',
        );
      }
    } catch (_) {
      // Bildirim kurulamazsa etkinlik yine de eklenmiş olur.
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await CalendarRepository().updateEvent(event);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((e) => e.id == event.id ? event : e).toList(),
      );
      _refreshDependents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final current = state.valueOrNull ?? [];
      CalendarEvent? removed;
      for (final e in current) {
        if (e.id == id) {
          removed = e;
          break;
        }
      }
      await CalendarRepository().deleteEvent(id);
      state = AsyncValue.data(current.where((e) => e.id != id).toList());
      _refreshDependents();
      if (removed != null) unawaited(_cancelEventReminders(removed));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _cancelEventReminders(CalendarEvent event) async {
    try {
      final mins = event.reminders.isNotEmpty ? event.reminders : const [30];
      final base = event.id.hashCode & 0x7fffff;
      for (final m in mins) {
        await NotificationService.cancelNotification((base + m) % 2147483647);
      }
    } catch (_) {}
  }
}

final eventsProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<List<CalendarEvent>>>(
      (ref) => CalendarNotifier(ref),
    );

// ── Shopping ──

class ShoppingNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  ShoppingNotifier() : super(const AsyncValue.loading()) {
    loadItems();
    _subscribeRealtime();
  }

  StreamSubscription<dynamic>? _rt;

  // Başka bir aile üyesi değişiklik yaptığında anında güncelle (realtime).
  // Realtime kapalıysa/başarısızsa sessizce yok sayılır.
  void _subscribeRealtime() {
    try {
      _rt = ShoppingRepository().watchItems().listen(
            (_) => _reloadSilent(),
            onError: (_) {},
          );
    } catch (_) {}
  }

  Future<void> _reloadSilent() async {
    try {
      final items = await ShoppingRepository().getItems();
      if (mounted) state = AsyncValue.data(items);
    } catch (_) {}
  }

  @override
  void dispose() {
    _rt?.cancel();
    super.dispose();
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
    int? quantity,
    ShoppingUnit unit = ShoppingUnit.piece,
  }) async {
    try {
      final item = await ShoppingRepository().createItem(
        name,
        category: category,
        quantity: quantity ?? 1,
        unit: unit,
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
      final userId = AuthService.currentUserId;
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((i) {
          if (i.id == item.id) {
            return i.copyWith(
              isCompleted: newValue,
              completedBy: newValue ? userId : null,
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
    _subscribeRealtime();
  }

  StreamSubscription<dynamic>? _rt;

  void _subscribeRealtime() {
    try {
      _rt = BudgetRepository().watchTransactions().listen(
            (_) => _reloadSilent(),
            onError: (_) {},
          );
    } catch (_) {}
  }

  Future<void> _reloadSilent() async {
    try {
      final txs = await BudgetRepository().getTransactions();
      if (mounted) state = AsyncValue.data(txs);
    } catch (_) {}
  }

  @override
  void dispose() {
    _rt?.cancel();
    super.dispose();
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
    _subscribeRealtime();
  }

  StreamSubscription<dynamic>? _rt;

  void _subscribeRealtime() {
    try {
      _rt = MoodRepository().watchEntries().listen(
            (_) => _load(),
            onError: (_) {},
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _rt?.cancel();
    super.dispose();
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
  final cityName = HiveService.getSetting('weatherCity') ?? 'Brüksel';
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

/// Mevcut konumu (şehir/ülke) çözer ve Hive'a önbellekler.
/// Kayıtlı konum varsa onu döndürür; yoksa GPS'ten çekip kaydeder — böylece
/// hub'daki konum satırı gerçek cihazda "Konum ayarlanmadı"da takılı kalmaz.
final currentLocationProvider = FutureProvider<LocationModel?>((ref) async {
  final cached = HiveService.getLocation();
  if (cached != null && cached.city.isNotEmpty) return cached;

  try {
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) return cached;
    final model = await LocationService.getAddressFromCoords(
      pos.latitude,
      pos.longitude,
    );
    if (model != null && model.city.isNotEmpty) {
      await HiveService.saveLocation(model);
      return model;
    }
  } catch (_) {
    // Sessizce önbelleğe/varsayılana düş.
  }
  return cached;
});

/// Bir aile üyesinin canlı (gerçek) konumu — geolocations tablosundan.
class LivePosition {
  final double lat;
  final double lng;
  final DateTime at;
  final num? speed;
  final int? battery;
  const LivePosition(this.lat, this.lng, this.at, {this.speed, this.battery});
}

/// Ebeveynin ailesindeki tüm üyelerin EN GÜNCEL canlı konumu.
/// Anahtar = user_id veya child_id. geolocations tablosunu family_id ile
/// süzüp gerçek zamanlı yayınlar (aile haritası bunu kullanır).
final familyLiveLocationsProvider =
    StreamProvider<Map<String, LivePosition>>((ref) async* {
  final familyId = await ref.watch(familyIdProvider.future);
  final client = SupabaseConfig.safeClient;
  if (familyId == null || client == null) {
    yield <String, LivePosition>{};
    return;
  }
  yield* client
      .from('geolocations')
      .stream(primaryKey: ['id'])
      .eq('family_id', familyId)
      .order('created_at')
      .map((rows) {
    final latest = <String, LivePosition>{};
    for (final r in rows) {
      final key = (r['user_id'] ?? r['child_id'])?.toString();
      final lat = (r['lat'] as num?)?.toDouble();
      final lng = (r['lng'] as num?)?.toDouble();
      if (key == null || lat == null || lng == null) continue;
      final at = DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now();
      final existing = latest[key];
      if (existing == null || at.isAfter(existing.at)) {
        latest[key] = LivePosition(lat, lng, at,
            speed: r['speed'] as num?, battery: r['battery_level'] as int?);
      }
    }
    return latest;
  });
});

// ── Theme & Appearance ──

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final accentColorProvider = StateProvider<Color>((ref) => const Color(0xFF6366F1));
final fontScaleProvider = StateProvider<double>((ref) => 1.0);
