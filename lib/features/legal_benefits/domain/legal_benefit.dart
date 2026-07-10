/// Yasal hak/avantaj domain modeli.
/// Kategori, bölge ve tür STABLE KEY olarak saklanır (çeviri değil);
/// başlık/açıklama içerik metnidir. Resmî kaynak ve doğrulama tarihi zorunlu
/// alanlardır — süresi geçmiş içerik aktif avantaj gibi gösterilmez.
library;

/// Stable kategori anahtarları (UI'da localization ile gösterilir).
enum LegalCategory {
  familySupport,
  childBenefits,
  healthRights,
  educationSupport,
  taxBenefits,
  housingSupport,
  employeeRights,
  parentalLeave,
  residencyRights,
  disabilitySupport,
  socialAid,
  other,
}

LegalCategory legalCategoryFromKey(String? key) {
  for (final c in LegalCategory.values) {
    if (c.name == key) return c;
  }
  return LegalCategory.other;
}

/// Belçika çok katmanlı bölge yapısı + diğer ülkeler için federal seviye.
/// Bölge dil DEĞİLDİR — yalnızca içerik kapsamını belirler.
enum LegalRegion { federal, flanders, wallonia, brussels, municipality, other }

LegalRegion legalRegionFromKey(String? key) {
  for (final r in LegalRegion.values) {
    if (r.name == key) return r;
  }
  return LegalRegion.federal;
}

class LegalBenefit {
  final String id;
  final String title;
  final String description;
  final LegalCategory category;
  final String countryCode; // 'BE','NL','TR','DE','FR'
  final LegalRegion region;
  final String sourceTitle;
  final String sourceUrl; // resmî kaynak — zorunlu
  final DateTime lastVerifiedAt;
  final DateTime? validUntil; // null → süresiz
  final bool isOfficial;

  const LegalBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.countryCode,
    this.region = LegalRegion.federal,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.lastVerifiedAt,
    this.validUntil,
    this.isOfficial = true,
  });

  /// Süresi geçmiş mi? (aktif avantaj gibi gösterilmemeli)
  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  /// İçerik bayat mı? (son doğrulama 180 günden eski)
  bool get isStale =>
      DateTime.now().difference(lastVerifiedAt).inDays > 180;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'countryCode': countryCode,
        'region': region.name,
        'sourceTitle': sourceTitle,
        'sourceUrl': sourceUrl,
        'lastVerifiedAt': lastVerifiedAt.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'isOfficial': isOfficial,
      };

  factory LegalBenefit.fromJson(Map<String, dynamic> json) => LegalBenefit(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: legalCategoryFromKey(json['category'] as String?),
        countryCode: json['countryCode'] as String? ?? 'BE',
        region: legalRegionFromKey(json['region'] as String?),
        sourceTitle: json['sourceTitle'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        lastVerifiedAt: DateTime.tryParse(json['lastVerifiedAt'] as String? ?? '') ??
            DateTime.now(),
        validUntil: json['validUntil'] != null
            ? DateTime.tryParse(json['validUntil'] as String)
            : null,
        isOfficial: json['isOfficial'] as bool? ?? true,
      );
}
