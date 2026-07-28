import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/content/content_localizer.dart';

void main() {
  group('normalizeContent', () {
    test('dil-map → aktif dil metni', () {
      final v = {
        'title': {'tr': 'Menemen', 'en': 'Scrambled Eggs', 'nl': 'Roerei'},
      };
      expect((normalizeContent(v, 'nl') as Map)['title'], 'Roerei');
      expect((normalizeContent(v, 'en') as Map)['title'], 'Scrambled Eggs');
    });

    test('eksik dil → en → tr fallback', () {
      final v = {
        'x': {'tr': 'T', 'en': 'E'},
      };
      expect((normalizeContent(v, 'fr') as Map)['x'], 'E'); // fr yok → en
      final v2 = {
        'x': {'tr': 'T'},
      };
      expect((normalizeContent(v2, 'fr') as Map)['x'], 'T'); // en yok → tr
    });

    test('{key,label} → key (filtre korunur)', () {
      final v = {
        'category': {
          'key': 'kahvalti',
          'label': {'tr': 'Kahvaltı', 'en': 'Breakfast'},
        },
      };
      expect((normalizeContent(v, 'en') as Map)['category'], 'kahvalti');
    });

    test('i18n alt-objesi merge — title/ingredients/difficulty yerelleşir', () {
      final r = {
        'id': 'r001',
        'title': 'Menemen',
        'category': 'kahvalti',
        'difficulty': 'kolay',
        'ingredients': [
          {'name': 'Yumurta', 'unit': 'adet'},
        ],
        'i18n': {
          'en': {
            'title': 'Menemen',
            'difficulty_label': 'easy',
            'ingredients': [
              {'name': 'egg', 'unit': 'quantity'},
            ],
          },
        },
      };
      final out = normalizeContent(r, 'en') as Map;
      expect(out['difficulty'], 'easy'); // difficulty_label → difficulty
      expect(out['category'], 'kahvalti'); // filtre anahtarı korunur
      expect((out['ingredients'] as List).first['name'], 'egg');
      expect(out.containsKey('i18n'), isFalse); // i18n kaldırıldı
    });

    test('i18n eksik dil → en fallback', () {
      final r = {
        'title': 'X',
        'i18n': {
          'en': {'title': 'X-en'},
          'tr': {'title': 'X-tr'},
        },
      };
      expect((normalizeContent(r, 'fr') as Map)['title'], 'X-en');
    });

    test('düz string dokunulmaz', () {
      expect(normalizeContent('plain', 'en'), 'plain');
    });
  });
}
