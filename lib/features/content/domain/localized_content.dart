/// Çok dilli içerik canonical modeli — makale/öneri/aktivite/rehber.
/// Tek doğru kaynak: 4 dilde (tr/nl/fr/en) çeviri + doğrulanabilir kaynak.
/// ID dil değişiminden ETKİLENMEZ; `published` yalnızca 4 dil tamamsa.
library;

/// Desteklenen içerik dilleri (ülke varyantından bağımsız kök kod).
const contentLocales = ['tr', 'nl', 'fr', 'en'];

/// Fallback sırası: seçili dil → İngilizce → Türkçe (geçiş) → key/boş.
List<String> contentFallbackChain(String locale) {
  final base = locale.split(RegExp(r'[_-]')).first;
  final chain = <String>[base];
  for (final f in const ['en', 'tr']) {
    if (!chain.contains(f)) chain.add(f);
  }
  return chain;
}

enum ContentStatus { draft, translationPending, reviewRequired, published, quarantined }

enum ContentRisk { standard, health, legal, financial, childSafety, emergency }

ContentRisk contentRiskFromKey(String? k) => switch (k) {
      'health' => ContentRisk.health,
      'legal' => ContentRisk.legal,
      'financial' => ContentRisk.financial,
      'child_safety' => ContentRisk.childSafety,
      'emergency' => ContentRisk.emergency,
      _ => ContentRisk.standard,
    };

String contentRiskToKey(ContentRisk r) => switch (r) {
      ContentRisk.health => 'health',
      ContentRisk.legal => 'legal',
      ContentRisk.financial => 'financial',
      ContentRisk.childSafety => 'child_safety',
      ContentRisk.emergency => 'emergency',
      ContentRisk.standard => 'standard',
    };

ContentStatus contentStatusFromKey(String? k) => switch (k) {
      'published' => ContentStatus.published,
      'review_required' => ContentStatus.reviewRequired,
      'translation_pending' => ContentStatus.translationPending,
      'quarantined' => ContentStatus.quarantined,
      _ => ContentStatus.draft,
    };

String contentStatusToKey(ContentStatus s) => switch (s) {
      ContentStatus.published => 'published',
      ContentStatus.reviewRequired => 'review_required',
      ContentStatus.translationPending => 'translation_pending',
      ContentStatus.quarantined => 'quarantined',
      ContentStatus.draft => 'draft',
    };

/// Tek dildeki içerik metni.
class ContentTranslation {
  final String title;
  final String summary;
  final String body;
  const ContentTranslation(
      {required this.title, required this.summary, required this.body});

  bool get isComplete =>
      title.trim().isNotEmpty && summary.trim().isNotEmpty && body.trim().isNotEmpty;

  Map<String, dynamic> toJson() =>
      {'title': title, 'summary': summary, 'body': body};

  factory ContentTranslation.fromJson(Map<String, dynamic> j) => ContentTranslation(
        title: (j['title'] ?? '') as String,
        summary: (j['summary'] ?? '') as String,
        body: (j['body'] ?? '') as String,
      );
}

/// İçeriğin doğrulanabilir kaynağı (kanıt zinciri).
class ContentSource {
  final String url;
  final String publisher;
  final String language;
  final DateTime? publishedAt;
  final DateTime? fetchedAt;
  final DateTime? verifiedAt;
  final String? contentHash;

  const ContentSource({
    required this.url,
    required this.publisher,
    required this.language,
    this.publishedAt,
    this.fetchedAt,
    this.verifiedAt,
    this.contentHash,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'publisher': publisher,
        'language': language,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        if (fetchedAt != null) 'fetchedAt': fetchedAt!.toIso8601String(),
        if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
        if (contentHash != null) 'contentHash': contentHash,
      };

  static DateTime? _date(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  factory ContentSource.fromJson(Map<String, dynamic> j) => ContentSource(
        url: (j['url'] ?? '') as String,
        publisher: (j['publisher'] ?? '') as String,
        language: (j['language'] ?? '') as String,
        publishedAt: _date(j['publishedAt']),
        fetchedAt: _date(j['fetchedAt']),
        verifiedAt: _date(j['verifiedAt']),
        contentHash: j['contentHash'] as String?,
      );
}

class LocalizedContent {
  final String id;
  final String category;
  final String countryCode;
  final List<String> regionCodes;
  final ContentStatus status;
  final ContentRisk riskLevel;
  final ContentSource source;
  final Map<String, ContentTranslation> translations;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const LocalizedContent({
    required this.id,
    required this.category,
    required this.countryCode,
    required this.regionCodes,
    required this.status,
    required this.riskLevel,
    required this.source,
    required this.translations,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  /// Tüm desteklenen dillerde tam çeviri var mı?
  bool get hasAllTranslations => contentLocales
      .every((l) => translations[l]?.isComplete ?? false);

  /// [locale] için fallback zincirini uygulayarak çeviriyi çözer.
  ContentTranslation? resolve(String locale) {
    for (final l in contentFallbackChain(locale)) {
      final t = translations[l];
      if (t != null && t.isComplete) return t;
    }
    return null;
  }

  /// Dedup kimliği: canonical URL + içerik hash (locale'den bağımsız).
  String get dedupKey => '${source.url}#${source.contentHash ?? ''}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'countryCode': countryCode,
        'regionCodes': regionCodes,
        'status': contentStatusToKey(status),
        'riskLevel': contentRiskToKey(riskLevel),
        'source': source.toJson(),
        'translations':
            translations.map((k, v) => MapEntry(k, v.toJson())),
        'tags': tags,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory LocalizedContent.fromJson(Map<String, dynamic> j) => LocalizedContent(
        id: j['id'] as String,
        category: (j['category'] ?? '') as String,
        countryCode: (j['countryCode'] ?? 'BE') as String,
        regionCodes: (j['regionCodes'] as List?)?.cast<String>() ?? const [],
        status: contentStatusFromKey(j['status'] as String?),
        riskLevel: contentRiskFromKey(j['riskLevel'] as String?),
        source: ContentSource.fromJson(
            Map<String, dynamic>.from(j['source'] as Map? ?? {})),
        translations: ((j['translations'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
              k as String, ContentTranslation.fromJson(Map<String, dynamic>.from(v as Map))),
        ),
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        createdAt: ContentSource._date(j['createdAt']),
        updatedAt: ContentSource._date(j['updatedAt']),
        expiresAt: ContentSource._date(j['expiresAt']),
      );
}
