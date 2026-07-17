import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/models/child_account.dart';
import 'package:familyhub/presentation/providers/child_context_provider.dart';

/// FAZ 3 — resolveActiveChild saf seçim mantığı (provider'dan bağımsız).
ChildAccount child(String id, {String family = 'f1'}) => ChildAccount(
      id: id,
      familyId: family,
      name: 'Çocuk $id',
      role: ChildRole.child,
      color: Colors.blue,
      createdBy: 'parent',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('hiç çocuk yoksa null (empty state)', () {
    expect(resolveActiveChild(const [], null), isNull);
    expect(resolveActiveChild(const [], 'x'), isNull);
  });

  test('tek çocuk otomatik seçilir', () {
    expect(resolveActiveChild([child('a')], null)?.id, 'a');
  });

  test('geçerli persisted seçim korunur', () {
    final list = [child('a'), child('b'), child('c')];
    expect(resolveActiveChild(list, 'b')?.id, 'b');
  });

  test('geçersiz/silinmiş seçim → ilk çocuğa fallback', () {
    expect(resolveActiveChild([child('a'), child('b')], 'silinmis')?.id, 'a');
  });

  test('başka aileye ait id listede yoksa → güvenli fallback (izolasyon)', () {
    expect(
        resolveActiveChild([child('a', family: 'f1')], 'baska_aile_cocugu')?.id,
        'a');
  });
}
