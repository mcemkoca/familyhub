import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';
import 'package:familyhub/features/context_memory/domain/memory_record.dart';
import 'package:familyhub/features/context_memory/domain/memory_sync.dart';

/// Context Memory Faz 9 — senkron seçimi, çakışma, tombstone, backoff.
void main() {
  MemoryRecord rec({
    String id = 'm1',
    String owner = 'u1',
    MemoryScope scope = MemoryScope.userPrivate,
    MemorySensitivity sensitivity = MemorySensitivity.normal,
    MemorySyncState sync = MemorySyncState.pendingCreate,
    MemorySourceType source = MemorySourceType.userMessage,
    DateTime? updatedAt,
  }) =>
      MemoryRecord(
        id: id,
        userId: owner,
        scope: scope,
        kind: MemoryKind.preference,
        sensitivity: sensitivity,
        sourceType: source,
        status: MemoryStatus.active,
        module: 'kitchen',
        key: 'k',
        title: 't',
        content: 'c',
        normalizedContent: 'c',
        createdAt: DateTime.utc(2026),
        updatedAt: updatedAt ?? DateTime.utc(2026, 7, 1),
        sourceId: 's',
        syncState: sync,
      );

  group('shouldSyncToCloud', () {
    test('bekleyen kayıt gönderilir', () {
      expect(shouldSyncToCloud(record: rec(), cloudSyncEnabled: true), isTrue);
    });

    test('bulut senkronu kapalıysa gönderilmez', () {
      expect(shouldSyncToCloud(record: rec(), cloudSyncEnabled: false), isFalse);
    });

    test('KRİTİK: deviceLocal kapsamı buluta ASLA gitmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(scope: MemoryScope.deviceLocal),
            cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('KRİTİK: session kapsamı buluta ASLA gitmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(scope: MemoryScope.session), cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('KRİTİK: credential buluta gitmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(sensitivity: MemorySensitivity.credential),
            cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('zaten senkronlanmış kayıt tekrar gönderilmez', () {
      expect(
        shouldSyncToCloud(
            record: rec(sync: MemorySyncState.synced), cloudSyncEnabled: true),
        isFalse,
      );
    });

    test('silme işlemi de senkronlanır', () {
      expect(
        shouldSyncToCloud(
            record: rec(sync: MemorySyncState.pendingDelete),
            cloudSyncEnabled: true),
        isTrue,
      );
    });
  });

  group('selectForSync — kullanıcı izolasyonu', () {
    test('KRİTİK: başka kullanıcının kaydı gönderilmez', () {
      final out = selectForSync(
        all: [rec(id: 'a', owner: 'u1'), rec(id: 'b', owner: 'u2')],
        ownerUserId: 'u1',
        cloudSyncEnabled: true,
      );
      expect(out.length, 1);
      expect(out.single.id, 'a');
    });

    test('limit aşılmaz', () {
      final all = List.generate(100, (i) => rec(id: 'm$i'));
      final out = selectForSync(
          all: all, ownerUserId: 'u1', cloudSyncEnabled: true, limit: 10);
      expect(out.length, 10);
    });
  });

  group('resolveSyncConflict', () {
    test('KRİTİK: kullanıcı düzeltmesi AI çıkarımını yener', () {
      expect(
        resolveSyncConflict(
          localSource: MemorySourceType.userCorrection,
          localUpdatedAt: DateTime.utc(2026, 1, 1),
          remoteSource: MemorySourceType.aiDerived,
          remoteUpdatedAt: DateTime.utc(2026, 12, 31), // daha yeni ama zayıf
        ),
        SyncConflictWinner.local,
      );
    });

    test('KRİTİK: AI çıkarımı kullanıcı beyanını EZEMEZ', () {
      expect(
        resolveSyncConflict(
          localSource: MemorySourceType.aiDerived,
          localUpdatedAt: DateTime.utc(2026, 12, 31),
          remoteSource: MemorySourceType.userMessage,
          remoteUpdatedAt: DateTime.utc(2026, 1, 1),
        ),
        SyncConflictWinner.remote,
      );
    });

    test('aynı otoritede daha yeni kazanır', () {
      expect(
        resolveSyncConflict(
          localSource: MemorySourceType.userMessage,
          localUpdatedAt: DateTime.utc(2026, 7, 2),
          remoteSource: MemorySourceType.userMessage,
          remoteUpdatedAt: DateTime.utc(2026, 7, 1),
        ),
        SyncConflictWinner.local,
      );
    });

    test('tam eşitlikte körlemesine ezme yok → unresolved', () {
      final t = DateTime.utc(2026, 7, 1);
      expect(
        resolveSyncConflict(
          localSource: MemorySourceType.userMessage,
          localUpdatedAt: t,
          remoteSource: MemorySourceType.userMessage,
          remoteUpdatedAt: t,
        ),
        SyncConflictWinner.unresolved,
      );
    });
  });

  group('mergeRemoteRecords', () {
    test('yeni uzak kayıt eklenir ve synced işaretlenir', () {
      final merged = mergeRemoteRecords(
        local: [],
        remote: [rec(id: 'r1')],
        ownerUserId: 'u1',
        tombstoneIds: const {},
      );
      expect(merged.single.id, 'r1');
      expect(merged.single.syncState, MemorySyncState.synced);
    });

    test('KRİTİK: silinen kayıt senkron sonrası GERİ GELMEZ', () {
      final merged = mergeRemoteRecords(
        local: [],
        remote: [rec(id: 'deleted1')],
        ownerUserId: 'u1',
        tombstoneIds: {'deleted1'},
      );
      expect(merged, isEmpty);
    });

    test('KRİTİK: başka kullanıcının uzak kaydı yerele yazılmaz', () {
      final merged = mergeRemoteRecords(
        local: [],
        remote: [rec(id: 'x', owner: 'u2')],
        ownerUserId: 'u1',
        tombstoneIds: const {},
      );
      expect(merged, isEmpty);
    });

    test('çakışmada yerel düzeltme korunur', () {
      final local = rec(
          id: 'same',
          source: MemorySourceType.userCorrection,
          updatedAt: DateTime.utc(2026, 1, 1));
      final remote = rec(
          id: 'same',
          source: MemorySourceType.aiDerived,
          updatedAt: DateTime.utc(2026, 12, 1));
      final merged = mergeRemoteRecords(
        local: [local],
        remote: [remote],
        ownerUserId: 'u1',
        tombstoneIds: const {},
      );
      expect(merged.single.sourceType, MemorySourceType.userCorrection);
    });

    test('çözülemeyen çakışma conflict olarak işaretlenir (veri kaybı yok)', () {
      final t = DateTime.utc(2026, 7, 1);
      final merged = mergeRemoteRecords(
        local: [rec(id: 'same', updatedAt: t)],
        remote: [rec(id: 'same', updatedAt: t)],
        ownerUserId: 'u1',
        tombstoneIds: const {},
      );
      expect(merged.single.syncState, MemorySyncState.conflict);
    });
  });

  group('backoff ve hata sınıflandırma', () {
    test('exponential adımlar', () {
      expect(syncBackoffSeconds(0), 2);
      expect(syncBackoffSeconds(3), 30);
    });

    test('üst sınırda sabit (sonsuz büyümez)', () {
      expect(syncBackoffSeconds(99), 60);
    });

    test('RLS/yetki hatası kalıcı — sonsuz deneme yok', () {
      expect(isPermanentSyncFailure('new row violates row-level security'),
          isTrue);
      expect(isPermanentSyncFailure('permission denied'), isTrue);
    });

    test('ağ hatası geçici — yeniden denenir', () {
      expect(isPermanentSyncFailure('SocketException'), isFalse);
      expect(isPermanentSyncFailure(null), isFalse);
    });

    test('nextSyncState: başarı → synced', () {
      expect(nextSyncState(success: true, attempt: 0), MemorySyncState.synced);
    });

    test('nextSyncState: kalıcı hata → failed (retry yok)', () {
      expect(
        nextSyncState(
            success: false, attempt: 0, error: 'permission denied'),
        MemorySyncState.failed,
      );
    });

    test('nextSyncState: max denemede failed', () {
      expect(
        nextSyncState(
            success: false, attempt: maxSyncAttempts - 1, error: 'network'),
        MemorySyncState.failed,
      );
    });

    test('nextSyncState: geçici hata → tekrar denenecek', () {
      expect(
        nextSyncState(success: false, attempt: 0, error: 'timeout'),
        MemorySyncState.pendingCreate,
      );
    });
  });
}
