import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/config/market_catalog.dart';
import 'package:familyhub/config/country_config.dart';

void main() {
  group('CountryConfig', () {
    test('byCode bilinen ülkeyi döner', () {
      expect(CountryConfig.byCode('TR').code, 'TR');
      expect(CountryConfig.byCode('BE').currencyCode, 'EUR');
      expect(CountryConfig.byCode('TR').currencyCode, 'TRY');
    });

    test('bilinmeyen/null kod fallback döner', () {
      expect(CountryConfig.byCode('XX').code, CountryConfig.fallback.code);
      expect(CountryConfig.byCode(null).code, CountryConfig.fallback.code);
    });

    test('5 ülke tanımlı (BE/TR/NL/FR/DE)', () {
      final codes = CountryConfig.all.map((c) => c.code).toSet();
      expect(codes, containsAll(['BE', 'TR', 'NL', 'FR', 'DE']));
    });
  });

  group('MarketCatalog', () {
    test('TR marketleri BIM ve A101 içermez (kullanıcı kısıtı)', () {
      final tr = MarketCatalog.marketsFor('TR');
      expect(tr, isNot(contains('BIM')));
      expect(tr, isNot(contains('A101')));
      expect(tr, contains('Migros'));
    });

    test('BE marketleri Aldi/Lidl/Colruyt içerir', () {
      final be = MarketCatalog.marketsFor('BE');
      expect(be, containsAll(['Aldi', 'Lidl', 'Colruyt']));
    });

    test('bilinmeyen ülke BE kataloğuna düşer', () {
      expect(MarketCatalog.marketsFor('ZZ'), MarketCatalog.marketsFor('BE'));
    });

    test('weeklyDeals istenen adette döner', () {
      expect(MarketCatalog.weeklyDeals('BE', count: 6).length, 6);
      expect(MarketCatalog.weeklyDeals('TR', count: 4).length, 4);
    });

    test('weeklyDeals aynı hafta içinde deterministik', () {
      final a = MarketCatalog.weeklyDeals('BE').map((p) => p.name).toList();
      final b = MarketCatalog.weeklyDeals('BE').map((p) => p.name).toList();
      expect(a, b);
    });

    test('weekNumber 1..53 aralığında', () {
      expect(MarketCatalog.weekNumber(DateTime(2026, 1, 1)), inInclusiveRange(1, 53));
      expect(MarketCatalog.weekNumber(DateTime(2026, 7, 4)), inInclusiveRange(1, 53));
      expect(MarketCatalog.weekNumber(DateTime(2026, 12, 31)), inInclusiveRange(1, 53));
    });

    test('kategoriler boş değil', () {
      expect(MarketCatalog.categories, isNotEmpty);
    });

    test('productsFor kategoriye göre filtreler', () {
      final cat = MarketCatalog.categories.first;
      final filtered = MarketCatalog.productsFor('BE', category: cat);
      expect(filtered, isNotEmpty);
      expect(filtered.every((p) => p.category == cat), isTrue);
    });
  });
}
