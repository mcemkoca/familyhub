/// Context Memory — Faz 9: senkronizasyon, çakışma ve dayanıklılık.
///
/// Offline-first: yerel yazma → kuyruk → yeniden deneme → sunucu onayı.
/// Tümü SAF fonksiyondur; ağ katmanı bunları kullanır.
library;

import 'memory_enums.dart';
import 'memory_record.dart';

/// Bir kaydın buluta gönderilip gönderilmeyeceği.
///
/// KRİTİK: `deviceLocal` ve `session` kapsamları buluta ASLA gitmez
/// (prompt §13 — bu değerler sunucu CHECK kısıtında da yoktur).
bool shouldSyncToCloud({
  required MemoryRecord record,
  required bool cloudSyncEnabled,
}) {
  if (!cloudSyncEnabled) return false;
  if (!record.scope.isSyncable) return false;
  // Kimlik bilgisi hiçbir koşulda gönderilmez (zaten saklanmamalı).
  if (record.sensitivity.isNeverStorable) return false;
  return switch (record.syncState) {
    MemorySyncState.pendingCreate ||
    MemorySyncState.pendingUpdate ||
    MemorySyncState.pendingDelete =>
      true,
    MemorySyncState.localOnly ||
    MemorySyncState.synced ||
    MemorySyncState.conflict ||
    MemorySyncState.failed =>
      false,
  };
}

/// Gönderilecek kayıtları seçer — YALNIZCA [ownerUserId]'ye ait olanlar.
///
/// Hesap değişiminde önceki kullanıcının bekleyen kayıtları yeni kullanıcı
/// adına gönderilmez (chat outbox'taki aynı güvenlik kuralı).
List<MemoryRecord> selectForSync({
  required List<MemoryRecord> all,
  required String ownerUserId,
  required bool cloudSyncEnabled,
  int limit = 50,
}) {
  final out = <MemoryRecord>[];
  for (final r in all) {
    if (r.userId != ownerUserId) continue;
    if (!shouldSyncToCloud(record: r, cloudSyncEnabled: cloudSyncEnabled)) {
      continue;
    }
    out.add(r);
    if (out.length >= limit) break;
  }
  return out;
}

/// Uzak ve yerel sürüm çakıştığında hangisi kazanır?
///
/// Öncelik: kaynak otoritesi → daha yeni güncelleme. Kullanıcı düzeltmesi
/// sunucudaki eski kaydı ezebilir; AI çıkarımı kullanıcı beyanını EZEMEZ.
enum SyncConflictWinner { local, remote, unresolved }

SyncConflictWinner resolveSyncConflict({
  required MemorySourceType localSource,
  required DateTime localUpdatedAt,
  required MemorySourceType remoteSource,
  required DateTime remoteUpdatedAt,
}) {
  final a = localSource.authority;
  final b = remoteSource.authority;
  if (a != b) return a > b ? SyncConflictWinner.local : SyncConflictWinner.remote;
  if (localUpdatedAt.isAfter(remoteUpdatedAt)) return SyncConflictWinner.local;
  if (remoteUpdatedAt.isAfter(localUpdatedAt)) return SyncConflictWinner.remote;
  // Aynı otorite + aynı zaman → körlemesine ezme, kullanıcıya bırak.
  return SyncConflictWinner.unresolved;
}

/// Silinen kayıt senkron sonrası GERİ GELMEMELİ (prompt §8).
///
/// Sunucudan gelen kayıt, yerel tombstone listesindeyse yok sayılır.
bool isTombstoned({
  required String remoteMemoryId,
  required Set<String> tombstoneIds,
}) =>
    tombstoneIds.contains(remoteMemoryId);

/// Sunucudan gelen kayıtları yerelle birleştirir.
///
/// - Tombstone'daki kayıtlar atlanır (geri gelmez),
/// - Başka kullanıcının kaydı ASLA alınmaz,
/// - Çakışmada [resolveSyncConflict] kararı uygulanır.
List<MemoryRecord> mergeRemoteRecords({
  required List<MemoryRecord> local,
  required List<MemoryRecord> remote,
  required String ownerUserId,
  required Set<String> tombstoneIds,
}) {
  final byId = {for (final r in local) r.id: r};

  for (final rem in remote) {
    // Kullanıcı izolasyonu — başka hesabın kaydı yerele yazılmaz.
    if (rem.userId != ownerUserId) continue;
    if (isTombstoned(remoteMemoryId: rem.id, tombstoneIds: tombstoneIds)) {
      continue;
    }

    final loc = byId[rem.id];
    if (loc == null) {
      byId[rem.id] = rem.copyWith(syncState: MemorySyncState.synced);
      continue;
    }

    final winner = resolveSyncConflict(
      localSource: loc.sourceType,
      localUpdatedAt: loc.updatedAt,
      remoteSource: rem.sourceType,
      remoteUpdatedAt: rem.updatedAt,
    );

    byId[rem.id] = switch (winner) {
      SyncConflictWinner.remote =>
        rem.copyWith(syncState: MemorySyncState.synced),
      SyncConflictWinner.local => loc,
      // Çözülemedi: veri kaybetme, işaretle ve kullanıcıya bırak.
      SyncConflictWinner.unresolved =>
        loc.copyWith(syncState: MemorySyncState.conflict),
    };
  }

  return byId.values.toList();
}

/// Yeniden deneme gecikmesi (sn): 2, 5, 15, 30, 60 — üst sınır 60.
int syncBackoffSeconds(int attempt) {
  const steps = [2, 5, 15, 30, 60];
  if (attempt < 0) return steps.first;
  if (attempt >= steps.length) return steps.last;
  return steps[attempt];
}

/// Kalıcı hata mı? (RLS/yetki → sonsuz deneme YAPILMAZ)
bool isPermanentSyncFailure(String? error) {
  if (error == null) return false;
  final e = error.toLowerCase();
  return e.contains('row-level security') ||
      e.contains('permission denied') ||
      e.contains('42501') ||
      e.contains('violates') ||
      e.contains('unauthorized') ||
      e.contains('forbidden');
}

/// Maksimum deneme; aşılırsa kayıt `failed` olur (sessiz sonsuz döngü yok).
const int maxSyncAttempts = 6;

/// Bir denemenin sonucuna göre kaydın yeni senkron durumu.
MemorySyncState nextSyncState({
  required bool success,
  required int attempt,
  String? error,
}) {
  if (success) return MemorySyncState.synced;
  if (isPermanentSyncFailure(error)) return MemorySyncState.failed;
  if (attempt + 1 >= maxSyncAttempts) return MemorySyncState.failed;
  return MemorySyncState.pendingCreate; // yeniden denenecek
}
