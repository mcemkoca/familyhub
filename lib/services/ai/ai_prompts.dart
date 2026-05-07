import '../../domain/entities.dart';

/// Centralized prompt templates for the AI Engine.
/// All prompts are in Turkish since FamilyHub targets Turkish families.
class AIPrompts {
  AIPrompts._();

  // ── System Prompts ─────────────────────────────────────────────────────

  static const String _hubSystemPrompt =
      'Sen bir aile asistanısın. Adın "FamilyHub AI". '
      'Görevin, aile üyelerinin günlük yaşamını kolaylaştırmak için '
      'akıllı, pratik ve samimi öneriler sunmak. '
      'Her öneri şu alanlardan biri olabilir: etkinlik, görev, bütçe, güvenlik, genel. '
      'Yanıtı her zaman JSON formatında ver. '
      'Öneriler kısa, öz ve uygulanabilir olsun.';

  static const String _safetySystemPrompt =
      'Sen bir aile güvenlik analistisin. '
      'Verilen konum ve zaman bilgilerine göre olası riskleri değerlendir. '
      'Yanıtı JSON formatında ver. '
      'Tehdit seviyesi: low, medium, high. '
      'Öneriler pratik ve uygulanabilir olsun.';

  static const String _budgetSystemPrompt =
      'Sen bir aile bütçe danışmanısın. '
      'Verilen harcama verilerine göre tasarruf önerileri sun. '
      'Yanıtı JSON formatında ver. '
      'Öneriler spesifik ve uygulanabilir olsun.';

  // ── Hub Context Builder ────────────────────────────────────────────────

  /// Builds a rich context prompt from [TodaySummary] data.
  static String buildHubPrompt(TodaySummary data) {
    final buffer = StringBuffer();
    buffer.writeln('Bugün: ${_formatDate(DateTime.now())}');
    buffer.writeln('Yaklaşan etkinlik sayısı: ${data.eventCount}');
    buffer.writeln('Tamamlanmamış görev sayısı: ${data.taskCount}');
    buffer.writeln('Online aile üyeleri: ${data.onlineMembers}/${data.totalMembers}');
    buffer.writeln('Okunmamış mesaj: ${data.unreadMessages}');

    if (data.nextEventTitle != null && data.nextEventTime != null) {
      buffer.writeln('Sonraki etkinlik: ${data.nextEventTitle} (${_formatTime(data.nextEventTime!)})');
    }

    buffer.writeln('\nBu bağlama göre 2-4 akıllı günlük öneri üret.');
    buffer.writeln('Her öneri şu alanlardan biri olabilir: recipe (yemek), chore (ev işi), health, social, finance, event, task, budget, safety, general.');
    buffer.writeln('Tarif önerilerinde malzemeler, hazırlık süresi ve kalori belirt.');
    buffer.writeln('Ev işi önerilerinde tahmini süre, ipuçları ve kim yapacak belirt.');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "unique-id",');
    buffer.writeln('      "type": "recipe|chore|health|social|finance|event|task|budget|safety|general",');
    buffer.writeln('      "title": "Öneri başlığı (max 50 karakter)",');
    buffer.writeln('      "description": "Kısa açıklama (max 120 karakter)",');
    buffer.writeln('      "action": "create_event|create_task|navigate_chat|navigate_calendar|navigate_budget|navigate_safety|navigate_tasks|show_detail",');
    buffer.writeln('      "durationMinutes": 35,');
    buffer.writeln('      "calories": 450,');
    buffer.writeln('      "servings": 4,');
    buffer.writeln('      "difficulty": "Kolay|Orta|Zor",');
    buffer.writeln('      "ingredients": [');
    buffer.writeln('        {"name": "Malzeme adı", "amount": "Miktar", "inStock": true}');
    buffer.writeln('      ],');
    buffer.writeln('      "tips": ["AI ipucu 1", "AI ipucu 2"],');
    buffer.writeln('      "assignedTo": "Anne",');
    buffer.writeln('      "lastDone": "14 gün önce"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// System prompt for hub suggestions.
  static String get hubSystemPrompt => _hubSystemPrompt;

  // ── Safety Analyzer ────────────────────────────────────────────────────

  /// Builds a safety analysis prompt from location and time data.
  static String buildSafetyPrompt({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    String? familyMemberName,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Konum: $latitude, $longitude');
    buffer.writeln('Zaman: ${_formatDateTime(timestamp)}');
    if (familyMemberName != null) {
      buffer.writeln('Aile üyesi: $familyMemberName');
    }
    buffer.writeln('\nGüvenlik analizi yap:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "threatLevel": "low|medium|high",');
    buffer.writeln('  "reason": "Kısa risk değerlendirmesi",');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Öneri başlığı",');
    buffer.writeln('      "description": "Açıklama",');
    buffer.writeln('      "action": "share_location|call_contact|check_in"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  static String get safetySystemPrompt => _safetySystemPrompt;

  // ── Budget Advisor ─────────────────────────────────────────────────────

  /// Builds a budget analysis prompt from spending data.
  static String buildBudgetPrompt({
    required double totalBudget,
    required double spentAmount,
    required Map<String, double> categorySpending,
    required String currency,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Aylık bütçe: $totalBudget $currency');
    buffer.writeln('Harcanan: $spentAmount $currency');
    buffer.writeln('Kalan: ${totalBudget - spentAmount} $currency');
    buffer.writeln('Kategori bazlı harcamalar:');

    categorySpending.forEach((category, amount) {
      final percentage = totalBudget > 0 ? (amount / totalBudget * 100).toStringAsFixed(1) : '0';
      buffer.writeln('  - $category: $amount $currency (%$percentage)');
    });

    buffer.writeln('\nTasarruf ve bütçe yönetimi önerileri sun:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "type": "budget",');
    buffer.writeln('      "title": "Öneri başlığı",');
    buffer.writeln('      "description": "Açıklama",');
    buffer.writeln('      "action": "navigate_budget|add_transaction|set_budget_limit"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  static String get budgetSystemPrompt => _budgetSystemPrompt;

  // ── Family Activity Suggester ──────────────────────────────────────────

  /// Suggests family activities based on weather, season, and preferences.
  static String buildActivityPrompt({
    required String weatherCondition,
    required double temperature,
    required int familySize,
    required List<String> interests,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Hava durumu: $weatherCondition, $temperature°C');
    buffer.writeln('Aile büyüklüğü: $familySize kişi');
    buffer.writeln('İlgi alanları: ${interests.join(", ")}');
    buffer.writeln('\nAile için aktivite önerileri sun:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "type": "event",');
    buffer.writeln('      "title": "Aktivite adı",');
    buffer.writeln('      "description": "Kısa açıklama",');
    buffer.writeln('      "estimatedCost": "Düşük|Orta|Yüksek",');
    buffer.writeln('      "duration": "Kaç saat süreceği",');
    buffer.writeln('      "action": "create_event"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  // ── Health & Wellness ──────────────────────────────────────────────────

  static const String _healthSystemPrompt =
      'Sen bir aile sağlık danışmanısın. '
      'Aile üyelerinin yaş gruplarına ve aktivite seviyelerine uygun sağlık önerileri sun. '
      'Yanıtı JSON formatında ver. '
      'Öneriler pratik, bilimsel ve uygulanabilir olsun.';

  static String buildHealthPrompt({
    required int familySize,
    required List<String> ageGroups, // e.g. ["adult", "child", "elder"]
    required List<String> healthGoals, // e.g. ["hydration", "exercise", "sleep"]
    String? weatherCondition,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Aile büyüklüğü: $familySize kişi');
    buffer.writeln('Yaş grupları: ${ageGroups.join(", ")}');
    buffer.writeln('Sağlık hedefleri: ${healthGoals.join(", ")}');
    if (weatherCondition != null) {
      buffer.writeln('Hava durumu: $weatherCondition');
    }
    buffer.writeln('\nGünlük sağlık ve wellness önerisi üret:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "unique-id",');
    buffer.writeln('      "type": "health",');
    buffer.writeln('      "category": "hydration|exercise|sleep|nutrition|mental",');
    buffer.writeln('      "title": "Öneri başlığı",');
    buffer.writeln('      "description": "Kısa açıklama",');
    buffer.writeln('      "action": "navigate_health|create_event",');
    buffer.writeln('      "durationMinutes": 15,');
    buffer.writeln('      "difficulty": "Kolay|Orta|Zor",');
    buffer.writeln('      "tips": ["AI ipucu 1"],');
    buffer.writeln('      "steps": ["Adım 1", "Adım 2"],');
    buffer.writeln('      "assignedTo": "Tüm Aile",');
    buffer.writeln('      "estimatedCost": "Düşük",');
    buffer.writeln('      "badge": "Yeni"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String get healthSystemPrompt => _healthSystemPrompt;

  // ── Education & Development ─────────────────────────────────────────────

  static const String _educationSystemPrompt =
      'Sen bir eğitim koçusun. '
      'Aile içi öğrenme aktiviteleri, okuma önerileri ve gelişim hedefleri sun. '
      'Yanıtı JSON formatında ver. '
      'Öneriler yaşa uygun ve eğlenceli olsun.';

  static String buildEducationPrompt({
    required List<String> ageGroups,
    required List<String> interests,
    required String familySize,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Yaş grupları: ${ageGroups.join(", ")}');
    buffer.writeln('İlgi alanları: ${interests.join(", ")}');
    buffer.writeln('Aile büyüklüğü: $familySize');
    buffer.writeln('\nEğitim ve gelişim önerisi üret:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "unique-id",');
    buffer.writeln('      "type": "education",');
    buffer.writeln('      "category": "reading|activity|online_course|skill",');
    buffer.writeln('      "title": "Öneri başlığı",');
    buffer.writeln('      "description": "Kısa açıklama",');
    buffer.writeln('      "action": "create_event|show_detail",');
    buffer.writeln('      "durationMinutes": 30,');
    buffer.writeln('      "difficulty": "Kolay|Orta|Zor",');
    buffer.writeln('      "tips": ["AI ipucu 1"],');
    buffer.writeln('      "steps": ["Adım 1", "Adım 2"],');
    buffer.writeln('      "assignedTo": "Çocuklar",');
    buffer.writeln('      "estimatedCost": "Düşük",');
    buffer.writeln('      "badge": "Trend"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String get educationSystemPrompt => _educationSystemPrompt;

  // ── Finance & Budget ────────────────────────────────────────────────────

  static const String _financeSystemPrompt =
      'Sen bir aile finans danışmanısın. '
      'Günlük bütçe ipuçları, tasarruf önerileri ve akıllı harcama stratejileri sun. '
      'Yanıtı JSON formatında ver. '
      'Öneriler spesifik ve uygulanabilir olsun.';

  static String buildFinancePrompt({
    required double monthlyBudget,
    required double spentSoFar,
    required String currency,
    required List<String> spendingCategories,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Aylık bütçe: $monthlyBudget $currency');
    buffer.writeln('Harcanan: $spentSoFar $currency');
    buffer.writeln('Kalan: ${monthlyBudget - spentSoFar} $currency');
    buffer.writeln('Harcama kategorileri: ${spendingCategories.join(", ")}');
    buffer.writeln('\nGünlük finans önerisi üret:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "unique-id",');
    buffer.writeln('      "type": "finance",');
    buffer.writeln('      "category": "budget_tip|saving|opportunity|expense_review",');
    buffer.writeln('      "title": "Öneri başlığı",');
    buffer.writeln('      "description": "Kısa açıklama",');
    buffer.writeln('      "action": "navigate_budget|show_detail",');
    buffer.writeln('      "durationMinutes": 15,');
    buffer.writeln('      "difficulty": "Kolay",');
    buffer.writeln('      "tips": ["AI ipucu 1"],');
    buffer.writeln('      "steps": ["Adım 1", "Adım 2"],');
    buffer.writeln('      "assignedTo": "Baba",');
    buffer.writeln('      "estimatedCost": "Düşük",');
    buffer.writeln('      "badge": "Zaman Tasarrufu"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String get financeSystemPrompt => _financeSystemPrompt;

  // ── Social & Activities ─────────────────────────────────────────────────

  static const String _socialSystemPrompt =
      'Sen bir aile aktivite planlayıcısısın. '
      'Hava durumu, mevsim ve aile tercihlerine göre sosyal etkinlik önerileri sun. '
      'Yanıtı JSON formatında ver. '
      'Öneriler eğlenceli, bağ kurucu ve uygulanabilir olsun.';

  static String buildSocialPrompt({
    required String weatherCondition,
    required double temperature,
    required int familySize,
    required List<String> interests,
    required List<String> upcomingOccasions,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Hava durumu: $weatherCondition, $temperature°C');
    buffer.writeln('Aile büyüklüğü: $familySize kişi');
    buffer.writeln('İlgi alanları: ${interests.join(", ")}');
    buffer.writeln('Yaklaşan özel günler: ${upcomingOccasions.join(", ")}');
    buffer.writeln('\nSosyal etkinlik önerisi üret:');
    buffer.writeln('JSON formatında yanıt ver:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "unique-id",');
    buffer.writeln('      "type": "social",');
    buffer.writeln('      "category": "activity|outing|celebration|visit",');
    buffer.writeln('      "title": "Etkinlik adı",');
    buffer.writeln('      "description": "Kısa açıklama",');
    buffer.writeln('      "action": "create_event|show_detail",');
    buffer.writeln('      "durationMinutes": 90,');
    buffer.writeln('      "difficulty": "Kolay",');
    buffer.writeln('      "tips": ["AI ipucu 1"],');
    buffer.writeln('      "steps": ["Adım 1", "Adım 2"],');
    buffer.writeln('      "assignedTo": "Tüm Aile",');
    buffer.writeln('      "estimatedCost": "Düşük|Orta|Yüksek",');
    buffer.writeln('      "weatherContext": "$weatherCondition",');
    buffer.writeln('      "badge": "Aile Favorisi"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String get socialSystemPrompt => _socialSystemPrompt;

  // ── Helpers ────────────────────────────────────────────────────────────

  static String _formatDate(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${_formatTime(dt)}';
  }
}
