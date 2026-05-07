import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/analytics/analytics_service.dart';
import 'ai_content_service.dart';
import 'content_cache_service.dart';
import 'content_models.dart';

/// Loads, caches, and serves FamilyHub seed content data.
///
/// Data flow: Asset JSON → Hive cache → Typed models → UI
class ContentEngine {
  ContentEngine._();
  static final ContentEngine _instance = ContentEngine._();
  static ContentEngine get instance => _instance;

  static const String _boxName = 'content_cache';
  static const String _keyPrefix = 'familyhub_content_';

  ChildDevelopmentData? _childDev;
  MealPlanningData? _mealPlanning;
  HouseholdData? _household;
  BudgetData? _budget;
  FuturePlanningData? _futurePlanning;

  bool _initialized = false;
  int _recipeOffset = 0;
  int _tipOffset = 0;
  int _taskOffset = 0;
  int _savingOffset = 0;

  /// Initialize the engine: load from cache or seed assets.
  static Future<void> initialize() async {
    await ContentCacheService.instance.initialize();
    await _instance._loadAll();
  }

  /// Initializes AI content service with API key.
  /// Call this after user consent / premium check.
  static void initializeAI({required String apiKey, String? masterPrompt}) {
    AIContentService.instance.initialize(
      apiKey: apiKey,
      masterPrompt: masterPrompt,
    );
  }

  Future<void> _loadAll() async {
    if (_initialized) return;

    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box<String>(_boxName)
        : await Hive.openBox<String>(_boxName);

    // Load each module with cache-first strategy
    _childDev = await _loadModule(
      box: box,
      moduleKey: 'child_development',
      assetPath: 'assets/data/child_development.json',
      parser: (json) => ChildDevelopmentData.fromJson(json),
    );

    _mealPlanning = await _loadModule(
      box: box,
      moduleKey: 'meal_planning',
      assetPath: 'assets/data/meal_planning.json',
      parser: (json) => MealPlanningData.fromJson(json),
    );

    _household = await _loadModule(
      box: box,
      moduleKey: 'household',
      assetPath: 'assets/data/household.json',
      parser: (json) => HouseholdData.fromJson(json),
    );

    _budget = await _loadModule(
      box: box,
      moduleKey: 'budget',
      assetPath: 'assets/data/budget.json',
      parser: (json) => BudgetData.fromJson(json),
    );

    _futurePlanning = await _loadModule(
      box: box,
      moduleKey: 'future_planning',
      assetPath: 'assets/data/future_planning.json',
      parser: (json) => FuturePlanningData.fromJson(json),
    );

    _initialized = true;

    AnalyticsService.track('content_engine_initialized', properties: {
      'modules_loaded': 5,
    });
  }

  Future<T?> _loadModule<T>({
    required Box<String> box,
    required String moduleKey,
    required String assetPath,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final cacheKey = '$_keyPrefix$moduleKey';

    // 1. Try cache with stale check
    final cached = box.get(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      final isStale = ContentCacheService.instance.isStale(
        module: moduleKey,
        contentKey: 'seed',
      );
      if (!isStale) {
        try {
          final json = jsonDecode(cached) as Map<String, dynamic>;
          return parser(json);
        } catch (_) {
          // Cache corrupted, fall through
        }
      }
    }

    // 2. Load from asset
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Save to both legacy and new cache
      await box.put(cacheKey, raw);
      await ContentCacheService.instance.put(
        module: moduleKey,
        contentKey: 'seed',
        content: json,
      );

      return parser(json);
    } catch (e) {
      AnalyticsService.track('content_load_error', properties: {
        'module': moduleKey,
        'error': e.toString(),
      });
      return null;
    }
  }

  // ── Module Accessors ──────────────────────────────────────────────────

  ChildDevelopmentData? get childDevelopment => _childDev;
  MealPlanningData? get mealPlanning => _mealPlanning;
  HouseholdData? get household => _household;
  BudgetData? get budget => _budget;
  FuturePlanningData? get futurePlanning => _futurePlanning;

  // ── Convenience Queries ───────────────────────────────────────────────

  /// Returns a daily rotating recipe based on day of month.
  Recipe? get dailyRecipe {
    final recipes = _mealPlanning?.recipes;
    if (recipes == null || recipes.isEmpty) return null;
    final index = (DateTime.now().day + _recipeOffset) % recipes.length;
    return recipes[index];
  }

  void nextRecipe() => _recipeOffset++;
  void prevRecipe() => _recipeOffset = (_recipeOffset - 1).clamp(0, 1000);

  /// Returns today's meal plan (Mon-Sun mapped from weekly template).
  DailyMeals? get todayMeals {
    final template = _mealPlanning?.weeklyTemplate;
    if (template == null) return null;
    final dayNames = ['pazar', 'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi'];
    final dayName = dayNames[DateTime.now().weekday % 7];
    return template[dayName];
  }

  /// Returns a random activity appropriate for the given age group.
  Activity? getRandomActivity(String ageGroup) {
    final group = _childDev?.ageGroups[ageGroup];
    final activities = group?.activities;
    if (activities == null || activities.isEmpty) return null;
    final index = DateTime.now().day % activities.length;
    return activities[index];
  }

  /// Returns today's featured activity from a rotating age group.
  Activity? get dailyActivity {
    final ageKeys = _childDev?.ageGroups.keys.toList();
    if (ageKeys == null || ageKeys.isEmpty) return null;
    final dayIndex = DateTime.now().day % ageKeys.length;
    final ageGroup = ageKeys[dayIndex];
    return getRandomActivity(ageGroup);
  }

  /// Returns the name of the current rotating age group.
  String? get dailyActivityAgeGroup {
    final ageKeys = _childDev?.ageGroups.keys.toList();
    if (ageKeys == null || ageKeys.isEmpty) return null;
    final dayIndex = DateTime.now().day % ageKeys.length;
    final key = ageKeys[dayIndex];
    return _ageGroupDisplayName(key);
  }

  String _ageGroupDisplayName(String key) {
    return switch (key) {
      '0_12_months' => '0-12 Ay',
      '1_2_years' => '1-2 Yaş',
      '3_5_years' => '3-5 Yaş',
      '6_8_years' => '6-8 Yaş',
      '9_12_years' => '9-12 Yaş',
      _ => key,
    };
  }

  /// Returns today's household tip.
  String? get dailyHouseholdTip {
    final tips = _household?.ecoTips;
    if (tips == null || tips.isEmpty) return null;
    final index = (DateTime.now().day + _tipOffset) % tips.length;
    return tips[index];
  }

  void nextTip() => _tipOffset++;
  void prevTip() => _tipOffset = (_tipOffset - 1).clamp(0, 1000);

  /// Returns a random budget saving tip.
  CostCuttingTip? get dailySavingTip {
    final tips = _budget?.costCuttingTips;
    if (tips == null || tips.isEmpty) return null;
    final index = (DateTime.now().day + _savingOffset) % tips.length;
    return tips[index];
  }

  void nextSavingTip() => _savingOffset++;
  void prevSavingTip() => _savingOffset = (_savingOffset - 1).clamp(0, 1000);

  /// Returns today's cleaning task from weekly schedule.
  String? get todayCleaningTask {
    final schedule = _household?.weeklySchedule;
    if (schedule == null) return null;
    final dayNames = ['pazar', 'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi'];
    final dayName = dayNames[(DateTime.now().weekday + _taskOffset) % 7];
    return schedule[dayName];
  }

  void nextTask() => _taskOffset++;
  void prevTask() => _taskOffset = (_taskOffset - 1).clamp(0, 1000);

  /// Returns emergency contacts list.
  List<EmergencyContact> get emergencyContacts {
    return _futurePlanning?.emergencyPlan.contacts ?? [];
  }

  /// Clears all cached content (forces reload from assets on next init).
  static Future<void> clearCache() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    await box.clear();
  }

  /// Refreshes a specific module from assets (use for updates).
  static Future<void> refreshModule(String moduleKey) async {
    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box<String>(_boxName);
      await box.delete('$_keyPrefix$moduleKey');
    }
    await ContentCacheService.instance.invalidateModule(moduleKey);
    await _instance._loadAll();
  }

  // ── AI-Powered Content Generation ─────────────────────────────────────

  /// Generates personalized content based on family profile.
  /// Requires AI to be initialized via [initializeAI].
  static Future<Map<String, dynamic>?> generatePersonalizedContent({
    required String familyType,
    required List<int> childrenAges,
    required double budgetRange,
    required String region,
    String? specialRequests,
  }) async {
    try {
      final result = await AIContentService.instance.generatePersonalized(
        familyType: familyType,
        childrenAges: childrenAges,
        budgetRange: budgetRange,
        region: region,
        specialRequests: specialRequests,
      );

      AnalyticsService.track('ai_personalized_generated', properties: {
        'family_type': familyType,
        'region': region,
      });

      return result;
    } on AIContentException catch (e) {
      debugPrint('AIContentService error: $e');
      AnalyticsService.track('ai_personalized_error', properties: {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Refreshes a module via AI (fallback when assets are outdated).
  static Future<Map<String, dynamic>?> refreshModuleFromAI(String moduleName) async {
    try {
      final result = await AIContentService.instance.refreshModule(moduleName);

      // Cache the AI-generated content
      await ContentCacheService.instance.put(
        module: moduleName,
        contentKey: 'ai_generated',
        content: result,
      );

      AnalyticsService.track('ai_module_refreshed', properties: {
        'module': moduleName,
      });

      return result;
    } on AIContentException catch (e) {
      debugPrint('AIContentService error: $e');
      AnalyticsService.track('ai_module_refresh_error', properties: {
        'module': moduleName,
        'error': e.toString(),
      });
      return null;
    }
  }
}
