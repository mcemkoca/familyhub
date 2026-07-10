import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/legal_benefits/domain/legal_benefit.dart';

void main() {
  group('LegalCategory / LegalRegion stable key', () {
    test('kategori adı stable key olarak korunur', () {
      expect(LegalCategory.childBenefits.name, 'childBenefits');
      expect(legalCategoryFromKey('healthRights'), LegalCategory.healthRights);
      expect(legalCategoryFromKey('bilinmeyen'), LegalCategory.other);
      expect(legalCategoryFromKey(null), LegalCategory.other);
    });

    test('bölge adı stable key olarak korunur', () {
      expect(LegalRegion.flanders.name, 'flanders');
      expect(legalRegionFromKey('brussels'), LegalRegion.brussels);
      expect(legalRegionFromKey(null), LegalRegion.federal);
    });
  });

  group('LegalBenefit iş kuralları', () {
    LegalBenefit make({DateTime? validUntil, DateTime? verified}) => LegalBenefit(
          id: 'x',
          title: 'T',
          description: 'D',
          category: LegalCategory.childBenefits,
          countryCode: 'BE',
          sourceTitle: 'Src',
          sourceUrl: 'https://example.gov',
          lastVerifiedAt: verified ?? DateTime.now(),
          validUntil: validUntil,
        );

    test('geçmiş validUntil → isExpired', () {
      expect(make(validUntil: DateTime(2000)).isExpired, true);
      expect(make(validUntil: DateTime(2999)).isExpired, false);
      expect(make().isExpired, false); // süresiz
    });

    test('180 günden eski doğrulama → isStale', () {
      expect(
          make(verified: DateTime.now().subtract(const Duration(days: 200)))
              .isStale,
          true);
      expect(make().isStale, false);
    });

    test('resmî kaynak URL zorunlu ve korunuyor', () {
      expect(make().sourceUrl.startsWith('https://'), true);
    });

    test('serialization round-trip', () {
      final b = make(validUntil: DateTime(2030, 5, 1));
      final back = LegalBenefit.fromJson(b.toJson());
      expect(back.id, b.id);
      expect(back.category, b.category);
      expect(back.region, b.region);
      expect(back.sourceUrl, b.sourceUrl);
      expect(back.validUntil, b.validUntil);
    });
  });
}
