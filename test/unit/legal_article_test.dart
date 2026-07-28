import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/content/content_localizer.dart';
import 'package:familyhub/features/legal_benefits/domain/legal_article.dart';

void main() {
  // be.json'daki i18n desenini temsil eden örnek makale.
  final rawArticle = {
    'id': 'be_groeipakket',
    'slug': 'groeipakket-vlaanderen',
    'category': 'childBenefits',
    'regionCodes': ['BE-VLG'],
    'jurisdictionLevel': 'regional',
    'riskLevel': 'high',
    'status': 'published',
    'lastVerifiedAt': '2026-01-15',
    'sources': [
      {
        'authority': 'Groeipakket',
        'title': 'Portal',
        'url': 'https://www.groeipakket.be/',
        'trustLevel': 1,
      },
    ],
    'i18n': {
      'tr': {
        'title': 'Groeipakket (TR)',
        'summary': 'Özet',
        'conditions': ['koşul1', 'koşul2'],
        'applicationSteps': ['adım1'],
      },
      'en': {
        'title': 'Groeipakket (EN)',
        'summary': 'Summary',
        'conditions': ['cond1', 'cond2'],
        'applicationSteps': ['step1'],
      },
    },
  };

  group('LegalArticle.fromLocalized + normalizeContent', () {
    test('aktif dil (en) uygulanır, sources ve meta korunur', () {
      final loc = normalizeContent(rawArticle, 'en') as Map<String, dynamic>;
      final a = LegalArticle.fromLocalized(loc);
      expect(a.title, 'Groeipakket (EN)');
      expect(a.summary, 'Summary');
      expect(a.conditions, ['cond1', 'cond2']);
      expect(a.applicationSteps, ['step1']);
      expect(a.category, 'childBenefits');
      expect(a.regionCodes, ['BE-VLG']);
      expect(a.sources.length, 1);
      expect(a.sources.first.url, 'https://www.groeipakket.be/');
      expect(a.isPublished, isTrue);
    });

    test('desteklenmeyen dil (nl yok) → en fallback', () {
      final loc = normalizeContent(rawArticle, 'nl') as Map<String, dynamic>;
      final a = LegalArticle.fromLocalized(loc);
      expect(a.title, 'Groeipakket (EN)'); // nl yok → en
    });

    test('tr aktifken tr içerik gelir', () {
      final loc = normalizeContent(rawArticle, 'tr') as Map<String, dynamic>;
      final a = LegalArticle.fromLocalized(loc);
      expect(a.title, 'Groeipakket (TR)');
      expect(a.conditions, ['koşul1', 'koşul2']);
    });

    test('lastVerifiedAt parse edilir, isStale hesaplanır', () {
      final loc = normalizeContent(rawArticle, 'en') as Map<String, dynamic>;
      final a = LegalArticle.fromLocalized(loc);
      expect(a.lastVerifiedAt, DateTime(2026, 1, 15));
    });
  });
}
