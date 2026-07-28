import '../domain/localized_content.dart';

/// İçerik yayın kalite kapısı — canonical model kurallarını doğrular.
/// Yalnızca tüm kurallardan geçen içerik `published` olabilir.
class ContentIssue {
  final String contentId;
  final String code;
  final String message;
  const ContentIssue(this.contentId, this.code, this.message);
  @override
  String toString() => '[$code] $contentId: $message';
}

class ContentValidator {
  const ContentValidator._();

  /// Yüksek riskli sınıflar — resmî kaynak + doğrulama tarihi zorunlu.
  static const _highRisk = {
    ContentRisk.health,
    ContentRisk.legal,
    ContentRisk.financial,
    ContentRisk.childSafety,
    ContentRisk.emergency,
  };

  static List<ContentIssue> validate(LocalizedContent c) {
    final issues = <ContentIssue>[];
    void add(String code, String msg) =>
        issues.add(ContentIssue(c.id, code, msg));

    if (c.id.trim().isEmpty) add('missing_id', 'ID boş');
    if (c.category.trim().isEmpty) add('missing_category', 'Kategori boş');

    // Dört dil parity — eksik/boş çeviri.
    for (final l in contentLocales) {
      final t = c.translations[l];
      if (t == null) {
        add('missing_translation', '$l çevirisi yok');
      } else if (!t.isComplete) {
        add('empty_translation', '$l çevirisi eksik (title/summary/body)');
      }
    }

    // Kaynak zorunlulukları.
    if (c.source.url.trim().isEmpty) {
      add('missing_source_url', 'Kaynak URL yok');
    }
    if (c.status == ContentStatus.published &&
        c.source.publisher.trim().isEmpty) {
      add('missing_publisher', 'Yayınlanmış içerikte yayıncı yok');
    }

    // Yüksek risk: doğrulama tarihi + kaynak zorunlu.
    if (_highRisk.contains(c.riskLevel)) {
      if (c.source.verifiedAt == null) {
        add('unverified_high_risk',
            'Yüksek riskli içerik doğrulama tarihi olmadan yayınlanamaz');
      }
    }

    return issues;
  }

  /// İçerik `published` olmaya uygun mu? (hiç ihlal yok + 4 dil tam)
  static bool canPublish(LocalizedContent c) =>
      c.hasAllTranslations && validate(c).isEmpty;

  /// Bir liste için tüm ihlalleri toplar (CI raporu için).
  static List<ContentIssue> validateAll(Iterable<LocalizedContent> items) =>
      [for (final c in items) ...validate(c)];
}
