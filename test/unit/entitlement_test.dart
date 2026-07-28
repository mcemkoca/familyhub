import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/subscription/domain/subscription_tier.dart';
import 'package:familyhub/features/subscription/application/entitlement_service.dart';

void main() {
  group('Legacy tier migration', () {
    test('free→basic, premium→plus, family→complete', () {
      expect(tierFromKey('free'), SubscriptionTier.basic);
      expect(tierFromKey('premium'), SubscriptionTier.plus);
      expect(tierFromKey('pro'), SubscriptionTier.plus);
      expect(tierFromKey('family'), SubscriptionTier.complete);
    });
    test('yeni anahtarlar', () {
      expect(tierFromKey('basic'), SubscriptionTier.basic);
      expect(tierFromKey('plus'), SubscriptionTier.plus);
      expect(tierFromKey('complete'), SubscriptionTier.complete);
    });
    test('bilinmeyen/null → basic (erişim kaybı yok)', () {
      expect(tierFromKey(null), SubscriptionTier.basic);
      expect(tierFromKey('xyz'), SubscriptionTier.basic);
    });
    test('idempotent: tierToKey→tierFromKey', () {
      for (final t in SubscriptionTier.values) {
        expect(tierFromKey(tierToKey(t)), t);
      }
    });
  });

  group('EntitlementService feature matrisi', () {
    const basic = EntitlementService(SubscriptionTier.basic);
    const plus = EntitlementService(SubscriptionTier.plus);
    const complete = EntitlementService(SubscriptionTier.complete);

    test('temel özellikler tüm katmanlarda açık', () {
      for (final e in [basic, plus, complete]) {
        expect(e.canUse(Feature.familyCalendar), true);
        expect(e.canUse(Feature.shopping), true);
        expect(e.canUse(Feature.healthReminders), true);
        expect(e.canUse(Feature.familyIntelligenceBasic), true);
      }
    });

    test('Plus özellikleri basic\'te kilitli, plus+ açık', () {
      expect(basic.canUse(Feature.legalBenefits), false);
      expect(basic.canUse(Feature.childDevelopment), false);
      expect(plus.canUse(Feature.legalBenefits), true);
      expect(complete.canUse(Feature.legalBenefits), true);
    });

    test('Complete özellikleri sadece complete\'te açık', () {
      expect(basic.canUse(Feature.familyRoutines), false);
      expect(plus.canUse(Feature.familyRoutines), false);
      expect(complete.canUse(Feature.familyRoutines), true);
      expect(complete.canUse(Feature.guestAccess), true);
      expect(plus.canUse(Feature.guestAccess), false);
    });

    test('requiresUpgrade doğru minimum katmanı verir', () {
      expect(basic.requiresUpgrade(Feature.legalBenefits), SubscriptionTier.plus);
      expect(basic.requiresUpgrade(Feature.familyRoutines),
          SubscriptionTier.complete);
      expect(plus.requiresUpgrade(Feature.familyRoutines),
          SubscriptionTier.complete);
      expect(plus.requiresUpgrade(Feature.legalBenefits), null); // zaten açık
      expect(complete.requiresUpgrade(Feature.guestAccess), null);
    });
  });

  group('Plan limitleri', () {
    test('depolama artışı basic<plus<complete', () {
      expect(const EntitlementService(SubscriptionTier.basic).storageMb, 500);
      expect(const EntitlementService(SubscriptionTier.plus).storageMb, 10240);
      expect(
          const EntitlementService(SubscriptionTier.complete).storageMb, 51200);
    });
    test('complete geçmiş sınırsız', () {
      expect(
          const EntitlementService(SubscriptionTier.complete).isUnlimitedHistory,
          true);
      expect(const EntitlementService(SubscriptionTier.plus).historyDays, 90);
    });
    test('AI kotası katmanla artar', () {
      expect(const EntitlementService(SubscriptionTier.basic).aiMonthlyQuota, 20);
      expect(
          const EntitlementService(SubscriptionTier.complete).aiMonthlyQuota >
              const EntitlementService(SubscriptionTier.basic).aiMonthlyQuota,
          true);
    });
    test('misafir erişimi sadece complete', () {
      expect(
          const EntitlementService(SubscriptionTier.basic).guestAccessLimit, 0);
      expect(
          const EntitlementService(SubscriptionTier.complete).guestAccessLimit >
              0,
          true);
    });
  });
}
