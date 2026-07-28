/// Context Memory — Faz 4: tekrar (dedup) ve çelişki çözümü.
///
/// Saf fonksiyonlar. Kullanıcı bir bilgiyi düzeltince ESKİ KAYIT SİLİNMEZ;
/// `superseded` yapılır ve ilişki kurulur (prompt §7 — audit trail korunur).
library;

import 'memory_enums.dart';
import 'memory_event.dart';
import 'memory_record.dart';

/// Bir adayın mevcut kayıtlarla ilişkisi.
enum ReconcileAction {
  /// Yeni kayıt oluştur.
  create,

  /// Aynı bilgi zaten var — hiçbir şey yapma (duplicate üretme).
  skipDuplicate,

  /// Mevcut kaydı güncelle (aynı anahtar, yeni değer, aynı otorite).
  update,

  /// Mevcut kaydı `superseded` yap, yenisini oluştur (düzeltme).
  supersede,

  /// Çelişki çözülemedi — `disputed` işaretle, AI bağlamına ALMA.
  dispute,
}

class ReconcileDecision {
  final ReconcileAction action;
  final String? targetMemoryId;
  final String reason;

  const ReconcileDecision({
    required this.action,
    required this.reason,
    this.targetMemoryId,
  });
}

/// Aday ile mevcut kayıtlar arasında ne yapılacağına karar verir.
///
/// [existing] aynı `dedupKey`'e sahip AKTİF kayıtlar olmalıdır.
ReconcileDecision reconcile({
  required MemoryCandidate candidate,
  required List<MemoryRecord> existing,
  required String candidateNormalizedContent,
}) {
  final active = existing
      .where((r) => r.status == MemoryStatus.active && r.deletedAt == null)
      .toList();

  if (active.isEmpty) {
    return const ReconcileDecision(
      action: ReconcileAction.create,
      reason: 'no_existing_record',
    );
  }

  // Aynı içerik → duplicate üretme.
  for (final r in active) {
    if (r.normalizedContent == candidateNormalizedContent) {
      return ReconcileDecision(
        action: ReconcileAction.skipDuplicate,
        targetMemoryId: r.id,
        reason: 'identical_content',
      );
    }
  }

  // İçerik farklı → çelişki. Otoriteye göre karar ver.
  final current = active.first;
  final candidateAuthority = candidate.sourceType.authority;
  final existingAuthority = current.sourceType.authority;

  if (candidateAuthority > existingAuthority) {
    // Kullanıcı düzeltmesi eski bilgiyi geçersiz kılar (SİLMEZ).
    return ReconcileDecision(
      action: ReconcileAction.supersede,
      targetMemoryId: current.id,
      reason: 'higher_authority:${candidate.sourceType.name}',
    );
  }

  if (candidateAuthority == existingAuthority) {
    // Aynı otorite: daha yeni bilgi geçerli sayılır (güncelle).
    return ReconcileDecision(
      action: ReconcileAction.update,
      targetMemoryId: current.id,
      reason: 'same_authority_newer_value',
    );
  }

  // Aday daha düşük otoriteli (ör. AI çıkarımı vs kullanıcı beyanı).
  // Sessizce ezmek YANLIŞ olur; ama kesin bilgi gibi de sunulamaz.
  return ReconcileDecision(
    action: ReconcileAction.dispute,
    targetMemoryId: current.id,
    reason: 'lower_authority_conflict',
  );
}

/// Bir kaydı `superseded` durumuna geçirir (silmez — audit korunur).
MemoryRecord markSuperseded(MemoryRecord record, {required DateTime now}) {
  return record.copyWith(
    status: MemoryStatus.superseded,
    updatedAt: now,
    syncState: MemorySyncState.pendingUpdate,
  );
}

/// Yeni kaydın hangi kayıtları geçersiz kıldığını işaretler.
MemoryRecord linkSupersedes(MemoryRecord record, List<String> supersededIds) {
  if (supersededIds.isEmpty) return record;
  return record.copyWith(
    supersedesMemoryIds: [...record.supersedesMemoryIds, ...supersededIds],
  );
}

/// "Bunu unut" isteği için silinecek kayıtları seçer (prompt §8).
///
/// Yalnızca ISTEK SAHIBININ erişebildiği kayıtlar silinebilir; başka üyenin
/// özel kaydı bu yolla silinemez.
List<MemoryRecord> selectForForget({
  required List<MemoryRecord> candidates,
  required String requesterUserId,
  required String normalizedQuery,
}) {
  if (normalizedQuery.trim().isEmpty) return const [];
  return candidates.where((r) {
    if (r.deletedAt != null) return false;
    // Sahiplik: yalnızca kendi kaydı veya açıkça izinli olduğu kayıt.
    final owns = r.userId == requesterUserId ||
        r.allowedUserIds.contains(requesterUserId);
    if (!owns) return false;
    return r.normalizedContent.contains(normalizedQuery) ||
        r.key.contains(normalizedQuery) ||
        r.keywords.any((k) => k.contains(normalizedQuery));
  }).toList();
}
