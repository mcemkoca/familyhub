import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/ai_suggestion.dart';

/// 10 kategoride toplam 1000+ aile önerisi havuzu.
/// Asset JSON'larını yükler, Hive cache'ler, kategorilere göre filtreler.
class FamilySuggestionsPool {
  FamilySuggestionsPool._();
  static final FamilySuggestionsPool _instance = FamilySuggestionsPool._();
  static FamilySuggestionsPool get instance => _instance;

  static const String _boxName = 'family_suggestions_cache';
  static const String _cacheKey = 'familyhub_suggestions_v2';

  final List<AISuggestion> _all = [];
  bool _initialized = false;

  /// Kategoriler ve display isimleri
  static const Map<String, String> categoryLabels = {
    'communication': 'Aile İletişimi',
    'health': 'Sağlıklı Yaşam',
    'education': 'Çocuk Gelişimi',
    'chore': 'Ev Düzeni',
    'finance': 'Bütçe Yönetimi',
    'safety': 'Güvenlik',
    'recipe': 'Yemek & Beslenme',
    'social': 'Sosyal Aktiviteler',
    'digital': 'Dijital Denge',
  };

  static const List<String> _assetPaths = [
    'assets/data/suggestions/family_communication.json',
    'assets/data/suggestions/healthy_living.json',
    'assets/data/suggestions/child_development.json',
    'assets/data/suggestions/home_organization.json',
    'assets/data/suggestions/budget_management.json',
    'assets/data/suggestions/safety_measures.json',
    'assets/data/suggestions/education_support.json',
    'assets/data/suggestions/meal_nutrition.json',
    'assets/data/suggestions/social_activities.json',
    'assets/data/suggestions/digital_balance.json',
  ];

  /// Initialize: load from cache or assets
  static Future<void> initialize() async {
    await _instance._load();
  }

  Future<void> _load() async {
    if (_initialized) return;

    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box<String>(_boxName)
        : await Hive.openBox<String>(_boxName);

    // Try cache first
    final cached = box.get(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = List<Map<String, dynamic>>.from(jsonDecode(cached));
        _all.addAll(list.map((e) => _fromJson(e)));
        _initialized = true;
        return;
      } catch (_) {
        // Cache corrupted, fall through
      }
    }

    // Load from assets
    for (final path in _assetPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List<dynamic>;
        for (final s in suggestions) {
          _all.add(_fromJson(s as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('FamilySuggestionsPool: Error loading $path: $e');
      }
    }

    // Save to cache
    try {
      final encoded = jsonEncode(_all.map((s) => s.toJson()).toList());
      await box.put(_cacheKey, encoded);
    } catch (_) {}

    _initialized = true;
  }

  /// Get all suggestions
  List<AISuggestion> get all => List.unmodifiable(_all);

  /// Get suggestions by category
  List<AISuggestion> byCategory(String category) {
    return _all.where((s) => s.type == category).toList();
  }

  /// Get available categories from loaded data
  Set<String> get categories {
    return _all.map((s) => s.type).toSet();
  }

  /// Pick daily suggestions based on settings
  List<AISuggestion> pickDaily({
    required DateTime date,
    required Set<String> enabledCategories,
    required List<String> excludedIds,
    int count = 5,
    int? childAge,
  }) {
    final available = _all
        .where((s) => enabledCategories.contains(s.type))
        .where((s) => !excludedIds.contains(s.id))
        .where((s) => childAge == null || _matchesAge(s, childAge))
        .toList();

    if (available.isEmpty) return [];

    final seed = date.year * 10000 + date.month * 100 + date.day;
    final dailyRandom = Random(seed);
    available.shuffle(dailyRandom);

    return available.take(count).toList();
  }

  /// Pick more suggestions (when user wants to see more)
  List<AISuggestion> pickMore({
    required DateTime date,
    required Set<String> enabledCategories,
    required List<String> alreadyShownIds,
    int count = 5,
    int? childAge,
  }) {
    final available = _all
        .where((s) => enabledCategories.contains(s.type))
        .where((s) => !alreadyShownIds.contains(s.id))
        .where((s) => childAge == null || _matchesAge(s, childAge))
        .toList();

    if (available.isEmpty) return [];

    final seed = date.year * 10000 + date.month * 100 + date.day + 9999;
    final random = Random(seed);
    available.shuffle(random);

    return available.take(count).toList();
  }

  /// Search suggestions by keyword
  List<AISuggestion> search(String query) {
    final q = query.toLowerCase();
    return _all.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Clear cache to force reload from assets
  static Future<void> clearCache() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    await box.delete(_cacheKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _matchesAge(AISuggestion s, int childAge) {
    if (s.minAge == null && s.maxAge == null) return true;
    if (s.minAge != null && childAge < s.minAge!) return false;
    if (s.maxAge != null && childAge > s.maxAge!) return false;
    return true;
  }

  static AISuggestion _fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      id: json['id'] as String,
      type: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      action: json['action_type'] as String? ?? 'show_detail',
      difficulty: json['difficulty'] as String? ?? 'Kolay',
      durationMinutes: json['duration_minutes'] as int? ?? 15,
      servings: json['participants'] as int? ?? 4,
      calories: null,
      ingredients: [],
      tips: (json['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      isNew: false,
      shareable: true,
      allowAlternatives: false,
      progress: 0,
      isFavorite: false,
      assignedTo: null,
      estimatedCost: null,
      userComment: null,
      badge: null,
      nutritionInfo: null,
      alternativeOptions: [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
    );
  }
}


