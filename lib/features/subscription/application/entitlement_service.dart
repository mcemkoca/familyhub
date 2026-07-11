import '../domain/subscription_tier.dart';

/// Merkezi yetki çözümleme — modüller kendi içinde plan adı KONTROL ETMEZ.
/// Kullanım: EntitlementService(tier).canUse(Feature.x) / getLimit / requiresUpgrade.
class EntitlementService {
  final SubscriptionTier tier;
  const EntitlementService(this.tier);

  /// Legacy/store tier string'inden oluşturur (migration güvenli).
  factory EntitlementService.fromKey(String? tierKey) =>
      EntitlementService(tierFromKey(tierKey));

  /// Özellik bu katmanda kullanılabilir mi?
  bool canUse(Feature f) =>
      PlanCatalog.rank(tier) >= PlanCatalog.rank(PlanCatalog.minTierFor(f));

  /// Özellik kilitliyse hangi katmana yükseltmek gerekir? (yoksa null)
  SubscriptionTier? requiresUpgrade(Feature f) {
    final min = PlanCatalog.minTierFor(f);
    return canUse(f) ? null : min;
  }

  PlanLimits get limits => PlanCatalog.limits[tier]!;

  int get storageMb => limits.storageMb;
  int get historyDays => limits.historyDays; // -1 sınırsız
  int get aiMonthlyQuota => limits.aiMonthlyQuota;
  int get guestAccessLimit => limits.guestAccessLimit;

  bool get isUnlimitedHistory => limits.historyDays < 0;
}
