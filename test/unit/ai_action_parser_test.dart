import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/familyhub_ai/domain/ai_action.dart';
import 'package:familyhub/features/familyhub_ai/domain/ai_action_parser.dart';

/// FH-04 / spec §8 — AI çıktısı GÜVENİLMEZ input.
void main() {
  group('geçerli aksiyonlar', () {
    test('alışverişe ürün ekleme çözülür', () {
      final r = parseAiResponse(
          '{"reply":"Ekliyorum.","action":{"type":"addShoppingItems","payload":{"items":["süt","ekmek"]}}}');
      expect(r.reply, 'Ekliyorum.');
      expect(r.action?.type, AIActionType.addShoppingItems);
      expect(r.action?.payload['items'], ['süt', 'ekmek']);
    });

    test('hatırlatma (yarın 18:00 süt) çözülür', () {
      final r = parseAiResponse(
          '{"reply":"Kuruyorum.","action":{"type":"createReminder","payload":{"title":"Süt al","days":1}}}');
      expect(r.action?.type, AIActionType.createReminder);
      expect(r.action?.payload['title'], 'Süt al');
      // HIGH risk → runtime onayı gerekli
      expect(r.action?.requiresConfirmation, isTrue);
    });

    test('takvim etkinliği çözülür', () {
      final r = parseAiResponse(
          '{"reply":"Ekledim.","action":{"type":"createCalendarEvent","payload":{"title":"Doktor","date":"2026-07-24T15:30:00"}}}');
      expect(r.action?.type, AIActionType.createCalendarEvent);
    });

    test('``` çitli JSON da çözülür', () {
      final r = parseAiResponse(
          'Tabii!\n```json\n{"reply":"Ekliyorum.","action":{"type":"addShoppingItems","payload":{"items":["un"]}}}\n```');
      expect(r.action?.type, AIActionType.addShoppingItems);
    });
  });

  group('güvenlik — reddedilmesi gerekenler', () {
    test('BİLİNMEYEN action type → aksiyon üretilmez', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"deleteAllFamilies","payload":{}}}');
      expect(r.action, isNull);
      expect(r.reply, 'ok');
    });

    test('BOZUK payload (items yok) → şema doğrulaması düşürür', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"addShoppingItems","payload":{}}}');
      expect(r.action, isNull);
    });

    test('boş title createReminder → düşürülür', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"createReminder","payload":{"title":"   "}}}');
      expect(r.action, isNull);
    });

    test('family_id/user_id/child_id modelden ALINMAZ', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"createTask","payload":{"title":"X","family_id":"baska-aile","userId":"kurban","childId":"c9"}}}');
      expect(r.action, isNotNull);
      expect(r.action!.payload.containsKey('family_id'), isFalse);
      expect(r.action!.payload.containsKey('userId'), isFalse);
      expect(r.action!.payload.containsKey('childId'), isFalse);
      expect(r.action!.payload['title'], 'X');
    });

    test('allowlist dışı fazla parametreler temizlenir', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"addShoppingItems","payload":{"items":["a"],"sqlInjection":"drop table","role":"admin"}}}');
      expect(r.action!.payload.keys.toSet(), {'items'});
    });

    test('harici route (açık yönlendirme) reddedilir → openModule düşer', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"openModule","route":"https://kotu.site"}}');
      expect(r.action, isNull); // route '/' ile başlamıyor → isValid false
    });

    test('legal kaynak yalnızca https kabul eder', () {
      final bad = parseAiResponse(
          '{"reply":"ok","action":{"type":"openLegalBenefit","payload":{"url":"http://insecure"}}}');
      expect(bad.action, isNull);
      final ok = parseAiResponse(
          '{"reply":"ok","action":{"type":"openLegalBenefit","payload":{"url":"https://www.groeipakket.be/"}}}');
      expect(ok.action?.type, AIActionType.openLegalBenefit);
    });
  });

  group('metin fallback (spec §8 test 13)', () {
    test('düz sohbet cevabı → aksiyon yok, metin korunur', () {
      final r = parseAiResponse('Bugün menemen yapabilirsin, çok pratik.');
      expect(r.action, isNull);
      expect(r.reply, 'Bugün menemen yapabilirsin, çok pratik.');
    });

    test('bozuk JSON → çökmez, ham metin döner', () {
      final r = parseAiResponse('{"reply": "yarim...');
      expect(r.action, isNull);
      expect(r.reply, isNotEmpty);
    });

    test('action alanı yoksa yalnızca reply kullanılır', () {
      final r = parseAiResponse('{"reply":"Sadece bilgi."}');
      expect(r.action, isNull);
      expect(r.reply, 'Sadece bilgi.');
    });
  });

  group('risk sınıflandırma', () {
    test('düşük riskli aksiyon onay istemez', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"summarizeBudget","route":"/budget"}}');
      expect(r.action?.requiresConfirmation, isFalse);
    });

    test('addShoppingItems MEDIUM → onay ister', () {
      final r = parseAiResponse(
          '{"reply":"ok","action":{"type":"addShoppingItems","payload":{"items":["a"]}}}');
      expect(r.action?.requiresConfirmation, isTrue);
    });
  });
}
