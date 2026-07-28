import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/application/ai_action_memory_adapter.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/familyhub_ai/application/ai_action_executor.dart';
import 'package:familyhub/features/familyhub_ai/domain/ai_action.dart';

/// AI aksiyonu → hafıza köprüsü. En kritik kural: BAŞARISIZ aksiyon
/// "yapıldı" gibi hatırlanmaz.
void main() {
  AIAction act(AIActionType t) => AIAction(type: t);

  group('SAHTE BAŞARI ENGELİ — kritik', () {
    test('KRİTİK: failed aksiyon HATIRLANMAZ', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createTask), result: AIExecResult.failed);
      expect(c, isEmpty);
    });

    test('KRİTİK: invalid aksiyon HATIRLANMAZ', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createTask), result: AIExecResult.invalid);
      expect(c, isEmpty);
    });

    test('KRİTİK: unsupported aksiyon HATIRLANMAZ', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createTask),
          result: AIExecResult.unsupported);
      expect(c, isEmpty);
    });

    test('yalnızca done hatırlanır', () {
      expect(actionShouldBeRemembered(AIExecResult.done), isTrue);
      expect(actionShouldBeRemembered(AIExecResult.failed), isFalse);
      expect(actionShouldBeRemembered(AIExecResult.invalid), isFalse);
      expect(actionShouldBeRemembered(AIExecResult.unsupported), isFalse);
    });
  });

  group('gürültü filtresi', () {
    test('salt gezinme aksiyonu hatırlanmaz', () {
      expect(
        candidatesForCompletedAction(
            action: act(AIActionType.openModule), result: AIExecResult.done),
        isEmpty,
      );
      expect(
        candidatesForCompletedAction(
            action: act(AIActionType.openEntity), result: AIExecResult.done),
        isEmpty,
      );
    });

    test('özet gösterme hatırlanmaz', () {
      expect(
        candidatesForCompletedAction(
            action: act(AIActionType.summarizeBudget),
            result: AIExecResult.done),
        isEmpty,
      );
    });

    test('yasal kaynak açma hatırlanmaz', () {
      expect(
        candidatesForCompletedAction(
            action: act(AIActionType.openLegalBenefit),
            result: AIExecResult.done),
        isEmpty,
      );
    });
  });

  group('başarılı yazma aksiyonları hatırlanır', () {
    test('görev oluşturma episodik kayıt üretir', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createTask), result: AIExecResult.done);
      expect(c.single.kind, MemoryKind.episodicEvent);
      expect(c.single.module, 'tasks');
      expect(c.single.key, 'action.createTask.completed');
    });

    test('takvim etkinliği calendar modülüne yazılır', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createCalendarEvent),
          result: AIExecResult.done);
      expect(c.single.module, 'calendar');
    });

    test('alışveriş shopping modülüne yazılır', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.addShoppingItems),
          result: AIExecResult.done);
      expect(c.single.module, 'shopping');
    });

    test('KRİTİK: kaynak applicationEvent — kullanıcı beyanı DEĞİL', () {
      final c = candidatesForCompletedAction(
          action: act(AIActionType.createTask), result: AIExecResult.done);
      expect(c.single.sourceType, MemorySourceType.applicationEvent);
      // Otorite kullanıcı beyanından düşük olmalı (çelişkide ezemez).
      expect(
        MemorySourceType.applicationEvent.authority,
        lessThan(MemorySourceType.userCorrection.authority),
      );
    });

    test('özel özet verilirse başlık olarak kullanılır', () {
      final c = candidatesForCompletedAction(
        action: act(AIActionType.createTask),
        result: AIExecResult.done,
        summary: 'Market alışverişi görevi',
      );
      expect(c.single.title, 'Market alışverişi görevi');
    });

    test('özet boşsa varsayılan etiket kullanılır', () {
      final c = candidatesForCompletedAction(
        action: act(AIActionType.createReminder),
        result: AIExecResult.done,
        summary: '   ',
      );
      expect(c.single.title, 'Hatırlatıcı kuruldu');
    });
  });

  group('modül eşlemesi', () {
    test('her aksiyon tipi bir modüle eşlenir', () {
      for (final t in AIActionType.values) {
        expect(moduleForAction(t).isNotEmpty, isTrue, reason: t.name);
      }
    });
  });

  group('olay üretimi', () {
    test('sistem olayı userInitiated=false', () {
      final e = aiActionMemoryEvent(
          eventId: 'e1', type: AIActionType.createTask, userId: 'u1');
      expect(e.userInitiated, isFalse);
      expect(e.explicitRememberRequest, isFalse);
      expect(e.module, 'tasks');
    });
  });
}
