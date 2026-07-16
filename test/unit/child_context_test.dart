import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/domain/models/child_account.dart';
import 'package:familyhub/presentation/providers/child_context_provider.dart';

ChildAccount _child(String id, String name) => ChildAccount(
      id: id,
      familyId: 'fam1',
      name: name,
      role: ChildRole.child,
      color: Colors.blue,
      createdBy: 'u1',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('activeChildProvider çözümü', () {
    test('çocuk yoksa null', () {
      final c = ProviderContainer(overrides: [
        familyChildrenProvider
            .overrideWith((ref) async => const <ChildAccount>[]),
      ]);
      addTearDown(c.dispose);
      // FutureProvider henüz çözülmedi → asData null → boş liste → null
      expect(c.read(activeChildProvider), isNull);
    });

    test('seçim yoksa ilk çocuğa düşer', () async {
      final c = ProviderContainer(overrides: [
        familyChildrenProvider.overrideWith(
            (ref) async => [_child('a', 'Ada'), _child('b', 'Bo')]),
      ]);
      addTearDown(c.dispose);
      await c.read(familyChildrenProvider.future);
      expect(c.read(activeChildProvider)?.id, 'a');
    });

    test('geçerli seçim o çocuğu döner', () async {
      final c = ProviderContainer(overrides: [
        familyChildrenProvider.overrideWith(
            (ref) async => [_child('a', 'Ada'), _child('b', 'Bo')]),
      ]);
      addTearDown(c.dispose);
      await c.read(familyChildrenProvider.future);
      c.read(activeChildIdProvider.notifier).select('b');
      expect(c.read(activeChildProvider)?.id, 'b');
    });

    test('geçersiz/eski seçim ilk çocuğa düşer', () async {
      final c = ProviderContainer(overrides: [
        familyChildrenProvider
            .overrideWith((ref) async => [_child('a', 'Ada')]),
      ]);
      addTearDown(c.dispose);
      await c.read(familyChildrenProvider.future);
      c.read(activeChildIdProvider.notifier).select('silinmis');
      expect(c.read(activeChildProvider)?.id, 'a');
    });

    test('hasChildrenProvider doğru', () async {
      final c = ProviderContainer(overrides: [
        familyChildrenProvider
            .overrideWith((ref) async => [_child('a', 'Ada')]),
      ]);
      addTearDown(c.dispose);
      await c.read(familyChildrenProvider.future);
      expect(c.read(hasChildrenProvider), isTrue);
    });
  });
}
