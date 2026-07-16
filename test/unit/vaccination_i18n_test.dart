import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/content/content_localizer.dart';

/// vaccinations_be.json'un yapısını ve i18n indirgemesini doğrular.
void main() {
  final raw = jsonDecode(
      File('assets/data/health/vaccinations_be.json').readAsStringSync());
  final cats = raw['categories'] as List;

  group('vaccinations_be i18n', () {
    test('4 kategori: child/adult/pregnancy/travel', () {
      final keys = cats.map((c) => c['key']).toList();
      expect(keys, containsAll(['child', 'adult', 'pregnancy', 'travel']));
    });

    test('çocuk kategorisi en dilinde İngilizce label + aşı adı', () {
      final child = cats.firstWhere((c) => c['key'] == 'child');
      final loc = normalizeContent(child, 'en') as Map;
      expect(loc['label'], 'Child');
      final firstVaccine = (loc['vaccines'] as List).first as Map;
      expect(firstVaccine['name'], contains('Hexavalent'));
      expect(firstVaccine['timing'], '8 weeks');
    });

    test('nl fallback yok — Flamanca gelir', () {
      final adult = cats.firstWhere((c) => c['key'] == 'adult');
      final loc = normalizeContent(adult, 'nl') as Map;
      expect(loc['label'], 'Volwassene');
    });

    test('her kategori için resmî kaynak tanımlı', () {
      final sources = raw['sources'] as Map;
      for (final key in ['child', 'adult', 'pregnancy', 'travel']) {
        expect((sources[key] as List).isNotEmpty, isTrue,
            reason: '$key kaynağı eksik');
      }
    });

    test('her aşıda id/ageBand + tr temel alanları var', () {
      for (final c in cats) {
        for (final v in (c['vaccines'] as List)) {
          expect((v['id'] as String).isNotEmpty, isTrue);
          expect(v['i18n']['tr']['name'], isNotNull);
        }
      }
    });
  });
}
