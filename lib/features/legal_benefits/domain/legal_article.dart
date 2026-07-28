/// Zengin yasal hak makalesi — çok-dilli JSON içerikten (assets/data/legal/*.json)
/// üretilir. Özet kart (LegalBenefit) altındaki DERİN içerik katmanıdır:
/// sade açıklama, kimler başvurabilir, koşullar, başvuru adımları, gerekli
/// belgeler ve uyarılar. Her makale EN AZ bir resmî kaynak taşır.
///
/// İçerik `normalizeContent` ile aktif dile indirgenerek verilir (i18n merge),
/// bu yüzden metin alanları zaten seçili dildeki String/List'tir.
library;

class LegalSource {
  final String authority;
  final String title;
  final String url;
  final int trustLevel; // 1 = resmî kurum

  const LegalSource({
    required this.authority,
    required this.title,
    required this.url,
    this.trustLevel = 1,
  });

  factory LegalSource.fromMap(Map<String, dynamic> m) => LegalSource(
        authority: (m['authority'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        url: (m['url'] ?? '').toString(),
        trustLevel: (m['trustLevel'] as num?)?.toInt() ?? 1,
      );
}

class LegalArticle {
  final String id;
  final String slug;
  final String category; // stable key → LegalCategory.name
  final List<String> regionCodes; // ISO 3166-2 (BE-VLG, BE-WAL, BE-BRU)
  final String jurisdictionLevel; // federal | regional | municipal
  final String riskLevel; // high | medium | low
  final String status; // published | review | draft
  final DateTime? lastVerifiedAt;
  final List<LegalSource> sources;

  // Yerelleşmiş içerik alanları (aktif dil).
  final String title;
  final String summary;
  final String plainExplanation;
  final String whoCanApply;
  final List<String> conditions;
  final List<String> benefits;
  final List<String> applicationSteps;
  final List<String> requiredDocuments;
  final List<String> importantWarnings;

  const LegalArticle({
    required this.id,
    required this.slug,
    required this.category,
    required this.regionCodes,
    required this.jurisdictionLevel,
    required this.riskLevel,
    required this.status,
    required this.lastVerifiedAt,
    required this.sources,
    required this.title,
    required this.summary,
    required this.plainExplanation,
    required this.whoCanApply,
    required this.conditions,
    required this.benefits,
    required this.applicationSteps,
    required this.requiredDocuments,
    required this.importantWarnings,
  });

  /// İçerik bayat mı? (son doğrulama 180 günden eski)
  bool get isStale =>
      lastVerifiedAt == null ||
      DateTime.now().difference(lastVerifiedAt!).inDays > 180;

  bool get isPublished => status == 'published';

  static List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  static DateTime? _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  /// `normalizeContent(rawArticle, lang)` çıktısından üretir.
  /// Metin alanları zaten aktif dile indirgenmiştir.
  factory LegalArticle.fromLocalized(Map<String, dynamic> m) {
    final rawSources = m['sources'];
    final sources = <LegalSource>[];
    if (rawSources is List) {
      for (final s in rawSources) {
        if (s is Map) {
          sources.add(LegalSource.fromMap(s.cast<String, dynamic>()));
        }
      }
    }
    return LegalArticle(
      id: (m['id'] ?? '').toString(),
      slug: (m['slug'] ?? '').toString(),
      category: (m['category'] ?? 'other').toString(),
      regionCodes: _strList(m['regionCodes']),
      jurisdictionLevel: (m['jurisdictionLevel'] ?? 'federal').toString(),
      riskLevel: (m['riskLevel'] ?? 'medium').toString(),
      status: (m['status'] ?? 'published').toString(),
      lastVerifiedAt: _date(m['lastVerifiedAt']),
      sources: sources,
      title: (m['title'] ?? '').toString(),
      summary: (m['summary'] ?? '').toString(),
      plainExplanation: (m['plainExplanation'] ?? '').toString(),
      whoCanApply: (m['whoCanApply'] ?? '').toString(),
      conditions: _strList(m['conditions']),
      benefits: _strList(m['benefits']),
      applicationSteps: _strList(m['applicationSteps']),
      requiredDocuments: _strList(m['requiredDocuments']),
      importantWarnings: _strList(m['importantWarnings']),
    );
  }
}
