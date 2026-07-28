/// Abonelik katmanları ve merkezi feature/limit tanımları.
/// Katman STABLE enum'dur; çevrilmiş plan adı business key OLARAK KULLANILMAZ.
/// Legacy tier (free/premium/family) → yeni katmana idempotent eşlenir.
library;

enum SubscriptionTier { basic, plus, complete }

/// Legacy ve store tier string'lerini yeni katmana çevirir (migration).
/// Bilinmeyen/null → basic (kullanıcı erişimini kaybettirmez, sadece taban).
SubscriptionTier tierFromKey(String? key) {
  switch (key) {
    case 'complete':
    case 'family': // legacy
      return SubscriptionTier.complete;
    case 'plus':
    case 'premium': // legacy
    case 'pro': // legacy
      return SubscriptionTier.plus;
    case 'basic':
    case 'free': // legacy
    default:
      return SubscriptionTier.basic;
  }
}

String tierToKey(SubscriptionTier t) => t.name;

/// İzinli özellikler (dağınık if yerine merkezi allowlist).
enum Feature {
  // Temel (tüm planlarda açık)
  familyCalendar,
  tasks,
  shopping,
  kitchenBasic,
  healthReminders,
  budgetBasic,
  familyIntelligenceBasic,
  // Plus+
  familyIntelligenceAdvanced,
  familyHubAIPlanning,
  kitchenAdvanced,
  budgetReports,
  childDevelopment,
  legalBenefits,
  recurringTasks,
  exportPdf,
  exportCsv,
  // Complete
  familyIntelligenceProactive,
  familyHubAIAdvanced,
  crossModuleAutomation,
  familyRoutines,
  healthDocumentArchive,
  guestAccess,
  advancedRoles,
  prioritySupport,
  earlyAccess,
}

/// Katman başına sayısal limitler.
class PlanLimits {
  final int storageMb;
  final int historyDays; // -1 = sınırsız
  final int aiMonthlyQuota;
  final int guestAccessLimit;

  const PlanLimits({
    required this.storageMb,
    required this.historyDays,
    required this.aiMonthlyQuota,
    required this.guestAccessLimit,
  });
}

/// Merkezi plan kataloğu — limitler ve feature matrisi tek yerde.
class PlanCatalog {
  PlanCatalog._();

  static const limits = <SubscriptionTier, PlanLimits>{
    SubscriptionTier.basic: PlanLimits(
        storageMb: 500, historyDays: 30, aiMonthlyQuota: 20, guestAccessLimit: 0),
    SubscriptionTier.plus: PlanLimits(
        storageMb: 10240, historyDays: 90, aiMonthlyQuota: 200, guestAccessLimit: 0),
    SubscriptionTier.complete: PlanLimits(
        storageMb: 51200, historyDays: -1, aiMonthlyQuota: 1000, guestAccessLimit: 3),
  };

  /// Feature → gereken minimum katman.
  static const _minTier = <Feature, SubscriptionTier>{
    // Temel
    Feature.familyCalendar: SubscriptionTier.basic,
    Feature.tasks: SubscriptionTier.basic,
    Feature.shopping: SubscriptionTier.basic,
    Feature.kitchenBasic: SubscriptionTier.basic,
    Feature.healthReminders: SubscriptionTier.basic,
    Feature.budgetBasic: SubscriptionTier.basic,
    Feature.familyIntelligenceBasic: SubscriptionTier.basic,
    // Plus
    Feature.familyIntelligenceAdvanced: SubscriptionTier.plus,
    Feature.familyHubAIPlanning: SubscriptionTier.plus,
    Feature.kitchenAdvanced: SubscriptionTier.plus,
    Feature.budgetReports: SubscriptionTier.plus,
    Feature.childDevelopment: SubscriptionTier.plus,
    Feature.legalBenefits: SubscriptionTier.plus,
    Feature.recurringTasks: SubscriptionTier.plus,
    Feature.exportPdf: SubscriptionTier.plus,
    Feature.exportCsv: SubscriptionTier.plus,
    // Complete
    Feature.familyIntelligenceProactive: SubscriptionTier.complete,
    Feature.familyHubAIAdvanced: SubscriptionTier.complete,
    Feature.crossModuleAutomation: SubscriptionTier.complete,
    Feature.familyRoutines: SubscriptionTier.complete,
    Feature.healthDocumentArchive: SubscriptionTier.complete,
    Feature.guestAccess: SubscriptionTier.complete,
    Feature.advancedRoles: SubscriptionTier.complete,
    Feature.prioritySupport: SubscriptionTier.complete,
    Feature.earlyAccess: SubscriptionTier.complete,
  };

  static SubscriptionTier minTierFor(Feature f) =>
      _minTier[f] ?? SubscriptionTier.complete;

  /// Katmanın gücü (karşılaştırma için): basic<plus<complete.
  static int rank(SubscriptionTier t) => switch (t) {
        SubscriptionTier.basic => 0,
        SubscriptionTier.plus => 1,
        SubscriptionTier.complete => 2,
      };

  static const pricing = <SubscriptionTier, PlanPricing>{
    SubscriptionTier.basic: PlanPricing(monthly: 0, yearly: 0),
    SubscriptionTier.plus: PlanPricing(
        monthly: 4.99,
        yearly: 39.99,
        monthlyProductId: 'familyhub_plus_monthly',
        yearlyProductId: 'familyhub_plus_yearly'),
    SubscriptionTier.complete: PlanPricing(
        monthly: 7.99,
        yearly: 69.99,
        monthlyProductId: 'familyhub_complete_monthly',
        yearlyProductId: 'familyhub_complete_yearly'),
  };

  static PlanPricing pricingFor(SubscriptionTier t) => pricing[t]!;
}

/// Plan fiyat + store product ID bilgisi (UI fallback fiyatı; asıl kaynak store).
class PlanPricing {
  final double monthly;
  final double yearly;
  final String? monthlyProductId;
  final String? yearlyProductId;

  const PlanPricing({
    required this.monthly,
    required this.yearly,
    this.monthlyProductId,
    this.yearlyProductId,
  });

  bool get isFree => monthly == 0 && yearly == 0;

  /// Yıllık tasarruf oranı (%) — aylık×12 ile yıllık farkı. Hard-coded değil.
  int get yearlySavingsPercent {
    if (monthly == 0) return 0;
    final full = monthly * 12;
    if (full <= 0) return 0;
    return (((full - yearly) / full) * 100).round();
  }
}
