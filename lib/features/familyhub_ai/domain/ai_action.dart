/// FamilyHub AI aksiyon modeli ve güvenlik politikası.
/// AI serbest kod/işlem çalıştırmaz — yalnızca ALLOWLIST edilmiş aksiyon
/// türlerini üretebilir. Her aksiyonun risk seviyesi ve onay politikası vardır.
library;

/// İzin verilen aksiyon türleri (allowlist). Bunun dışında hiçbir tür çalışmaz.
enum AIActionType {
  openModule, // bir modülü aç (LOW)
  openEntity, // bir kayda git (LOW)
  createTask, // görev taslağı (HIGH — onay)
  createReminder, // hatırlatma (HIGH — onay)
  createCalendarEvent, // takvim etkinliği (HIGH — onay)
  addShoppingItems, // listeye ürün (MEDIUM — onay)
  summarizeBudget, // özet göster (LOW)
  openLegalBenefit, // resmî kaynak (LOW)
}

/// Risk seviyesi — onay politikasını belirler.
enum AIRiskLevel { low, medium, high, critical }

class AIAction {
  final AIActionType type;
  final String? route; // openModule/openEntity için
  final Map<String, Object?> payload;

  const AIAction({required this.type, this.route, this.payload = const {}});

  AIRiskLevel get risk => AIActionPolicy.riskFor(type);

  /// Kullanıcı onayı gerekli mi? (medium/high/critical → evet)
  bool get requiresConfirmation =>
      risk == AIRiskLevel.medium ||
      risk == AIRiskLevel.high ||
      risk == AIRiskLevel.critical;
}

/// Merkezi güvenlik politikası — risk sınıflandırma + payload doğrulama.
class AIActionPolicy {
  AIActionPolicy._();

  static AIRiskLevel riskFor(AIActionType type) => switch (type) {
        AIActionType.openModule => AIRiskLevel.low,
        AIActionType.openEntity => AIRiskLevel.low,
        AIActionType.summarizeBudget => AIRiskLevel.low,
        AIActionType.openLegalBenefit => AIRiskLevel.low,
        AIActionType.addShoppingItems => AIRiskLevel.medium,
        AIActionType.createTask => AIRiskLevel.high,
        AIActionType.createReminder => AIRiskLevel.high,
        AIActionType.createCalendarEvent => AIRiskLevel.high,
      };

  /// Aksiyon şeması geçerli mi? Bozuk/eksik payload reddedilir (fail-safe).
  static bool isValid(AIAction a) {
    switch (a.type) {
      case AIActionType.openModule:
      case AIActionType.openEntity:
        return a.route != null && a.route!.startsWith('/');
      case AIActionType.openLegalBenefit:
        final url = a.payload['url'];
        return url is String && url.startsWith('https://');
      case AIActionType.addShoppingItems:
        final items = a.payload['items'];
        return items is List && items.isNotEmpty && items.length <= 50;
      case AIActionType.createTask:
      case AIActionType.createReminder:
        final title = a.payload['title'];
        return title is String && title.trim().isNotEmpty;
      case AIActionType.createCalendarEvent:
        final title = a.payload['title'];
        final date = a.payload['date'];
        return title is String && title.trim().isNotEmpty && date is String;
      case AIActionType.summarizeBudget:
        return true;
    }
  }

  /// Serbest metin AI çıktısından gelen tür adını güvenli enum'a çözer.
  /// Bilinmeyen/izinsiz tür → null (aksiyon üretilmez).
  static AIActionType? typeFromKey(String? key) {
    for (final t in AIActionType.values) {
      if (t.name == key) return t;
    }
    return null;
  }
}
