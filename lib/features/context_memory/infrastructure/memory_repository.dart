/// Context Memory — Faz 7: yerel kalıcı depo (Hive) + pipeline yürütücü.
///
/// Faz 1-6'daki SAF politika/retrieval fonksiyonlarını gerçek depolamaya
/// bağlar. Kullanıcı izolasyonu [MemoryKeyspace] ile zorunludur: bir kullanıcı
/// başka kullanıcının kaydını OKUYAMAZ (hesap değişimi sızıntısı yok).
library;

import 'dart:convert';

import '../../../core/app_logger.dart';
import '../../../services/hive_service.dart';
import '../domain/memory_enums.dart';
import '../domain/memory_event.dart';
import '../domain/memory_policy.dart';
import '../domain/memory_reconciler.dart';
import '../domain/memory_record.dart';
import '../domain/memory_retrieval.dart';
import 'memory_keyspace.dart';

/// Yerel memory deposu.
///
/// Not: mevcut `HiveService` settings box'ı üzerinde JSON liste tutar
/// (ek bağımlılık yok). Kayıt sayısı büyürse ayrı box'a taşınabilir —
/// arayüz aynı kalır.
class MemoryRepository {
  MemoryRepository._();
  static final MemoryRepository instance = MemoryRepository._();

  static const _storeKey = 'context_memory_records_v1';

  /// Daima DEĞİŞTİRİLEBİLİR liste döner (çağıranlar üzerinde mutasyon yapar).
  List<MemoryRecord> _readAll() {
    try {
      final raw = HiveService.getSetting(_storeKey);
      if (raw == null || raw.isEmpty) return <MemoryRecord>[];
      final data = jsonDecode(raw);
      if (data is! List) return <MemoryRecord>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(MemoryRecord.fromJson)
          .toList();
    } catch (e) {
      // Bozuk kalıcı veri uygulamayı çökertmemeli.
      AppLogger.logBestEffort(e, module: 'memory', operation: 'readAll');
      return <MemoryRecord>[];
    }
  }

  Future<void> _writeAll(List<MemoryRecord> records) async {
    await HiveService.setSetting(
      _storeKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  /// Yalnızca [userId]'ye ait kayıtlar (izolasyon zorunlu).
  List<MemoryRecord> recordsFor(String? userId) {
    if (userId == null || userId.isEmpty) return const [];
    return _readAll().where((r) => r.userId == userId).toList();
  }

  Future<void> save(MemoryRecord record) async {
    final all = _readAll();
    final i = all.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      all[i] = record;
    } else {
      all.add(record);
    }
    await _writeAll(all);
  }

  Future<void> saveAll(List<MemoryRecord> records) async {
    final all = _readAll();
    for (final rec in records) {
      final i = all.indexWhere((r) => r.id == rec.id);
      if (i >= 0) {
        all[i] = rec;
      } else {
        all.add(rec);
      }
    }
    await _writeAll(all);
  }

  /// Soft delete + tombstone (senkron sonrası geri gelmez).
  Future<void> softDelete(String id, {required DateTime now}) async {
    final all = _readAll();
    final i = all.indexWhere((r) => r.id == id);
    if (i < 0) return;
    all[i] = all[i].copyWith(
      status: MemoryStatus.deleted,
      deletedAt: now,
      updatedAt: now,
      syncState: MemorySyncState.pendingDelete,
    );
    await _writeAll(all);
  }

  /// Kullanıcı çıkışı / hesap silme: o kullanıcının TÜM kayıtlarını siler.
  Future<int> purgeUser(String userId) async {
    final all = _readAll();
    final before = all.length;
    all.removeWhere((r) => r.userId == userId);
    await _writeAll(all);
    return before - all.length;
  }
}

/// Modül olaylarını memory'ye dönüştüren pipeline yürütücüsü.
///
/// Zincir: politika → kapsam/hassasiyet → dedup/çelişki → kayıt.
/// Politika reddederse HİÇBİR ŞEY saklanmaz.
class MemoryIngestionService {
  MemoryIngestionService({
    MemoryRepository? repository,
    this.consent = const MemoryConsentSnapshot(),
  }) : _repo = repository ?? MemoryRepository.instance;

  final MemoryRepository _repo;
  final MemoryConsentSnapshot consent;

  /// Bir olayı işler ve kabul edilen kayıtları döndürür.
  Future<MemoryIngestionResult> ingest(
    MemoryEvent event,
    List<MemoryCandidate> candidates, {
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final accepted = <MemoryCandidate>[];
    final rejected = <String, String>{};
    final toSave = <MemoryRecord>[];

    for (final c in candidates) {
      // 1) Saklama politikası (credential yasağı, consent, güven eşiği).
      final decision = evaluateStoragePolicy(
        kind: c.kind,
        sensitivity: c.sensitivity,
        scope: c.scope,
        sourceType: c.sourceType,
        confidence: c.confidence,
        module: c.module,
        consent: consent,
        explicitRememberRequest: event.explicitRememberRequest,
      );
      if (!decision.allowed) {
        rejected[c.key] = decision.reason;
        continue;
      }

      final normalized = normalizeMemoryContent(c.content);

      // 2) Aynı özne için mevcut kayıtlar (dedup/çelişki).
      final existing = _repo
          .recordsFor(event.userId)
          .where((r) =>
              r.module == c.module &&
              r.key == c.key &&
              (r.childId ?? r.memberId ?? r.userId) ==
                  (event.childId ?? event.memberId ?? event.userId))
          .toList();

      final rec = reconcile(
        candidate: c,
        existing: existing,
        candidateNormalizedContent: normalized,
      );

      if (rec.action == ReconcileAction.skipDuplicate) {
        rejected[c.key] = 'duplicate';
        continue;
      }

      // 3) Çelişkili ise disputed olarak saklanır (bağlama girmez).
      final status = rec.action == ReconcileAction.dispute
          ? MemoryStatus.disputed
          : MemoryStatus.active;

      // 4) Eski kaydı superseded yap (SİLME — audit korunur).
      if (rec.action == ReconcileAction.supersede &&
          rec.targetMemoryId != null) {
        final old = existing.firstWhere((r) => r.id == rec.targetMemoryId);
        toSave.add(markSuperseded(old, now: ts));
      }

      final id = '${event.id}_${c.key}_${ts.microsecondsSinceEpoch}';
      var record = MemoryRecord(
        id: id,
        userId: event.userId,
        familyId: event.familyId,
        memberId: event.memberId,
        childId: event.childId,
        conversationId: event.conversationId,
        scope: c.scope,
        kind: c.kind,
        sensitivity: c.sensitivity,
        sourceType: c.sourceType,
        status: status,
        module: c.module,
        key: c.key,
        title: c.title,
        content: c.content,
        normalizedContent: normalized,
        structuredData: c.structuredData,
        confidence: c.confidence,
        importance: c.importance,
        explicit: c.explicit,
        encrypted: decision.requiresEncryption,
        occurredAt: event.occurredAt,
        createdAt: ts,
        updatedAt: ts,
        expiresAt: decision.retention == null ? null : ts.add(decision.retention!),
        sourceId: event.sourceId,
        syncState: c.scope.isSyncable
            ? MemorySyncState.pendingCreate
            : MemorySyncState.localOnly,
      );

      if (rec.action == ReconcileAction.supersede &&
          rec.targetMemoryId != null) {
        record = linkSupersedes(record, [rec.targetMemoryId!]);
      }

      toSave.add(record);
      accepted.add(c);
    }

    if (toSave.isNotEmpty) await _repo.saveAll(toSave);
    return MemoryIngestionResult(accepted: accepted, rejected: rejected);
  }

  /// "Bunu unut" — yalnızca istek sahibinin kayıtları silinir.
  Future<int> forget({
    required String userId,
    required String query,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final targets = selectForForget(
      candidates: _repo.recordsFor(userId),
      requesterUserId: userId,
      normalizedQuery: normalizeMemoryContent(query),
    );
    for (final t in targets) {
      await _repo.softDelete(t.id, now: ts);
    }
    return targets.length;
  }
}

/// AI'a gönderilecek bağlamı üretir (retrieval + bütçe + prompt).
class MemoryContextService {
  MemoryContextService({MemoryRepository? repository})
      : _repo = repository ?? MemoryRepository.instance;

  final MemoryRepository _repo;

  /// Sorgu için izinli, bütçelenmiş bağlam paketi.
  MemoryContextPacket buildPacket({
    required String userId,
    required String query,
    Set<String> modules = const {},
    String? childId,
    bool viewerIsParentOrAdmin = false,
    ContextBudget budget = const ContextBudget(),
    DateTime? now,
  }) {
    final records = _repo.recordsFor(userId);
    if (records.isEmpty) return const MemoryContextPacket();

    final ranked = retrieveAndRank(
      all: records,
      query: MemoryQuery(
        normalizedQuery: normalizeMemoryContent(query),
        viewerUserId: userId,
        now: now ?? DateTime.now(),
        modules: modules,
        childId: childId,
        viewerIsParentOrAdmin: viewerIsParentOrAdmin,
      ),
    );
    return buildContextPacket(ranked: ranked, budget: budget);
  }
}
