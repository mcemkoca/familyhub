import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';
import 'package:familyhub/features/context_memory/domain/memory_sync.dart';

/// Uzak senkron kuralları — migration 070 sonrası.
///
/// Not: gerçek Supabase çağrıları ağ/oturum gerektirir; burada GÖNDERİM
/// KARARLARI test edilir (hangi kayıt gider, hangisi ASLA gitmez).
void main() {
  MemoryRecord rec({
    String id = 'm1',
    String owner = 'u1',
    MemoryScope scope = MemoryScope.userPrivate,
    MemorySensitivity sensitivity = MemorySensitivity.normal,
    MemorySyncState sync = MemorySyncState.pendingCreate,
  }) =>
      MemoryRecord(
        id: id,
        userId: owner,
        scope: scope,
        kind: MemoryKind.preference,
        sensitivity: sensitivity,
        sourceType: MemorySourceType.userMessage,
        status: MemoryStatus.active,
        module: 'kitchen',
        key: 'k',
        title: 't',
        content: 'gizli içerik',
        normalizedContent: 'gizli icerik',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        sourceId: 's',
        syncState: sync,
      );

  group('KRİTİK: buluta gitmemesi gerekenler', () {
    test('deviceLocal kapsamı gönderilmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(scope: MemoryScope.deviceLocal),
            cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('session kapsamı gönderilmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(scope: MemoryScope.session), cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('credential gönderilmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(sensitivity: MemorySensitivity.credential),
            cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('kullanıcı bulut senkronunu kapattıysa hiçbir şey gitmez', () {
      expect(
        shouldSyncToCloud(record: rec(), cloudSyncEnabled: false),
        isFalse,
      );
    });
  });

  group('gönderilecekler', () {
    test('bekleyen oluşturma gönderilir', () {
      expect(shouldSyncToCloud(record: rec(), cloudSyncEnabled: true), isTrue);
    });

    test('bekleyen silme gönderilir (tombstone için)', () {
      expect(
        shouldSyncToCloud(
            record: rec(sync: MemorySyncState.pendingDelete),
            cloudSyncEnabled: true),
        isTrue,
      );
    });

    test('senkronlanmış kayıt tekrar gönderilmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(sync: MemorySyncState.synced), cloudSyncEnabled: true),
        isFalse,
      );
    });
  });

  group('hesap izolasyonu', () {
    test('KRİTİK: başka kullanıcının kaydı gönderim listesine girmez', () {
      final out = selectForSync(
        all: [rec(id: 'a', owner: 'u1'), rec(id: 'b', owner: 'u2')],
        ownerUserId: 'u1',
        cloudSyncEnabled: true,
      );
      expect(out.map((e) => e.id), ['a']);
    });
  });

  group('hassas kayıt şifreleme kuralı', () {
    test('sağlık verisi şifreleme gerektirir', () {
      expect(MemorySensitivity.health.requiresEncryption, isTrue);
    });

    test('çocuk verisi şifreleme gerektirir', () {
      expect(MemorySensitivity.minorData.requiresEncryption, isTrue);
    });

    test('normal veri şifreleme gerektirmez', () {
      expect(MemorySensitivity.normal.requiresEncryption, isFalse);
    });
  });

  group('hata sonrası durum', () {
    test('RLS hatası kalıcı → failed (sonsuz deneme yok)', () {
      expect(
        nextSyncState(
            success: false,
            attempt: 0,
            error: 'new row violates row-level security policy'),
        MemorySyncState.failed,
      );
    });

    test('ağ hatası geçici → tekrar denenir', () {
      expect(
        nextSyncState(success: false, attempt: 0, error: 'SocketException'),
        MemorySyncState.pendingCreate,
      );
    });

    test('başarı → synced', () {
      expect(nextSyncState(success: true, attempt: 0), MemorySyncState.synced);
    });
  });
}
