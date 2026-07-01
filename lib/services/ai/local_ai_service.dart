import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

/// Tokensiz yerel AI servisi.
/// API çağrısı yapmaz — tüm içerik assets/data/content/ JSON dosyalarından gelir.
/// Kural tabanlı + rastgele seçim ile kişiselleştirilmiş öneriler üretir.
class LocalAIService {
  static final LocalAIService _instance = LocalAIService._();
  factory LocalAIService() => _instance;
  LocalAIService._();

  final _rng = Random();
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _activities = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final recipeRaw =
          await rootBundle.loadString('assets/data/content/recipes.json');
      _recipes = (jsonDecode(recipeRaw) as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    try {
      final eduRaw =
          await rootBundle.loadString('assets/data/content/education.json');
      _activities = (jsonDecode(eduRaw) as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    _loaded = true;
  }

  // ── GÜNLÜK PROGRAM ──────────────────────────────────────────────────────

  /// Bugünün saatine göre bağlamsal kart önerileri döner
  Future<List<AISuggestion>> getDailySuggestions({
    int childCount = 1,
    int adultCount = 2,
  }) async {
    await _ensureLoaded();
    final hour = DateTime.now().hour;
    final suggestions = <AISuggestion>[];

    // Sabah önerileri (06-10)
    if (hour >= 6 && hour < 10) {
      suggestions.addAll(_morningRoutine(childCount));
    }
    // Öğle önerileri (10-14)
    else if (hour >= 10 && hour < 14) {
      suggestions.addAll(_midDayIdeas());
    }
    // Öğleden sonra (14-18)
    else if (hour >= 14 && hour < 18) {
      suggestions.addAll(_afternoonActivities(childCount));
    }
    // Akşam (18-22)
    else if (hour >= 18 && hour < 22) {
      suggestions.addAll(_eveningRoutine());
    }
    // Gece (22-06)
    else {
      suggestions.addAll(_nightWindDown());
    }

    // Her zaman geçerli öneriler
    suggestions.addAll(_alwaysRelevant());

    // Yemek önerisi ekle
    if (_recipes.isNotEmpty) {
      final recipe = _recipes[_rng.nextInt(_recipes.length)];
      suggestions.add(AISuggestion(
        icon: '🍽️',
        title: 'Bugünkü Tarif',
        body: recipe['title'] ?? 'Lezzetli bir yemek',
        category: SuggestionCategory.kitchen,
        action: 'Tarife Bak',
        actionRoute: '/kitchen',
      ));
    }

    // Aktivite önerisi ekle
    if (_activities.isNotEmpty) {
      final act = _activities[_rng.nextInt(_activities.length)];
      final ageGroup = act['age_group'] as Map<String, dynamic>? ?? {};
      suggestions.add(AISuggestion(
        icon: '🎯',
        title: 'Günün Aktivitesi',
        body: '${act['title']} (${ageGroup['min']}-${ageGroup['max']} yaş)',
        category: SuggestionCategory.education,
        action: 'Aktiviteye Bak',
        actionRoute: '/education',
      ));
    }

    suggestions.shuffle(_rng);
    return suggestions.take(6).toList();
  }

  List<AISuggestion> _morningRoutine(int childCount) => [
        AISuggestion(
          icon: '☀️',
          title: 'Günaydın Rutini',
          body: 'Kahvaltıyı birlikte hazırlayın, günün planını paylaşın.',
          category: SuggestionCategory.family,
          action: 'Rutinlere Bak',
          actionRoute: '/routines',
        ),
        if (childCount > 0)
          AISuggestion(
            icon: '🎒',
            title: 'Okul Hazırlığı',
            body: 'Çantaları kontrol edin, ödevleri hatırlatın.',
            category: SuggestionCategory.child,
            action: 'Görevler',
            actionRoute: '/tasks',
          ),
        AISuggestion(
          icon: '💸',
          title: 'Gün Bütçesi',
          body: 'Bugünkü harcama planını gözden geçirin.',
          category: SuggestionCategory.budget,
          action: 'Bütçeye Bak',
          actionRoute: '/budget',
        ),
      ];

  List<AISuggestion> _midDayIdeas() => [
        AISuggestion(
          icon: '🛒',
          title: 'Alışveriş Zamanı',
          body: 'Listenizde 3 ürün eksik. Markete uğrayın.',
          category: SuggestionCategory.shopping,
          action: 'Listeyi Aç',
          actionRoute: '/shopping',
        ),
        AISuggestion(
          icon: '📍',
          title: 'Aile Konumu',
          body: 'Aile üyelerinin konumunu kontrol edin.',
          category: SuggestionCategory.location,
          action: 'Haritayı Aç',
          actionRoute: '/family-map',
        ),
      ];

  List<AISuggestion> _afternoonActivities(int childCount) => [
        if (childCount > 0)
          AISuggestion(
            icon: '🎨',
            title: 'Okul Sonrası',
            body: 'Çocuklarla birlikte yaratıcı bir aktivite yapın.',
            category: SuggestionCategory.education,
            action: 'Aktiviteler',
            actionRoute: '/education',
          ),
        AISuggestion(
          icon: '📸',
          title: 'An Paylaşımı',
          body: 'Bugünkü güzel anları galeriye ekleyin.',
          category: SuggestionCategory.gallery,
          action: 'Galeriyi Aç',
          actionRoute: '/gallery',
        ),
      ];

  List<AISuggestion> _eveningRoutine() => [
        AISuggestion(
          icon: '🍳',
          title: 'Akşam Yemeği',
          body: 'Haftalık yemek planınıza göre bugün ne pişiriyorsunuz?',
          category: SuggestionCategory.kitchen,
          action: 'Mutfak',
          actionRoute: '/kitchen',
        ),
        AISuggestion(
          icon: '💬',
          title: 'Aile Sohbeti',
          body: 'Gün nasıl geçti? Herkesle paylaşın.',
          category: SuggestionCategory.family,
          action: 'Sohbet',
          actionRoute: '/chat',
        ),
        AISuggestion(
          icon: '📊',
          title: 'Günlük Özet',
          body: 'Bugünkü harcamaları kaydedin.',
          category: SuggestionCategory.budget,
          action: 'Bütçe',
          actionRoute: '/budget',
        ),
      ];

  List<AISuggestion> _nightWindDown() => [
        AISuggestion(
          icon: '🌙',
          title: 'Gece Rutini',
          body: 'Yarın için liste hazırlayın, çocukları uyutun.',
          category: SuggestionCategory.family,
          action: 'Rutinler',
          actionRoute: '/routines',
        ),
        AISuggestion(
          icon: '📅',
          title: 'Yarın Planı',
          body: 'Takvime göz atın, yarınki önemli etkinlikler.',
          category: SuggestionCategory.family,
          action: 'Takvim',
          actionRoute: '/calendar',
        ),
      ];

  List<AISuggestion> _alwaysRelevant() => [
        AISuggestion(
          icon: '💊',
          title: 'İlaç Takibi',
          body: 'Aile üyelerinin günlük ilaç alımını kontrol edin.',
          category: SuggestionCategory.health,
          action: 'Sağlık',
          actionRoute: '/family-health',
        ),
        AISuggestion(
          icon: '📱',
          title: 'Abonelikler',
          body: 'Bu ay biten aboneliklerinizi gözden geçirin.',
          category: SuggestionCategory.budget,
          action: 'Abonelikler',
          actionRoute: '/subscriptions',
        ),
      ];

  // ── AKILLI ALIŞVERIŞ ─────────────────────────────────────────────────────

  /// Tarife göre eksik malzemeleri tespit eder
  List<String> getMissingIngredients(
      String recipeName, List<String> availableItems) {
    final recipe = _recipes.firstWhere(
      (r) => (r['title'] as String?)
              ?.toLowerCase()
              .contains(recipeName.toLowerCase()) ==
          true,
      orElse: () => {},
    );
    if (recipe.isEmpty) return [];

    final ingredients = (recipe['ingredients'] as List?)
            ?.map((i) => (i['name'] as String? ?? '').toLowerCase())
            .toList() ??
        [];
    final available =
        availableItems.map((i) => i.toLowerCase()).toSet();
    return ingredients
        .where((ing) =>
            !available.any((a) => a.contains(ing) || ing.contains(a)))
        .toList();
  }

  // ── ÇOCUK GELİŞİMİ ÖNERISI ───────────────────────────────────────────────

  /// Yaşa göre uygun aktivite önerir
  Future<List<Map<String, dynamic>>> getActivitiesForAge(int age,
      {int count = 3}) async {
    await _ensureLoaded();
    final suitable = _activities
        .where((a) {
          final ageGroup =
              a['age_group'] as Map<String, dynamic>? ?? {};
          final min = ageGroup['min'] as int? ?? 0;
          final max = ageGroup['max'] as int? ?? 18;
          return age >= min && age <= max;
        })
        .toList()
      ..shuffle(_rng);
    return suitable.take(count).toList();
  }

  // ── HAFTALIK YEMEK PLANI ─────────────────────────────────────────────────

  /// Rastgele haftalık yemek planı oluşturur
  Future<Map<String, Map<String, dynamic>>> generateWeeklyPlan() async {
    await _ensureLoaded();
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final plan = <String, Map<String, dynamic>>{};
    final pool = List<Map<String, dynamic>>.from(_recipes)..shuffle(_rng);
    for (int i = 0; i < days.length; i++) {
      plan[days[i]] = pool[i % pool.length];
    }
    return plan;
  }

  // ── BÜTÇE ANALİZİ ────────────────────────────────────────────────────────

  /// Harcama kategorilerine göre tavsiye metni üretir (kural tabanlı)
  String getBudgetAdvice({
    required double totalExpense,
    required double budgetLimit,
    required Map<String, double> categorySpending,
  }) {
    final pct = budgetLimit > 0 ? (totalExpense / budgetLimit * 100) : 0;
    if (pct > 90) {
      final topCat = categorySpending.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final cat = topCat.firstOrNull?.key ?? 'harcamalar';
      return '⚠️ Bütçenizin %${pct.toStringAsFixed(0)}\'ini kullandınız. '
          '$cat kategorisinde tasarruf etmeyi düşünün.';
    } else if (pct > 70) {
      return '📊 Bütçenizin %${pct.toStringAsFixed(0)}\'ini kullandınız. '
          'Kalan ${(budgetLimit - totalExpense).toStringAsFixed(0)} ₺ ile hafta sonuna kadar idare edin.';
    } else {
      return '✅ Bütçe kontrolü iyi! '
          'Toplam harcama: ${totalExpense.toStringAsFixed(0)} ₺ (limit: ${budgetLimit.toStringAsFixed(0)} ₺)';
    }
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

enum SuggestionCategory {
  family,
  kitchen,
  education,
  shopping,
  budget,
  gallery,
  child,
  location,
  health,
  chore,
}

class AISuggestion {
  final String icon;
  final String title;
  final String body;
  final SuggestionCategory category;
  final String action;
  final String actionRoute;

  const AISuggestion({
    required this.icon,
    required this.title,
    required this.body,
    required this.category,
    required this.action,
    required this.actionRoute,
  });

  Color get categoryColor {
    return switch (category) {
      SuggestionCategory.family => const Color(0xFF8B5CF6),
      SuggestionCategory.kitchen => const Color(0xFFF97316),
      SuggestionCategory.education => const Color(0xFF6366F1),
      SuggestionCategory.shopping => const Color(0xFF10B981),
      SuggestionCategory.budget => const Color(0xFF3B82F6),
      SuggestionCategory.gallery => const Color(0xFFEC4899),
      SuggestionCategory.child => const Color(0xFFF59E0B),
      SuggestionCategory.location => const Color(0xFF06B6D4),
      SuggestionCategory.health => const Color(0xFF11998E),
      SuggestionCategory.chore => const Color(0xFF667EEA),
    };
  }
}
