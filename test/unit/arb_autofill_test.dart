import 'package:flutter_test/flutter_test.dart';
import '../../tool/arb_autofill.dart' as autofill;
import '../../tool/content_sync/content_translator.dart';

void main() {
  group('ARB autofill — eksik anahtar tespiti', () {
    test('hedefte olmayan anahtarları bulur, @-metadata sayılmaz', () {
      final tr = {'a': '1', 'b': '2', 'c': '3', '@c': {}};
      final en = {'a': 'x', '@a': {}};
      expect(autofill.missingKeys(tr, en), ['b', 'c']);
    });

    test('parity tamsa boş liste', () {
      final tr = {'a': '1', 'b': '2'};
      final en = {'a': 'x', 'b': 'y'};
      expect(autofill.missingKeys(tr, en), isEmpty);
    });

    test('sonuç deterministik (sıralı)', () {
      final tr = {'z': '1', 'a': '2', 'm': '3'};
      expect(autofill.missingKeys(tr, {}), ['a', 'm', 'z']);
    });
  });

  group('Çeviri sağlayıcı + guard', () {
    test('yapılandırılmamış sağlayıcı çeviri fırlatır (sahte çeviri yok)', () {
      final p = PendingTranslationProvider();
      expect(p.isConfigured, isFalse);
      expect(
        () => p.translate(const TranslationRequest('Merhaba',
            sourceLocale: 'tr', targetLocale: 'en')),
        throwsA(isA<TranslationUnavailable>()),
      );
    });

    test('placeholder guard: {name} kaybını yakalar', () {
      expect(
          TranslationGuards.placeholdersPreserved(
              'Merhaba {name}', 'Hello {name}'),
          isTrue);
      expect(
          TranslationGuards.placeholdersPreserved(
              'Merhaba {name}', 'Hello there'),
          isFalse);
    });

    test('translation memory aynı metni tekrar çevirmez', () {
      final tm = TranslationMemory();
      const req = TranslationRequest('Kaydet',
          sourceLocale: 'tr', targetLocale: 'en');
      expect(tm.get(req), isNull);
      tm.put(req, 'Save');
      expect(tm.get(req), 'Save');
    });
  });
}
