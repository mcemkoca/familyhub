import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/familyhub_ai/domain/family_ai_response.dart';

/// family-ai structured response + "sahte başarı yok" kontratı testleri.
void main() {
  group('type parsing (exhaustive)', () {
    test('bilinen tipler doğru map edilir', () {
      for (final e in {
        'answer': FamilyAiResponseType.answer,
        'action_proposal': FamilyAiResponseType.actionProposal,
        'action_result': FamilyAiResponseType.actionResult,
        'error': FamilyAiResponseType.error,
        'safety_notice': FamilyAiResponseType.safetyNotice,
        'navigation': FamilyAiResponseType.navigation,
      }.entries) {
        final r = FamilyAiResponse.fromJson({'type': e.key, 'text': 'x'});
        expect(r.type, e.value, reason: e.key);
      }
    });

    test('bilinmeyen tip → unknown, crash yok', () {
      final r = FamilyAiResponse.fromJson({'type': 'martian', 'text': 'x'});
      expect(r.type, FamilyAiResponseType.unknown);
    });

    test('bozuk JSON → error tipi, crash yok', () {
      final r = FamilyAiResponse.parse('{bozuk json');
      expect(r.type, FamilyAiResponseType.error);
      expect(r.errorCode, 'INVALID_RESPONSE');
    });
  });

  group('SAHTE BAŞARI ENGELLEME (§12) — kritik', () {
    test('model metni "takvime eklendi" dese bile completed action YOK', () {
      // executed_actions boş → model ne derse desin completed gösterilmez.
      final r = FamilyAiResponse.parse(
          '{"type":"answer","text":"Takvime eklendi.","executed_actions":[]}');
      expect(r.hasCompletedAction, isFalse);
    });

    test('status=success ama persisted=false → başarı DEĞİL', () {
      final r = FamilyAiResponse.fromJson({
        'type': 'action_result',
        'text': 'x',
        'executed_actions': [
          {'tool': 'create_family_task', 'status': 'success', 'persisted': false}
        ],
      });
      expect(r.hasCompletedAction, isFalse);
    });

    test('status=error → başarı DEĞİL', () {
      final r = FamilyAiResponse.fromJson({
        'type': 'action_result',
        'text': 'x',
        'executed_actions': [
          {'tool': 'create_family_task', 'status': 'error', 'persisted': false}
        ],
      });
      expect(r.hasCompletedAction, isFalse);
    });

    test('gerçek başarı: status=success && persisted=true', () {
      final r = FamilyAiResponse.fromJson({
        'type': 'action_result',
        'text': 'Görev oluşturuldu',
        'executed_actions': [
          {
            'tool': 'create_family_task',
            'status': 'success',
            'persisted': true,
            'resourceId': 'task_123'
          }
        ],
      });
      expect(r.hasCompletedAction, isTrue);
      expect(r.executedActions.first.resourceId, 'task_123');
    });
  });

  group('güvenli alan çıkarımı', () {
    test('eksik alanlar güvenli varsayılan', () {
      final r = FamilyAiResponse.fromJson({});
      expect(r.text, '');
      expect(r.suggestions, isEmpty);
      expect(r.executedActions, isEmpty);
      expect(r.type, FamilyAiResponseType.unknown);
    });

    test('suggestions ve model okunur', () {
      final r = FamilyAiResponse.fromJson({
        'type': 'answer',
        'text': 'Merhaba',
        'suggestions': ['a', 'b'],
        'model': 'gemini-2.5-flash',
      });
      expect(r.suggestions, ['a', 'b']);
      expect(r.model, 'gemini-2.5-flash');
    });
  });
}
