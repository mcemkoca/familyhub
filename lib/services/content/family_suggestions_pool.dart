import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/ai_suggestion.dart';
import '../../core/localization/app_locale.dart';
import '../hive_service.dart';

/// Locale-aware family suggestion pool.
///
/// The pool keeps a separate cache for every supported language and reloads
/// when the user changes language. Until localized asset files are completed,
/// Turkish assets are used only as an explicit fallback.
class FamilySuggestionsPool {
  FamilySuggestionsPool._();

  static final FamilySuggestionsPool _instance = FamilySuggestionsPool._();
  static FamilySuggestionsPool get instance => _instance;

  static const String _boxName = 'family_suggestions_cache';
  static const String _cacheVersion = 'v3';

  final List<AISuggestion> _all = [];
  String? _loadedLocale;

  static const Map<String, Map<String, String>> categoryLabels = {
    'tr': {
      'communication': 'Aile İletişimi',
      'health': 'Sağlıklı Yaşam',
      'education': 'Çocuk Gelişimi',
      'chore': 'Ev Düzeni',
      'finance': 'Bütçe Yönetimi',
      'safety': 'Güvenlik',
      'recipe': 'Yemek & Beslenme',
      'social': 'Sosyal Aktiviteler',
      'digital': 'Dijital Denge',
    },
    'nl': {
      'communication': 'Gezinscommunicatie',
      'health': 'Gezond leven',
      'education': 'Kinderontwikkeling',
      'chore': 'Huishouding',
      'finance': 'Budgetbeheer',
      'safety': 'Veiligheid',
      'recipe': 'Voeding en recepten',
      'social': 'Sociale activiteiten',
      'digital': 'Digitale balans',
    },
    'fr': {
      'communication': 'Communication familiale',
      'health': 'Vie saine',
      'education': 'Développement de l’enfant',
      'chore': 'Organisation du foyer',
      'finance': 'Gestion du budget',
      'safety': 'Sécurité',
      'recipe': 'Repas et nutrition',
      'social': 'Activités sociales',
      'digital': 'Équilibre numérique',
    },
    'en': {
      'communication': 'Family Communication',
      'health': 'Healthy Living',
      'education': 'Child Development',
      'chore': 'Home Organisation',
      'finance': 'Budget Management',
      'safety': 'Safety',
      'recipe': 'Food & Nutrition',
      'social': 'Social Activities',
      'digital': 'Digital Balance',
    },
  };

  static const List<String> _assetFileNames = [
    'family_communication.json',
    'healthy_living.json',
    'child_development.json',
    'home_organization.json',
    'budget_management.json',
    'safety_measures.json',
    'education_support.json',
    'meal_nutrition.json',
    'social_activities.json',
    'digital_balance.json',
  ];

  static Future<void> initialize() async {
    final locale = _currentLocaleCode();
    await _instance._load(locale);
  }

  static Future<void> reloadForLocale(String localeCode) async {
    final normalized = AppLanguage.fromStoredValue(localeCode).code;
    await _instance._load(normalized, force: true);
  }

  static String categoryLabel(String category, {String? localeCode}) {
    final locale = AppLanguage.fromStoredValue(
      localeCode ?? HiveService.getSetting('languageCode'),
    ).code;
    return categoryLabels[locale]?[category] ??
        categoryLabels['en']?[category] ??
        category;
  }

  Future<void> _load(String locale, {bool force = false}) async {
    if (!force && _loadedLocale == locale && _all.isNotEmpty) return;

    _all.clear();
    _loadedLocale = locale;

    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box<String>(_boxName)
        : await Hive.openBox<String>(_boxName);
    final cacheKey = _cacheKey(locale);

    final cached = box.get(cacheKey);
    if (!force && cached != null && cached.isNotEmpty) {
      try {
        final list = List<Map<String, dynamic>>.from(
          jsonDecode(cached) as List<dynamic>,
        );
        _all.addAll(list.map(_fromJson));
        return;
      } catch (_) {
        await box.delete(cacheKey);
      }
    }

    for (final fileName in _assetFileNames) {
      final localizedPath = 'assets/data/suggestions/$locale/$fileName';
      final fallbackPath = 'assets/data/suggestions/$fileName';

      Map<String, dynamic>? data;
      try {
        final raw = await rootBundle.loadString(localizedPath);
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        if (locale == 'tr') {
          try {
            final raw = await rootBundle.loadString(fallbackPath);
            data = jsonDecode(raw) as Map<String, dynamic>;
          } catch (error) {
            debugPrint('FamilySuggestionsPool: $fallbackPath: $error');
          }
        }
      }

      if (data == null) continue;
      final suggestions = data['suggestions'] as List<dynamic>? ?? const [];
      for (final suggestion in suggestions) {
        _all.add(_fromJson(suggestion as Map<String, dynamic>));
      }
    }

    try {
      final encoded = jsonEncode(_all.map((item) => item.toJson()).toList());
      await box.put(cacheKey, encoded);
    } catch (error) {
      debugPrint('FamilySuggestionsPool cache error: $error');
    }
  }

  List<AISuggestion> get all => List.unmodifiable(_all);

  List<AISuggestion> byCategory(String category) =>
      _all.where((item) => item.type == category).toList();

  Set<String> get categories => _all.map((item) => item.type).toSet();

  List<AISuggestion> pickDaily({
    required DateTime date,
    required Set<String> enabledCategories,
    required List<String> excludedIds,
    int count = 5,
    int? childAge,
  }) {
    final available = _all
        .where((item) => enabledCategories.contains(item.type))
        .where((item) => !excludedIds.contains(item.id))
        .where((item) => childAge == null || _matchesAge(item, childAge))
        .toList();

    if (available.isEmpty) return [];

    final seed = date.year * 10000 + date.month * 100 + date.day;
    available.shuffle(Random(seed));
    return available.take(count).toList();
  }

  List<AISuggestion> pickMore({
    required DateTime date,
    required Set<String> enabledCategories,
    required List<String> alreadyShownIds,
    int count = 5,
    int? childAge,
  }) {
    final available = _all
        .where((item) => enabledCategories.contains(item.type))
        .where((item) => !alreadyShownIds.contains(item.id))
        .where((item) => childAge == null || _matchesAge(item, childAge))
        .toList();

    if (available.isEmpty) return [];

    final seed = date.year * 10000 + date.month * 100 + date.day + 9999;
    available.shuffle(Random(seed));
    return available.take(count).toList();
  }

  List<AISuggestion> search(String query) {
    final normalized = query.toLowerCase();
    return _all.where((item) {
      return item.title.toLowerCase().contains(normalized) ||
          item.description.toLowerCase().contains(normalized) ||
          item.tags.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
  }

  static Future<void> clearCache({String? localeCode}) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<String>(_boxName);
    if (localeCode == null) {
      await box.clear();
      return;
    }
    await box.delete(_cacheKey(AppLanguage.fromStoredValue(localeCode).code));
  }

  static String _cacheKey(String locale) =>
      'familyhub_suggestions_${_cacheVersion}_$locale';

  static String _currentLocaleCode() {
    final stored = HiveService.getSetting('languageCode') ??
        HiveService.getSetting('language');
    return AppLanguage.fromStoredValue(stored).code;
  }

  static bool _matchesAge(AISuggestion suggestion, int childAge) {
    if (suggestion.minAge == null && suggestion.maxAge == null) return true;
    if (suggestion.minAge != null && childAge < suggestion.minAge!) return false;
    if (suggestion.maxAge != null && childAge > suggestion.maxAge!) return false;
    return true;
  }

  static AISuggestion _fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      id: json['id'] as String,
      type: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      action: json['action_type'] as String? ?? 'show_detail',
      difficulty: json['difficulty'] as String? ?? '',
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
