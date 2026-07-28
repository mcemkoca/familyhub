/// Context Memory — Faz 5: retrieval, sıralama ve Context Builder.
///
/// AI'a TÜM hafıza gönderilmez. Bu katman: izin filtresi → durum/süre filtresi
/// → alaka sıralaması → token bütçesi → yapılandırılmış context packet üretir
/// (prompt §9). Tüm fonksiyonlar saftır.
library;

import 'memory_enums.dart';
import 'memory_policy.dart';
import 'memory_record.dart';

/// Retrieval sorgusu.
class MemoryQuery {
  final String normalizedQuery;
  final String viewerUserId;
  final bool viewerIsSameFamily;
  final bool viewerIsParentOrAdmin;

  /// Sorguyla ilgili modüller (boşsa tüm modüller).
  final Set<String> modules;

  /// Belirli bir çocuk bağlamı isteniyorsa (diğer çocuklar elenir).
  final String? childId;

  final DateTime now;

  const MemoryQuery({
    required this.normalizedQuery,
    required this.viewerUserId,
    required this.now,
    this.viewerIsSameFamily = true,
    this.viewerIsParentOrAdmin = false,
    this.modules = const {},
    this.childId,
  });
}

/// Sıralanmış tek sonuç.
class MemorySearchResult {
  final MemoryRecord record;
  final double score;
  const MemorySearchResult({required this.record, required this.score});
}

/// AI'a giden token bütçesi (prompt §9.5).
class ContextBudget {
  final int maxCharacters;
  final int maxMemories;

  const ContextBudget({
    this.maxCharacters = 4000,
    this.maxMemories = 25,
  });
}

/// Yapılandırılmış bağlam paketi — serbest metin yığını DEĞİL.
class MemoryContextPacket {
  /// Kritik kısıtlar (alerji, sağlık) — bütçe dolsa bile ilk sıradadır.
  final List<MemoryRecord> restrictions;
  final List<MemoryRecord> confirmedFacts;
  final List<MemoryRecord> preferences;
  final List<MemoryRecord> recentEvents;

  /// Çözülemeyen çelişkiler — AI'a "kesin bilgi" olarak SUNULMAZ.
  final List<MemoryRecord> unresolvedConflicts;

  final int usedCharacters;
  final int droppedCount;

  const MemoryContextPacket({
    this.restrictions = const [],
    this.confirmedFacts = const [],
    this.preferences = const [],
    this.recentEvents = const [],
    this.unresolvedConflicts = const [],
    this.usedCharacters = 0,
    this.droppedCount = 0,
  });

  int get totalIncluded =>
      restrictions.length +
      confirmedFacts.length +
      preferences.length +
      recentEvents.length;

  bool get isEmpty => totalIncluded == 0;
}

/// Bir kaydın sorguya alaka skoru (0..1 civarı, sıralama için).
///
/// Ağırlıklar prompt §9.3'e dayanır; embedding servisi ZORUNLU değildir —
/// anahtar/keyword eşleşmesi + önem + tazelik + güven yeterlidir.
double scoreRelevance({
  required MemoryRecord record,
  required MemoryQuery query,
}) {
  var score = 0.0;

  // 1) Kanonik anahtar / içerik eşleşmesi.
  final q = query.normalizedQuery;
  if (q.isNotEmpty) {
    if (record.key.contains(q)) {
      score += 0.35;
    } else if (record.normalizedContent.contains(q)) {
      score += 0.25;
    } else if (record.keywords.any((k) => k.contains(q) || q.contains(k))) {
      score += 0.18;
    }
  }

  // 2) Modül yakınlığı.
  if (query.modules.isNotEmpty && query.modules.contains(record.module)) {
    score += 0.12;
  }

  // 3) Önem ve güven.
  score += record.importance * 0.15;
  score += record.confidence * 0.08;

  // 4) Tazelik — 180 günde doğrusal sönüm.
  final ageDays = query.now.difference(record.updatedAt).inDays;
  final recency = (1.0 - (ageDays / 180.0)).clamp(0.0, 1.0);
  score += recency * 0.10;

  // 5) Sabitlenmiş kayıt önceliklidir.
  if (record.pinned) score += 0.10;

  // 6) Kullanıcı düzeltmesi en güvenilir kaynaktır.
  if (record.sourceType == MemorySourceType.userCorrection) score += 0.05;

  return score;
}

/// Erişim + durum + süre filtresinden geçen kayıtları skorlayıp sıralar.
///
/// KRİTİK: filtreleme sıralamadan ÖNCE yapılır — yetkisiz kayıt hiç skorlanmaz.
List<MemorySearchResult> retrieveAndRank({
  required List<MemoryRecord> all,
  required MemoryQuery query,
}) {
  final results = <MemorySearchResult>[];

  for (final r in all) {
    // Silinmiş kayıt asla.
    if (r.deletedAt != null) continue;

    // Farklı çocuk bağlamı istendiyse ele (çocuk verileri karışmaz).
    if (query.childId != null &&
        r.childId != null &&
        r.childId != query.childId) {
      continue;
    }

    final hasAccess = viewerCanAccess(
      scope: r.scope,
      ownerUserId: r.userId,
      viewerUserId: query.viewerUserId,
      viewerIsSameFamily: query.viewerIsSameFamily,
      viewerIsParentOrAdmin: query.viewerIsParentOrAdmin,
      allowedUserIds: r.allowedUserIds,
      deniedUserIds: r.deniedUserIds,
    );

    final usable = canIncludeInContext(
      status: r.status,
      sensitivity: r.sensitivity,
      confidence: r.confidence,
      viewerHasAccess: hasAccess,
      expiresAt: r.expiresAt,
      now: query.now,
    );
    if (!usable) continue;

    results.add(
      MemorySearchResult(record: r, score: scoreRelevance(record: r, query: query)),
    );
  }

  results.sort((a, b) => b.score.compareTo(a.score));
  return results;
}

/// Sıralı sonuçlardan token bütçeli, kategorili bağlam paketi kurar.
///
/// Öncelik (prompt §9.5): kısıtlar (alerji/sağlık) → doğrulanmış gerçekler →
/// tercihler → yakın olaylar. Bütçe dolarsa DÜŞÜK öncelikli olanlar düşer.
MemoryContextPacket buildContextPacket({
  required List<MemorySearchResult> ranked,
  ContextBudget budget = const ContextBudget(),
}) {
  final restrictions = <MemoryRecord>[];
  final facts = <MemoryRecord>[];
  final prefs = <MemoryRecord>[];
  final events = <MemoryRecord>[];
  final conflicts = <MemoryRecord>[];

  var chars = 0;
  var dropped = 0;
  var count = 0;

  bool fits(MemoryRecord r) =>
      count < budget.maxMemories &&
      (chars + r.content.length) <= budget.maxCharacters;

  void take(MemoryRecord r, List<MemoryRecord> bucket) {
    bucket.add(r);
    chars += r.content.length;
    count++;
  }

  // Kısıtlar önce — bütçe dolsa bile alerji/sağlık kısıtı düşmemeli.
  for (final res in ranked) {
    final r = res.record;
    if (r.kind == MemoryKind.restriction ||
        r.sensitivity == MemorySensitivity.health ||
        r.sensitivity == MemorySensitivity.minorData) {
      if (fits(r)) {
        take(r, restrictions);
      } else {
        dropped++;
      }
    }
  }

  for (final res in ranked) {
    final r = res.record;
    if (restrictions.contains(r)) continue;

    // Çözülemeyen çelişki: ayrı listede, kesin bilgi olarak sunulmaz.
    if (r.status == MemoryStatus.disputed) {
      conflicts.add(r);
      continue;
    }

    final bucket = switch (r.kind) {
      MemoryKind.preference => prefs,
      MemoryKind.episodicEvent => events,
      _ => facts,
    };

    if (fits(r)) {
      take(r, bucket);
    } else {
      dropped++;
    }
  }

  return MemoryContextPacket(
    restrictions: restrictions,
    confirmedFacts: facts,
    preferences: prefs,
    recentEvents: events,
    unresolvedConflicts: conflicts,
    usedCharacters: chars,
    droppedCount: dropped,
  );
}
