import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/familyhub_ai/domain/ai_suggestion.dart';

void main() {
  const sys = [
    AISuggestion(id: 'sys_0', isSystem: true, text: 'Sistem 0'),
    AISuggestion(id: 'sys_1', isSystem: true, text: 'Sistem 1'),
  ];
  final custom = [AISuggestion.custom('c1', 'Özel 1')];

  group('AISuggestionResolver', () {
    test('özel öneriler sistemden önce gelir', () {
      final r = AISuggestionResolver.resolve(
          system: sys, custom: custom, hiddenSystemIds: {}, pinnedIds: {});
      expect(r.first.id, 'c1');
      expect(r.length, 3);
    });

    test('gizlenen sistem önerisi listede yok', () {
      final r = AISuggestionResolver.resolve(
          system: sys, custom: const [], hiddenSystemIds: {'sys_0'}, pinnedIds: {});
      expect(r.any((s) => s.id == 'sys_0'), false);
      expect(r.any((s) => s.id == 'sys_1'), true);
    });

    test('sabitlenen öneri en öne alınır ve isPinned=true', () {
      final r = AISuggestionResolver.resolve(
          system: sys, custom: const [], hiddenSystemIds: {}, pinnedIds: {'sys_1'});
      expect(r.first.id, 'sys_1');
      expect(r.first.isPinned, true);
    });

    test('custom.isSystem=false, sistem.isSystem=true', () {
      final r = AISuggestionResolver.resolve(
          system: sys, custom: custom, hiddenSystemIds: {}, pinnedIds: {});
      expect(r.firstWhere((s) => s.id == 'c1').isSystem, false);
      expect(r.firstWhere((s) => s.id == 'sys_0').isSystem, true);
    });

    test('boş kaynaklar → boş liste', () {
      final r = AISuggestionResolver.resolve(
          system: const [], custom: const [], hiddenSystemIds: {}, pinnedIds: {});
      expect(r, isEmpty);
    });
  });
}
