import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/content/domain/localized_content.dart';
import 'package:familyhub/features/content/application/content_validator.dart';
import 'package:familyhub/features/content/application/content_deduplicator.dart';

ContentTranslation _t(String s) =>
    ContentTranslation(title: 'T-$s', summary: 'S-$s', body: 'B-$s');

LocalizedContent _content({
  String id = 'c1',
  ContentStatus status = ContentStatus.published,
  ContentRisk risk = ContentRisk.standard,
  Map<String, ContentTranslation>? tr,
  String url = 'https://example.be/a',
  String publisher = 'Pub',
  String? hash = 'h1',
  DateTime? verifiedAt,
}) =>
    LocalizedContent(
      id: id,
      category: 'child_health',
      countryCode: 'BE',
      regionCodes: const ['BRU'],
      status: status,
      riskLevel: risk,
      source: ContentSource(
          url: url,
          publisher: publisher,
          language: 'nl',
          contentHash: hash,
          verifiedAt: verifiedAt),
      translations: tr ??
          {for (final l in contentLocales) l: _t(l)},
    );

void main() {
  group('LocalizedContent — parity & fallback', () {
    test('4 dil tamsa hasAllTranslations true', () {
      expect(_content().hasAllTranslations, isTrue);
    });

    test('bir dil eksikse hasAllTranslations false', () {
      final c = _content(tr: {'tr': _t('tr'), 'en': _t('en'), 'fr': _t('fr')});
      expect(c.hasAllTranslations, isFalse);
    });

    test('fallback zinciri: seçili → en → tr', () {
      expect(contentFallbackChain('nl_BE'), ['nl', 'en', 'tr']);
      expect(contentFallbackChain('en'), ['en', 'tr']);
      expect(contentFallbackChain('tr'), ['tr', 'en']);
    });

    test('resolve eksik dilde fallback uygular', () {
      final c = _content(tr: {'tr': _t('tr'), 'en': _t('en')});
      // nl yok → en'e düşer
      expect(c.resolve('nl_BE')!.title, 'T-en');
      // en de yoksa tr
      final c2 = _content(tr: {'tr': _t('tr')});
      expect(c2.resolve('fr')!.title, 'T-tr');
    });

    test('toJson/fromJson round-trip ID ve dilleri korur', () {
      final c = _content();
      final back = LocalizedContent.fromJson(c.toJson());
      expect(back.id, c.id);
      expect(back.hasAllTranslations, isTrue);
      expect(back.status, ContentStatus.published);
    });
  });

  group('ContentValidator — yayın kalite kapısı', () {
    test('tam içerik yayınlanabilir', () {
      expect(ContentValidator.canPublish(_content()), isTrue);
      expect(ContentValidator.validate(_content()), isEmpty);
    });

    test('eksik çeviri → yayınlanamaz (eksik çevirinin yayınlanmaması)', () {
      final c = _content(tr: {'tr': _t('tr'), 'en': _t('en'), 'fr': _t('fr')});
      expect(ContentValidator.canPublish(c), isFalse);
      expect(ContentValidator.validate(c).any((i) => i.code == 'missing_translation'),
          isTrue);
    });

    test('kaynak URL yoksa ihlal (kaynaksız yayın engeli)', () {
      final c = _content(url: '');
      expect(ContentValidator.validate(c).any((i) => i.code == 'missing_source_url'),
          isTrue);
    });

    test('yüksek riskli içerik doğrulama tarihi olmadan yayınlanamaz', () {
      final c = _content(risk: ContentRisk.health); // verifiedAt null
      expect(ContentValidator.validate(c)
          .any((i) => i.code == 'unverified_high_risk'), isTrue);
      final ok = _content(
          risk: ContentRisk.health, verifiedAt: DateTime(2026, 7, 1));
      expect(ContentValidator.validate(ok), isEmpty);
    });
  });

  group('ContentDeduplicator — idempotency', () {
    test('aynı URL+hash tekrar eklenmez', () {
      final a = _content(id: 'a', url: 'https://x/1', hash: 'h');
      final dup = _content(id: 'b', url: 'https://x/1', hash: 'h'); // aynı key
      final merged = ContentDeduplicator.merge([a], [dup]);
      expect(merged.length, 1);
    });

    test('farklı hash ayrı kayıt', () {
      final a = _content(id: 'a', url: 'https://x/1', hash: 'h1');
      final b = _content(id: 'b', url: 'https://x/1', hash: 'h2');
      expect(ContentDeduplicator.merge([a], [b]).length, 2);
    });

    test('idempotent: iki kez uygulama sonucu değiştirmez', () {
      final a = _content(id: 'a', url: 'https://x/1', hash: 'h');
      final once = ContentDeduplicator.merge([a], [a]);
      final twice = ContentDeduplicator.merge(once, [a]);
      expect(twice.length, 1);
      expect(twice.map((c) => c.id), once.map((c) => c.id));
    });

    test('deterministik sıra (id artan)', () {
      final c = _content(id: 'c', url: 'u3', hash: '3');
      final a = _content(id: 'a', url: 'u1', hash: '1');
      final b = _content(id: 'b', url: 'u2', hash: '2');
      expect(ContentDeduplicator.unique([c, a, b]).map((e) => e.id).toList(),
          ['a', 'b', 'c']);
    });
  });
}
