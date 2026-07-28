import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/content/content_localizer.dart';

/// daily_suggestions.json'un aktif dile doğru indirgendiğini doğrular.
void main() {
  final raw = jsonDecode(
      File('assets/data/daily_suggestions.json').readAsStringSync());
  final sugs = (raw['suggestions'] as List);

  Map<String, dynamic> byId(String id) =>
      sugs.firstWhere((e) => e['id'] == id) as Map<String, dynamic>;

  group('daily_suggestions i18n', () {
    test('400 öneri + 14 görev yüklendi', () {
      expect(sugs.length, 400);
      expect((raw['chores'] as List).length, 14);
    });

    test('çevrilmiş tarif (y02) en dilinde İngilizce gelir', () {
      final loc = normalizeContent(byId('y02'), 'en') as Map;
      expect(loc['title'], 'Karnıyarık (Stuffed Eggplant)');
      expect(loc['difficulty'], 'Medium'); // difficulty_label → difficulty
      expect(loc.containsKey('i18n'), isFalse);
    });

    test('çevrilmiş tarif nl dilinde Flamanca gelir', () {
      final loc = normalizeContent(byId('y24'), 'nl') as Map;
      expect(loc['title'], 'Menemen');
      expect(loc['description'], contains('paprika'));
      expect(loc['difficulty'], 'Makkelijk');
    });

    test('tüm 400 öğe 3 dilde başlık+açıklama içerir (tam kapsama)', () {
      for (final s in sugs) {
        final m = s as Map;
        final i18n = m['i18n'] as Map;
        for (final lang in ['en', 'fr', 'nl']) {
          final loc = i18n[lang] as Map;
          expect(loc['title'], isNotEmpty,
              reason: '${m['id']} $lang title eksik');
          expect(loc['description'], isNotEmpty,
              reason: '${m['id']} $lang description eksik');
        }
      }
    });

    test('sosyal öğe (a01) artık çevrili', () {
      final loc = normalizeContent(byId('a01'), 'fr') as Map;
      expect(loc['title'], 'Soirée jeux en famille');
    });

    test('görev (ch1) en dilinde çevrili', () {
      final chores = raw['chores'] as List;
      final ch1 = chores.firstWhere((e) => e['id'] == 'ch1');
      final loc = normalizeContent(ch1, 'en') as Map;
      expect(loc['title'], 'Kitchen Counter Cleaning');
    });
  });
}
