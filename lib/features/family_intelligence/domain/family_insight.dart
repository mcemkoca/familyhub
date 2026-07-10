/// Aile Zekası içgörü modeli — kural tabanlı motor tarafından üretilir.
/// Tür/öncelik/kaynak STABLE enum'dur; başlık/açıklama argümanlarla lokalize
/// edilir. AI olmadan da çalışır (deterministik). "Neden gösterildi" alanı zorunlu.
library;

enum InsightType {
  reminder,
  warning,
  recommendation,
  summary,
  achievement,
  planning,
}

/// Kaynak modül (yönlendirme + "neden" için).
enum InsightModule {
  tasks,
  calendar,
  shopping,
  budget,
  health,
  kitchen,
  legalBenefit,
  general,
}

/// Öncelik — P0 kritik … P3 bilgilendirme.
enum InsightPriority { critical, high, normal, info }

/// Tek bir içgörü. [titleKey]/[bodyKey] localization anahtarlarıdır; [args]
/// placeholder değerleridir (çeviri metni business key olarak KULLANILMAZ).
class FamilyInsight {
  final String id;
  final InsightType type;
  final InsightModule module;
  final InsightPriority priority;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> args;

  /// "Neden gösterildi?" — kullanıcıya açıklanabilirlik (localization key).
  final String reasonKey;

  /// Aksiyon route'u (tıklanınca gidilecek). null → aksiyon yok.
  final String? actionRoute;

  const FamilyInsight({
    required this.id,
    required this.type,
    required this.module,
    required this.priority,
    required this.titleKey,
    required this.bodyKey,
    this.args = const {},
    required this.reasonKey,
    this.actionRoute,
  });

  /// Öncelik skoru (sıralama için) — düşük = daha önemli.
  int get priorityScore => switch (priority) {
        InsightPriority.critical => 0,
        InsightPriority.high => 1,
        InsightPriority.normal => 2,
        InsightPriority.info => 3,
      };
}
