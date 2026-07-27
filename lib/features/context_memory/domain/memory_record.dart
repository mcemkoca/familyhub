/// Context Memory — tip güvenli kayıt modeli (Faz 1/2).
///
/// Generic `Map<String, dynamic>` yerine bu model kullanılır: çelişki çözümü,
/// dedup, retention ve erişim kontrolü ancak tipli alanlarla mümkündür.
library;

import 'memory_enums.dart';

/// Kalıcı bir bağlam bilgisi.
class MemoryRecord {
  final String id;

  // ── Kimlik / kapsam ────────────────────────────────────────────────────
  final String? userId;
  final String? familyId;
  final String? memberId;
  final String? childId;
  final String? conversationId;

  final MemoryScope scope;
  final MemoryKind kind;
  final MemorySensitivity sensitivity;
  final MemorySourceType sourceType;
  final MemoryStatus status;

  // ── İçerik ─────────────────────────────────────────────────────────────
  final String module;

  /// Dile BAĞIMSIZ kanonik anahtar (ör. `food.allergy.peanut`).
  /// Gösterim lokalize edilir; anahtar asla çevrilmez (prompt §17).
  final String key;
  final String title;
  final String content;

  /// Arama/dedup için normalize edilmiş biçim (küçük harf, aksansız).
  final String normalizedContent;

  final Map<String, dynamic> structuredData;
  final List<String> keywords;
  final List<String> relatedMemoryIds;
  final List<String> supersedesMemoryIds;

  // ── Erişim ─────────────────────────────────────────────────────────────
  final List<String> allowedUserIds;
  final List<String> deniedUserIds;

  // ── Skorlar ────────────────────────────────────────────────────────────
  final double confidence;
  final double importance;

  final bool explicit;
  final bool confirmed;
  final bool pinned;
  final bool encrypted;

  // ── Zaman ──────────────────────────────────────────────────────────────
  final DateTime? occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DateTime? deletedAt;

  final int accessCount;
  final int schemaVersion;
  final String sourceId;
  final MemorySyncState syncState;

  static const currentSchemaVersion = 1;

  const MemoryRecord({
    required this.id,
    required this.scope,
    required this.kind,
    required this.sensitivity,
    required this.sourceType,
    required this.status,
    required this.module,
    required this.key,
    required this.title,
    required this.content,
    required this.normalizedContent,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceId,
    this.userId,
    this.familyId,
    this.memberId,
    this.childId,
    this.conversationId,
    this.structuredData = const {},
    this.keywords = const [],
    this.relatedMemoryIds = const [],
    this.supersedesMemoryIds = const [],
    this.allowedUserIds = const [],
    this.deniedUserIds = const [],
    this.confidence = 1.0,
    this.importance = 0.5,
    this.explicit = false,
    this.confirmed = false,
    this.pinned = false,
    this.encrypted = false,
    this.occurredAt,
    this.expiresAt,
    this.deletedAt,
    this.accessCount = 0,
    this.schemaVersion = currentSchemaVersion,
    this.syncState = MemorySyncState.localOnly,
  });

  /// Verilen ana göre süresi dolmuş mu?
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  /// Dedup kimliği: aynı kapsam+modül+anahtar+özne aynı bilgidir.
  String get dedupKey =>
      '${scope.name}|$module|$key|${childId ?? memberId ?? userId ?? ''}';

  MemoryRecord copyWith({
    MemoryStatus? status,
    String? content,
    String? normalizedContent,
    Map<String, dynamic>? structuredData,
    List<String>? supersedesMemoryIds,
    double? confidence,
    double? importance,
    bool? confirmed,
    bool? pinned,
    bool? encrypted,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? deletedAt,
    int? accessCount,
    MemorySyncState? syncState,
    MemorySourceType? sourceType,
  }) {
    return MemoryRecord(
      id: id,
      userId: userId,
      familyId: familyId,
      memberId: memberId,
      childId: childId,
      conversationId: conversationId,
      scope: scope,
      kind: kind,
      sensitivity: sensitivity,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      module: module,
      key: key,
      title: title,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      structuredData: structuredData ?? this.structuredData,
      keywords: keywords,
      relatedMemoryIds: relatedMemoryIds,
      supersedesMemoryIds: supersedesMemoryIds ?? this.supersedesMemoryIds,
      allowedUserIds: allowedUserIds,
      deniedUserIds: deniedUserIds,
      confidence: confidence ?? this.confidence,
      importance: importance ?? this.importance,
      explicit: explicit,
      confirmed: confirmed ?? this.confirmed,
      pinned: pinned ?? this.pinned,
      encrypted: encrypted ?? this.encrypted,
      occurredAt: occurredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deletedAt: deletedAt ?? this.deletedAt,
      accessCount: accessCount ?? this.accessCount,
      schemaVersion: schemaVersion,
      sourceId: sourceId,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'familyId': familyId,
        'memberId': memberId,
        'childId': childId,
        'conversationId': conversationId,
        'scope': scope.name,
        'kind': kind.name,
        'sensitivity': sensitivity.name,
        'sourceType': sourceType.name,
        'status': status.name,
        'module': module,
        'key': key,
        'title': title,
        'content': content,
        'normalizedContent': normalizedContent,
        'structuredData': structuredData,
        'keywords': keywords,
        'relatedMemoryIds': relatedMemoryIds,
        'supersedesMemoryIds': supersedesMemoryIds,
        'allowedUserIds': allowedUserIds,
        'deniedUserIds': deniedUserIds,
        'confidence': confidence,
        'importance': importance,
        'explicit': explicit,
        'confirmed': confirmed,
        'pinned': pinned,
        'encrypted': encrypted,
        'occurredAt': occurredAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'accessCount': accessCount,
        'schemaVersion': schemaVersion,
        'sourceId': sourceId,
        'syncState': syncState.name,
      };

  /// Bozuk/eksik alanlara toleranslı parse (kalıcı veri şema evrimi).
  factory MemoryRecord.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    DateTime? date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return MemoryRecord(
      id: j['id']?.toString() ?? '',
      userId: j['userId']?.toString(),
      familyId: j['familyId']?.toString(),
      memberId: j['memberId']?.toString(),
      childId: j['childId']?.toString(),
      conversationId: j['conversationId']?.toString(),
      scope: MemoryScope.parse(j['scope']?.toString()),
      kind: MemoryKind.parse(j['kind']?.toString()),
      sensitivity: MemorySensitivity.parse(j['sensitivity']?.toString()),
      sourceType: MemorySourceType.parse(j['sourceType']?.toString()),
      status: MemoryStatus.parse(j['status']?.toString()),
      module: j['module']?.toString() ?? 'unknown',
      key: j['key']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      content: j['content']?.toString() ?? '',
      normalizedContent: j['normalizedContent']?.toString() ?? '',
      structuredData: (j['structuredData'] as Map?)?.cast<String, dynamic>() ??
          const {},
      keywords: strList(j['keywords']),
      relatedMemoryIds: strList(j['relatedMemoryIds']),
      supersedesMemoryIds: strList(j['supersedesMemoryIds']),
      allowedUserIds: strList(j['allowedUserIds']),
      deniedUserIds: strList(j['deniedUserIds']),
      confidence: (j['confidence'] as num?)?.toDouble() ?? 1.0,
      importance: (j['importance'] as num?)?.toDouble() ?? 0.5,
      explicit: j['explicit'] == true,
      confirmed: j['confirmed'] == true,
      pinned: j['pinned'] == true,
      encrypted: j['encrypted'] == true,
      occurredAt: date(j['occurredAt']),
      createdAt: date(j['createdAt']) ?? DateTime.utc(1970),
      updatedAt: date(j['updatedAt']) ?? DateTime.utc(1970),
      expiresAt: date(j['expiresAt']),
      deletedAt: date(j['deletedAt']),
      accessCount: (j['accessCount'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (j['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      sourceId: j['sourceId']?.toString() ?? '',
      syncState: MemorySyncState.parse(j['syncState']?.toString()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MemoryRecord && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

/// İçeriği dedup/arama için normalize eder: küçük harf, aksan sadeleştirme,
/// fazla boşluk temizliği. Dil-bağımsız kanonik karşılaştırma sağlar.
String normalizeMemoryContent(String input) {
  const map = {
    'ı': 'i', 'İ': 'i', 'ş': 's', 'Ş': 's', 'ğ': 'g', 'Ğ': 'g',
    'ü': 'u', 'Ü': 'u', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'à': 'a', 'â': 'a', 'ï': 'i', 'î': 'i',
  };
  var s = input.trim().toLowerCase();
  map.forEach((k, v) => s = s.replaceAll(k, v));
  return s.replaceAll(RegExp(r'\s+'), ' ');
}
