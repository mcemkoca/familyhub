import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/subscription/domain/subscription_tier.dart';
import 'package:familyhub/features/subscription/application/entitlement_service.dart';

void main() {
  group('PlanPricing', () {
    test('basic ücretsizdir', () {
      final p = PlanCatalog.pricingFor(SubscriptionTier.basic);
      expect(p.isFree, isTrue);
      expect(p.yearlySavingsPercent, 0);
    });

    test('plus yıllık tasarrufu doğru hesaplanır (hard-coded değil)', () {
      final p = PlanCatalog.pricingFor(SubscriptionTier.plus);
      // 4.99*12=59.88, yıllık 39.99 → ~%33
      expect(p.yearlySavingsPercent, 33);
      expect(p.monthlyProductId, 'familyhub_plus_monthly');
    });

    test('complete yıllık tasarrufu hesaplanır', () {
      final p = PlanCatalog.pricingFor(SubscriptionTier.complete);
      // 7.99*12=95.88, yıllık 69.99 → ~%27
      expect(p.yearlySavingsPercent, 27);
    });
  });

  group('FeatureGate mantığı (entitlement)', () {
    test('basic kullanıcı Plus özelliği kullanamaz, plus gerekir', () {
      const ent = EntitlementService(SubscriptionTier.basic);
      expect(ent.canUse(Feature.legalBenefits), isFalse);
      expect(ent.requiresUpgrade(Feature.legalBenefits), SubscriptionTier.plus);
    });

    test('plus kullanıcı Complete özelliği için complete gerekir', () {
      const ent = EntitlementService(SubscriptionTier.plus);
      expect(ent.canUse(Feature.familyRoutines), isFalse);
      expect(ent.requiresUpgrade(Feature.familyRoutines),
          SubscriptionTier.complete);
    });

    test('complete kullanıcı tüm özellikleri kullanır, upgrade gerekmez', () {
      const ent = EntitlementService(SubscriptionTier.complete);
      for (final f in Feature.values) {
        expect(ent.canUse(f), isTrue, reason: '$f complete için açık olmalı');
        expect(ent.requiresUpgrade(f), isNull);
      }
    });

    test('temel özellikler her katmanda açık (retroaktif kilitleme yok)', () {
      const basic = EntitlementService(SubscriptionTier.basic);
      expect(basic.canUse(Feature.familyCalendar), isTrue);
      expect(basic.canUse(Feature.tasks), isTrue);
      expect(basic.canUse(Feature.shopping), isTrue);
    });
  });
}
