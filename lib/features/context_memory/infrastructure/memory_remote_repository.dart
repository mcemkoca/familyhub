/// Context Memory — uzak depo (Supabase) ve senkron yürütücü.
///
/// Migration 070 (`context_memories`, `context_memory_tombstones`,
/// `context_memory_consents`) canlıya uygulandı.
///
/// GÜVENLİK:
///  - Hassas içerik `content_encrypted` alanına ŞİFRELİ yazılır; `search_text`
///    yalnızca hassas OLMAYAN kayıtlarda doldurulur.
///  - `deviceLocal`/`session` kapsamları buluta HİÇ gönderilmez (shouldSyncToCloud).
///  - `family_id` sunucuda RLS ile `family_members` üzerinden doğrulanır.
library;

import '../../../core/app_logger.dart';
import '../../../services/auth_service.dart';
import '../domain/memory_enums.dart';
import '../domain/memory_record.dart';
import '../domain/memory_sync.dart';
import 'memory_crypto.dart';
import 'memory_repository.dart';

class MemoryRemoteRepository {
  MemoryRemoteRepository._();
  static final MemoryRemoteRepository instance = MemoryRemoteRepository._();

  static const _table = 'context_memories';
  static const _tombstones = 'context_memory_tombstones';

  /// Kaydı sunucu satırına çevirir. Hassas ise içerik şifrelenir.
  ///
  /// Şifreleme başarısızsa `null` döner — düz metin ASLA gönderilmez.
  Future<Map<String, dynamic>?> _toRow(MemoryRecord r) async {
    final needsEncryption = r.sensitivity.requiresEncryption;

    String? encrypted;
    if (needsEncryption) {
      encrypted = await MemoryCrypto.instance.encrypt(r.content);
      if (encrypted == null) {
        AppLogger.logError(
          StateError('encrypt_failed'),
          module: 'memory',
          operation: 'toRow',
        );
        return null; // gönderme — gizlilik korunur
      }
    }

    return {
      'id': r.id,
      'user_id': r.userId,
      'family_id': r.familyId,
      'member_id': r.memberId,
      'child_id': r.childId,
      'conversation_id': r.conversationId,
      'scope': r.scope.name,
      'kind': r.kind.name,
      'sensitivity': r.sensitivity.name,
      'source_type': r.sourceType.name,
      'status': r.status.name,
      'module': r.module,
      'memory_key': r.key,
      'title': r.title,
      'content_encrypted': encrypted ?? r.content,
      'structured_data': r.structuredData,
      // Hassas kayıtta arama metni SUNUCUDA tutulmaz.
      'search_text': needsEncryption ? null : r.normalizedContent,
      'keywords': r.keywords,
      'supersedes_memory_ids': r.supersedesMemoryIds,
      'allowed_user_ids': r.allowedUserIds,
      'denied_user_ids': r.deniedUserIds,
      'confidence': r.confidence,
      'importance': r.importance,
      'is_explicit': r.explicit,
      'is_confirmed': r.confirmed,
      'is_pinned': r.pinned,
      'occurred_at': r.occurredAt?.toIso8601String(),
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
      'expires_at': r.expiresAt?.toIso8601String(),
      'deleted_at': r.deletedAt?.toIso8601String(),
      'access_count': r.accessCount,
      'schema_version': r.schemaVersion,
      'source_id': r.sourceId,
    };
  }

  /// Bir kaydı sunucuya yazar (upsert). Başarılıysa true.
  Future<bool> push(MemoryRecord record) async {
    final client = AuthService.safeClient;
    if (client == null) return false;
    try {
      if (record.syncState == MemorySyncState.pendingDelete) {
        // Silme: tombstone + satır silme (geri gelmesin).
        await client.from(_tombstones).upsert({
          'memory_id': record.id,
          'user_id': record.userId,
          'family_id': record.familyId,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        });
        await client.from(_table).delete().eq('id', record.id);
        return true;
      }

      final row = await _toRow(record);
      if (row == null) return false; // şifreleme başarısız → gönderme
      await client.from(_table).upsert(row);
      return true;
    } catch (e) {
      // İçerik loglanmaz — yalnızca işlem.
      AppLogger.logBestEffort(e, module: 'memory', operation: 'push');
      rethrow; // çağıran hata sınıfına göre retry kararı verir
    }
  }

  /// Sunucudaki tombstone id'lerini getirir (silinen geri gelmesin).
  Future<Set<String>> fetchTombstones(String userId) async {
    final client = AuthService.safeClient;
    if (client == null) return const {};
    try {
      final rows = await client
          .from(_tombstones)
          .select('memory_id')
          .eq('user_id', userId);
      return (rows as List)
          .map((e) => (e as Map)['memory_id'].toString())
          .toSet();
    } catch (e) {
      AppLogger.logBestEffort(e, module: 'memory', operation: 'fetchTombstones');
      return const {};
    }
  }
}

/// Bekleyen kayıtları sunucuya gönderir (offline-first).
///
/// - Yalnızca oturum sahibinin kayıtları (hesap sızıntısı yok),
/// - Kalıcı hatada (RLS/yetki) sonsuz deneme YOK,
/// - Aynı anda tek çalışır.
class MemorySyncWorker {
  MemorySyncWorker._();
  static final MemorySyncWorker instance = MemorySyncWorker._();

  bool _running = false;

  /// Döndürülen: (gönderilen, başarısız) sayısı.
  Future<({int pushed, int failed})> sync({
    required bool cloudSyncEnabled,
    int limit = 50,
  }) async {
    if (_running) return (pushed: 0, failed: 0);
    final userId = AuthService.currentUserId;
    if (userId == null || !cloudSyncEnabled) return (pushed: 0, failed: 0);

    _running = true;
    var pushed = 0;
    var failed = 0;
    try {
      final pending = selectForSync(
        all: MemoryRepository.instance.recordsFor(userId),
        ownerUserId: userId,
        cloudSyncEnabled: cloudSyncEnabled,
        limit: limit,
      );

      for (final rec in pending) {
        try {
          final ok = await MemoryRemoteRepository.instance.push(rec);
          if (ok) {
            pushed++;
            await MemoryRepository.instance.save(
              rec.copyWith(syncState: MemorySyncState.synced),
            );
          } else {
            failed++;
            await MemoryRepository.instance.save(
              rec.copyWith(syncState: MemorySyncState.failed),
            );
          }
        } catch (e) {
          failed++;
          // Kalıcı hata → failed; geçici → tekrar denenecek.
          final next = nextSyncState(
            success: false,
            attempt: 0,
            error: e.toString(),
          );
          await MemoryRepository.instance.save(rec.copyWith(syncState: next));
        }
      }
    } finally {
      _running = false;
    }
    return (pushed: pushed, failed: failed);
  }
}
