import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/ai/pedagogy_engine.dart';

void main() {
  group('PedagogyEngine.parseJsonObject', () {
    test('düz JSON nesnesi ayrıştırır', () {
      final r = PedagogyEngine.parseJsonObject('{"title":"Ders","points":10}');
      expect(r, isNotNull);
      expect(r!['title'], 'Ders');
      expect(r['points'], 10);
    });

    test('```json fence içindeki JSON ayrıştırır', () {
      const raw = '```json\n{"a":1,"b":"x"}\n```';
      final r = PedagogyEngine.parseJsonObject(raw);
      expect(r?['a'], 1);
      expect(r?['b'], 'x');
    });

    test('dilsiz ``` fence ayrıştırır', () {
      const raw = '```\n{"ok":true}\n```';
      expect(PedagogyEngine.parseJsonObject(raw)?['ok'], true);
    });

    test('araya karışan düz metni tolere eder', () {
      const raw = 'İşte haftalık plan: {"week_theme":"Uzay"} umarım beğenirsin!';
      expect(PedagogyEngine.parseJsonObject(raw)?['week_theme'], 'Uzay');
    });

    test('iç içe nesne/dizi ile son } doğru bulunur', () {
      const raw = '{"days":[{"n":1},{"n":2}],"goal":"oku"}';
      final r = PedagogyEngine.parseJsonObject(raw);
      expect((r?['days'] as List).length, 2);
      expect(r?['goal'], 'oku');
    });

    test('geçersiz JSON null döner', () {
      expect(PedagogyEngine.parseJsonObject('{bozuk: değil json'), isNull);
    });

    test('nesne olmayan içerik null döner', () {
      expect(PedagogyEngine.parseJsonObject('sadece düz metin'), isNull);
      expect(PedagogyEngine.parseJsonObject(''), isNull);
    });
  });
}
