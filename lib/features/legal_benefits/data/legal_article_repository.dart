import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../services/content/content_localizer.dart';
import '../domain/legal_article.dart';

/// Ülkeye göre zengin yasal makale içeriğini `assets/data/legal/<ülke>.json`'dan
/// yükler ve aktif dile (i18n merge) indirger. Sonuç (ülke+dil) bazında
/// önbelleklenir; ağ gerektirmez. İçerik dosyası yoksa boş liste döner.
class LegalArticleRepository {
  LegalArticleRepository._();
  static final instance = LegalArticleRepository._();

  /// (country|lang) → makaleler.
  final Map<String, List<LegalArticle>> _cache = {};
  /// Ham JSON önbelleği (dilden bağımsız, tek okuma).
  final Map<String, List<dynamic>?> _rawCache = {};

  static const _supported = {'BE', 'NL', 'TR', 'DE', 'FR'};

  Future<List<dynamic>?> _loadRaw(String country) async {
    if (_rawCache.containsKey(country)) return _rawCache[country];
    List<dynamic>? articles;
    try {
      final path = 'assets/data/legal/${country.toLowerCase()}.json';
      final txt = await rootBundle.loadString(path);
      final decoded = jsonDecode(txt);
      if (decoded is Map && decoded['articles'] is List) {
        articles = decoded['articles'] as List;
      }
    } catch (_) {
      articles = null; // dosya yok / bozuk → sessizce boş
    }
    _rawCache[country] = articles;
    return articles;
  }

  /// Aktif dildeki makaleler (yalnızca published). Bilinmeyen ülke → BE fallback.
  Future<List<LegalArticle>> forCountry(String country, String lang) async {
    final code = _supported.contains(country) ? country : 'BE';
    final key = '$code|$lang';
    final cached = _cache[key];
    if (cached != null) return cached;

    final raw = await _loadRaw(code);
    if (raw == null) {
      _cache[key] = const [];
      return const [];
    }
    final out = <LegalArticle>[];
    for (final item in raw) {
      final localized = normalizeContent(item, lang);
      if (localized is Map<String, dynamic>) {
        final a = LegalArticle.fromLocalized(localized);
        if (a.isPublished) out.add(a);
      } else if (localized is Map) {
        final a = LegalArticle.fromLocalized(localized.cast<String, dynamic>());
        if (a.isPublished) out.add(a);
      }
    }
    _cache[key] = out;
    return out;
  }

  /// Belirli id için aktif dildeki makale (yoksa null).
  Future<LegalArticle?> byId(String country, String lang, String id) async {
    final list = await forCountry(country, lang);
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }
}
