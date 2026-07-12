// İçerik kaynak registry — content_sources.yaml kayıtlarının modeli + doğrulaması.
// Saf Dart (I/O'suz), test edilebilir. Gerçek fetch content_sync.dart'ta.

/// Kaynak güven seviyesi — yayın kararı ve önceliklendirme için.
enum SourceTrust { official, publicService, international, academic, ngo, publisher, unknown }

SourceTrust sourceTrustFromKey(String? k) => switch (k) {
      'official' => SourceTrust.official,
      'public_service' => SourceTrust.publicService,
      'international' => SourceTrust.international,
      'academic' => SourceTrust.academic,
      'ngo' => SourceTrust.ngo,
      'publisher' => SourceTrust.publisher,
      _ => SourceTrust.unknown,
    };

class SourceRecord {
  final String id;
  final String name;
  final String baseUrl;
  final String country;
  final List<String> regions;
  final List<String> categories;
  final String sourceLanguage;
  final String fetchType;
  final bool enabled;
  final SourceTrust trustLevel;

  const SourceRecord({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.country,
    required this.regions,
    required this.categories,
    required this.sourceLanguage,
    required this.fetchType,
    required this.enabled,
    required this.trustLevel,
  });

  factory SourceRecord.fromMap(Map<String, dynamic> m) => SourceRecord(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        baseUrl: (m['base_url'] ?? '') as String,
        country: (m['country'] ?? '') as String,
        regions: (m['regions'] as List?)?.cast<String>() ?? const [],
        categories: (m['categories'] as List?)?.cast<String>() ?? const [],
        sourceLanguage: (m['source_language'] ?? '') as String,
        fetchType: (m['fetch_type'] ?? 'html') as String,
        enabled: (m['enabled'] ?? false) as bool,
        trustLevel: sourceTrustFromKey(m['trust_level'] as String?),
      );

  /// Yüksek riskli kategoriler yalnızca resmî/kamu/uluslararası kaynaklardan.
  static const _highRiskCategories = {
    'health', 'legal', 'financial', 'child_safety', 'child_health', 'social_rights'
  };
  static const _trustedForHighRisk = {
    SourceTrust.official, SourceTrust.publicService, SourceTrust.international, SourceTrust.academic
  };

  List<String> validate() {
    final errs = <String>[];
    if (id.trim().isEmpty) errs.add('id boş');
    if (!baseUrl.startsWith('https://')) errs.add('$id: base_url https olmalı');
    if (country.trim().isEmpty) errs.add('$id: country boş');
    if (categories.isEmpty) errs.add('$id: kategori yok');
    if (sourceLanguage.trim().isEmpty) errs.add('$id: source_language boş');
    // Yüksek riskli kategoride blog/publisher temel kaynak olamaz.
    final highRisk = categories.any(_highRiskCategories.contains);
    if (highRisk && !_trustedForHighRisk.contains(trustLevel)) {
      errs.add('$id: yüksek riskli kategori için güvenilir/resmî kaynak gerekir');
    }
    return errs;
  }
}

class SourceRegistry {
  final List<SourceRecord> sources;
  const SourceRegistry(this.sources);

  factory SourceRegistry.fromMaps(List<Map<String, dynamic>> raw) =>
      SourceRegistry(raw.map(SourceRecord.fromMap).toList());

  /// Tüm kayıtların doğrulama hataları (CI kapısı için).
  List<String> validate() {
    final errs = <String>[];
    final seen = <String>{};
    for (final s in sources) {
      if (!seen.add(s.id)) errs.add('${s.id}: yinelenen kaynak id');
      errs.addAll(s.validate());
    }
    return errs;
  }

  List<SourceRecord> get enabledSources =>
      sources.where((s) => s.enabled).toList();
}
