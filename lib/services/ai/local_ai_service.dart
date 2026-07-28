import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../core/app_logger.dart';
import '../localization/locale_service.dart';

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

  String _text(Map<String, String> values) {
    final code = LocaleService.resolveInitialLocale().languageCode;
    return values[code] ?? values['tr']!;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final recipeRaw =
          await rootBundle.loadString('assets/data/content/recipes.json');
      _recipes = (jsonDecode(recipeRaw) as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      // Asset eksik/bozuksa yerel AI sessizce boş döner — bu bir paketleme
      // hatasıdır, kullanıcı hatası değil. Görünür olmalı.
      AppLogger.logError(
        e,
        module: 'ai',
        operation: 'loadRecipesAsset',
        stackTrace: st,
      );
    }
    try {
      final eduRaw =
          await rootBundle.loadString('assets/data/content/education.json');
      _activities = (jsonDecode(eduRaw) as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      AppLogger.logError(
        e,
        module: 'ai',
        operation: 'loadEducationAsset',
        stackTrace: st,
      );
    }
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
        title: _text(const {'tr': 'Bugünkü Tarif', 'en': "Today’s Recipe", 'nl': 'Recept van vandaag', 'fr': 'Recette du jour'}),
        body: (recipe['title'] ?? _text(const {'tr': 'Lezzetli bir yemek', 'en': 'A delicious meal', 'nl': 'Een heerlijke maaltijd', 'fr': 'Un délicieux repas'})).toString(),
        category: SuggestionCategory.kitchen,
        action: _text(const {'tr': 'Tarife Bak', 'en': 'View Recipe', 'nl': 'Bekijk recept', 'fr': 'Voir la recette'}),
        actionRoute: '/kitchen',
      ));
    }

    // Aktivite önerisi ekle
    if (_activities.isNotEmpty) {
      final act = _activities[_rng.nextInt(_activities.length)];
      final ageGroup = act['age_group'] as Map<String, dynamic>? ?? {};
      suggestions.add(AISuggestion(
        icon: '🎯',
        title: _text(const {'tr': 'Günün Aktivitesi', 'en': 'Activity of the Day', 'nl': 'Activiteit van de dag', 'fr': 'Activité du jour'}),
        body: '${act['title']} (${ageGroup['min']}-${ageGroup['max']} ${_text(const {'tr': 'yaş', 'en': 'years', 'nl': 'jaar', 'fr': 'ans'})})',
        category: SuggestionCategory.education,
        action: _text(const {'tr': 'Aktiviteye Bak', 'en': 'View Activity', 'nl': 'Bekijk activiteit', 'fr': "Voir l’activité"}),
        actionRoute: '/education',
      ));
    }

    suggestions.shuffle(_rng);
    return suggestions.take(6).toList();
  }

  List<AISuggestion> _morningRoutine(int childCount) => [
        AISuggestion(
          icon: '☀️',
          title: _text(const {'tr': 'Günaydın Rutini', 'en': 'Good Morning Routine', 'nl': 'Goedemorgenroutine', 'fr': 'Routine du matin'}),
          body: _text(const {'tr': 'Kahvaltıyı birlikte hazırlayın, günün planını paylaşın.', 'en': 'Prepare breakfast together and share the plan for the day.', 'nl': 'Maak samen het ontbijt en bespreek de planning van de dag.', 'fr': 'Préparez le petit-déjeuner ensemble et partagez le programme du jour.'}),
          category: SuggestionCategory.family,
          action: _text(const {'tr': 'Rutinlere Bak', 'en': 'View Routines', 'nl': 'Bekijk routines', 'fr': 'Voir les routines'}),
          actionRoute: '/routines',
        ),
        if (childCount > 0)
          AISuggestion(
            icon: '🎒',
            title: _text(const {'tr': 'Okul Hazırlığı', 'en': 'School Preparation', 'nl': 'Voorbereiding op school', 'fr': "Préparation pour l’école"}),
            body: _text(const {'tr': 'Çantaları kontrol edin, ödevleri hatırlatın.', 'en': 'Check the bags and remind everyone about homework.', 'nl': 'Controleer de tassen en herinner iedereen aan het huiswerk.', 'fr': 'Vérifiez les sacs et rappelez les devoirs à chacun.'}),
            category: SuggestionCategory.child,
            action: _text(const {'tr': 'Görevler', 'en': 'Tasks', 'nl': 'Taken', 'fr': 'Tâches'}),
            actionRoute: '/tasks',
          ),
        AISuggestion(
          icon: '💸',
          title: _text(const {'tr': 'Gün Bütçesi', 'en': 'Daily Budget', 'nl': 'Dagbudget', 'fr': 'Budget du jour'}),
          body: _text(const {'tr': 'Bugünkü harcama planını gözden geçirin.', 'en': "Review today’s spending plan.", 'nl': 'Bekijk het uitgavenplan van vandaag.', 'fr': 'Passez en revue le budget prévu pour aujourd’hui.'}),
          category: SuggestionCategory.budget,
          action: _text(const {'tr': 'Bütçeye Bak', 'en': 'View Budget', 'nl': 'Bekijk budget', 'fr': 'Voir le budget'}),
          actionRoute: '/budget',
        ),
      ];

  List<AISuggestion> _midDayIdeas() => [
        AISuggestion(
          icon: '🛒',
          title: _text(const {'tr': 'Alışveriş Zamanı', 'en': 'Shopping Time', 'nl': 'Tijd om boodschappen te doen', 'fr': 'À vos courses'}),
          body: _text(const {'tr': 'Listenizde 3 ürün eksik. Markete uğrayın.', 'en': 'Three items are missing from your list. Stop by the store.', 'nl': 'Er ontbreken drie producten op je lijst. Ga even langs de winkel.', 'fr': 'Il manque trois articles à votre liste. Passez au magasin.'}),
          category: SuggestionCategory.shopping,
          action: _text(const {'tr': 'Listeyi Aç', 'en': 'Open List', 'nl': 'Open lijst', 'fr': 'Ouvrir la liste'}),
          actionRoute: '/shopping',
        ),
        AISuggestion(
          icon: '📍',
          title: _text(const {'tr': 'Aile Konumu', 'en': 'Family Location', 'nl': 'Gezinslocatie', 'fr': 'Localisation de la famille'}),
          body: _text(const {'tr': 'Aile üyelerinin konumunu kontrol edin.', 'en': 'Check the location of family members.', 'nl': 'Bekijk de locatie van gezinsleden.', 'fr': 'Vérifiez la localisation des membres de la famille.'}),
          category: SuggestionCategory.location,
          action: _text(const {'tr': 'Haritayı Aç', 'en': 'Open Map', 'nl': 'Open kaart', 'fr': 'Ouvrir la carte'}),
          actionRoute: '/family-map',
        ),
      ];

  List<AISuggestion> _afternoonActivities(int childCount) => [
        if (childCount > 0)
          AISuggestion(
            icon: '🎨',
            title: _text(const {'tr': 'Okul Sonrası', 'en': 'After School', 'nl': 'Na school', 'fr': "Après l’école"}),
            body: _text(const {'tr': 'Çocuklarla birlikte yaratıcı bir aktivite yapın.', 'en': 'Do a creative activity with the children.', 'nl': 'Doe een creatieve activiteit met de kinderen.', 'fr': 'Faites une activité créative avec les enfants.'}),
            category: SuggestionCategory.education,
            action: _text(const {'tr': 'Aktiviteler', 'en': 'Activities', 'nl': 'Activiteiten', 'fr': 'Activités'}),
            actionRoute: '/education',
          ),
        AISuggestion(
          icon: '📸',
          title: _text(const {'tr': 'An Paylaşımı', 'en': 'Share a Moment', 'nl': 'Deel een moment', 'fr': 'Partager un moment'}),
          body: _text(const {'tr': 'Bugünkü güzel anları galeriye ekleyin.', 'en': "Add today’s lovely moments to the gallery.", 'nl': 'Voeg de mooie momenten van vandaag toe aan de galerij.', 'fr': 'Ajoutez les beaux moments de la journée à la galerie.'}),
          category: SuggestionCategory.gallery,
          action: _text(const {'tr': 'Galeriyi Aç', 'en': 'Open Gallery', 'nl': 'Open galerij', 'fr': 'Ouvrir la galerie'}),
          actionRoute: '/gallery',
        ),
      ];

  List<AISuggestion> _eveningRoutine() => [
        AISuggestion(
          icon: '🍳',
          title: _text(const {'tr': 'Akşam Yemeği', 'en': 'Dinner', 'nl': 'Avondeten', 'fr': 'Dîner'}),
          body: _text(const {'tr': 'Haftalık yemek planınıza göre bugün ne pişiriyorsunuz?', 'en': 'What are you cooking today based on your weekly meal plan?', 'nl': 'Wat kook je vandaag volgens je wekelijkse maaltijdplan?', 'fr': 'Que cuisinez-vous aujourd’hui selon votre menu de la semaine ?'}),
          category: SuggestionCategory.kitchen,
          action: _text(const {'tr': 'Mutfak', 'en': 'Kitchen', 'nl': 'Keuken', 'fr': 'Cuisine'}),
          actionRoute: '/kitchen',
        ),
        AISuggestion(
          icon: '💬',
          title: _text(const {'tr': 'Aile Sohbeti', 'en': 'Family Chat', 'nl': 'Gezinsgesprek', 'fr': 'Discussion en famille'}),
          body: _text(const {'tr': 'Gün nasıl geçti? Herkesle paylaşın.', 'en': 'How was your day? Share it with everyone.', 'nl': 'Hoe was je dag? Deel het met iedereen.', 'fr': 'Comment s’est passée votre journée ? Partagez-la avec tout le monde.'}),
          category: SuggestionCategory.family,
          action: _text(const {'tr': 'Sohbet', 'en': 'Chat', 'nl': 'Gesprek', 'fr': 'Discussion'}),
          actionRoute: '/chat',
        ),
        AISuggestion(
          icon: '📊',
          title: _text(const {'tr': 'Günlük Özet', 'en': 'Daily Summary', 'nl': 'Dagoverzicht', 'fr': 'Résumé du jour'}),
          body: _text(const {'tr': 'Bugünkü harcamaları kaydedin.', 'en': "Record today’s expenses.", 'nl': 'Registreer de uitgaven van vandaag.', 'fr': 'Enregistrez les dépenses du jour.'}),
          category: SuggestionCategory.budget,
          action: _text(const {'tr': 'Bütçe', 'en': 'Budget', 'nl': 'Budget', 'fr': 'Budget'}),
          actionRoute: '/budget',
        ),
      ];

  List<AISuggestion> _nightWindDown() => [
        AISuggestion(
          icon: '🌙',
          title: _text(const {'tr': 'Gece Rutini', 'en': 'Night Routine', 'nl': 'Avondroutine', 'fr': 'Routine du soir'}),
          body: _text(const {'tr': 'Yarın için liste hazırlayın, çocukları uyutun.', 'en': 'Prepare a list for tomorrow and put the children to bed.', 'nl': 'Maak een lijst voor morgen en breng de kinderen naar bed.', 'fr': 'Préparez une liste pour demain et couchez les enfants.'}),
          category: SuggestionCategory.family,
          action: _text(const {'tr': 'Rutinler', 'en': 'Routines', 'nl': 'Routines', 'fr': 'Routines'}),
          actionRoute: '/routines',
        ),
        AISuggestion(
          icon: '📅',
          title: _text(const {'tr': 'Yarın Planı', 'en': "Tomorrow’s Plan", 'nl': 'Planning voor morgen', 'fr': 'Programme de demain'}),
          body: _text(const {'tr': 'Takvime göz atın, yarınki önemli etkinlikler.', 'en': "Check the calendar for tomorrow’s important events.", 'nl': 'Bekijk de belangrijke afspraken van morgen in de agenda.', 'fr': 'Consultez le calendrier pour les événements importants de demain.'}),
          category: SuggestionCategory.family,
          action: _text(const {'tr': 'Takvim', 'en': 'Calendar', 'nl': 'Agenda', 'fr': 'Calendrier'}),
          actionRoute: '/calendar',
        ),
      ];

  List<AISuggestion> _alwaysRelevant() => [
        AISuggestion(
          icon: '💊',
          title: _text(const {'tr': 'İlaç Takibi', 'en': 'Medication Tracking', 'nl': 'Medicatie bijhouden', 'fr': 'Suivi des médicaments'}),
          body: _text(const {'tr': 'Aile üyelerinin günlük ilaç alımını kontrol edin.', 'en': 'Check the daily medication of family members.', 'nl': 'Controleer de dagelijkse medicatie van gezinsleden.', 'fr': 'Vérifiez la prise quotidienne de médicaments des membres de la famille.'}),
          category: SuggestionCategory.health,
          action: _text(const {'tr': 'Sağlık', 'en': 'Health', 'nl': 'Gezondheid', 'fr': 'Santé'}),
          actionRoute: '/family-health',
        ),
        AISuggestion(
          icon: '📱',
          title: _text(const {'tr': 'Abonelikler', 'en': 'Subscriptions', 'nl': 'Abonnementen', 'fr': 'Abonnements'}),
          body: _text(const {'tr': 'Bu ay biten aboneliklerinizi gözden geçirin.', 'en': 'Review subscriptions ending this month.', 'nl': 'Bekijk de abonnementen die deze maand aflopen.', 'fr': 'Vérifiez les abonnements qui se terminent ce mois-ci.'}),
          category: SuggestionCategory.budget,
          action: _text(const {'tr': 'Abonelikler', 'en': 'Subscriptions', 'nl': 'Abonnementen', 'fr': 'Abonnements'}),
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
            ?.map((i) => ((i as Map?)?['name'] as String? ?? '').toLowerCase())
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
      final cat = topCat.firstOrNull?.key ?? _text(const {'tr': 'harcamalar', 'en': 'spending', 'nl': 'uitgaven', 'fr': 'dépenses'});
      return _text({
        'tr': '⚠️ Bütçenizin %${pct.toStringAsFixed(0)}\'ini kullandınız. $cat kategorisinde tasarruf etmeyi düşünün.',
        'en': '⚠️ You have used ${pct.toStringAsFixed(0)}% of your budget. Consider saving in the $cat category.',
        'nl': '⚠️ Je hebt ${pct.toStringAsFixed(0)}% van je budget gebruikt. Overweeg te besparen in de categorie $cat.',
        'fr': '⚠️ Vous avez utilisé ${pct.toStringAsFixed(0)} % de votre budget. Pensez à économiser dans la catégorie $cat.',
      });
    } else if (pct > 70) {
      final remaining = (budgetLimit - totalExpense).toStringAsFixed(0);
      return _text({
        'tr': '📊 Bütçenizin %${pct.toStringAsFixed(0)}\'ini kullandınız. Kalan $remaining € ile hafta sonuna kadar idare edin.',
        'en': '📊 You have used ${pct.toStringAsFixed(0)}% of your budget. Make the remaining €$remaining last until the weekend.',
        'nl': '📊 Je hebt ${pct.toStringAsFixed(0)}% van je budget gebruikt. Probeer met de resterende €$remaining het weekend te halen.',
        'fr': '📊 Vous avez utilisé ${pct.toStringAsFixed(0)} % de votre budget. Tenez jusqu’au week-end avec les $remaining € restants.',
      });
    } else {
      return _text({
        'tr': '✅ Bütçe kontrolü iyi! Toplam harcama: ${totalExpense.toStringAsFixed(0)} € (limit: ${budgetLimit.toStringAsFixed(0)} €)',
        'en': '✅ Your budget is under control! Total spending: €${totalExpense.toStringAsFixed(0)} (limit: €${budgetLimit.toStringAsFixed(0)})',
        'nl': '✅ Je budget is onder controle! Totale uitgaven: €${totalExpense.toStringAsFixed(0)} (limiet: €${budgetLimit.toStringAsFixed(0)})',
        'fr': '✅ Votre budget est bien maîtrisé ! Dépenses totales : ${totalExpense.toStringAsFixed(0)} € (limite : ${budgetLimit.toStringAsFixed(0)} €)',
      });
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
