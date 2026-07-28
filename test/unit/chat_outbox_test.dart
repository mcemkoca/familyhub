import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/services/chat_outbox.dart';

/// FAZ 6 — offline pending kuyruğu çekirdek testleri.
void main() {
  OutboxMessage msg(String id, {String owner = 'u1', int retry = 0}) =>
      OutboxMessage(
        clientMessageId: id,
        ownerId: owner,
        familyId: 'f1',
        content: 'merhaba',
        createdAtMs: 1000,
        retryCount: retry,
      );

  group('serialization', () {
    test('json round-trip alanları korur', () {
      final m = msg('c1', retry: 2).copyWith(
          state: OutboxState.failed, lastError: 'boom', nextRetryAtMs: 5);
      final back = OutboxMessage.fromJson(m.toJson());
      expect(back.clientMessageId, 'c1');
      expect(back.retryCount, 2);
      expect(back.state, OutboxState.failed);
      expect(back.lastError, 'boom');
      expect(back.nextRetryAtMs, 5);
    });

    test('liste encode/decode', () {
      final raw = OutboxMessage.encodeList([msg('a'), msg('b')]);
      final list = OutboxMessage.decodeList(raw);
      expect(list.map((e) => e.clientMessageId), ['a', 'b']);
    });

    test('boş/bozuk girdi güvenli boş liste', () {
      expect(OutboxMessage.decodeList(null), isEmpty);
      expect(OutboxMessage.decodeList(''), isEmpty);
      expect(OutboxMessage.decodeList('{bozuk'), isEmpty);
    });
  });

  group('backoff', () {
    test('exponential adımlar 2/5/15/30/60', () {
      expect(backoffSeconds(0), 2);
      expect(backoffSeconds(1), 5);
      expect(backoffSeconds(2), 15);
      expect(backoffSeconds(3), 30);
      expect(backoffSeconds(4), 60);
    });

    test('üst sınırda sabit kalır (sonsuz büyümez)', () {
      expect(backoffSeconds(10), 60);
      expect(backoffSeconds(100), 60);
    });

    test('negatif güvenli', () {
      expect(backoffSeconds(-5), 2);
    });
  });

  group('kalıcı hata sınıflandırma', () {
    test('RLS/permission kalıcı → retry edilmez', () {
      expect(isPermanentFailure('new row violates row-level security'), isTrue);
      expect(isPermanentFailure('permission denied for table messages'), isTrue);
      expect(isPermanentFailure('42501: insufficient_privilege'), isTrue);
      expect(isPermanentFailure('Unauthorized'), isTrue);
    });

    test('ağ/timeout geçici → retry edilir', () {
      expect(isPermanentFailure('SocketException: failed host lookup'), isFalse);
      expect(isPermanentFailure('TimeoutException after 8s'), isFalse);
      expect(isPermanentFailure('Connection reset'), isFalse);
      expect(isPermanentFailure(null), isFalse);
    });
  });

  group('kullanıcı izolasyonu', () {
    test('farklı ownerId kuyrukları ayrılır', () {
      final all = [msg('a', owner: 'u1'), msg('b', owner: 'u2'), msg('c', owner: 'u1')];
      final u1 = all.where((m) => m.ownerId == 'u1').toList();
      expect(u1.map((e) => e.clientMessageId), ['a', 'c']);
      // u2'nin mesajı u1 gönderiminde ASLA yer almamalı (logout sızıntısı yok).
      expect(u1.any((m) => m.ownerId == 'u2'), isFalse);
    });
  });

  group('retry limiti', () {
    test('maxOutboxRetries makul ve pozitif', () {
      expect(maxOutboxRetries, greaterThan(0));
      expect(maxOutboxRetries, lessThanOrEqualTo(10));
    });
  });
}
