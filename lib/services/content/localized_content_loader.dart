import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Dil-klasörlü içerik yükleyici.
///
/// İçerik dosyaları: `assets/data/content/<modül>/<dil>.json`
///   örn. assets/data/content/health_articles/nl.json
///
/// Çevirmen sadece ilgili dilin JSON dosyasını çevirir ve yerine koyar;
/// KOD DEĞİŞMEZ, yeniden derleme gerekmez (asset zaten pubspec'te kayıtlı
/// klasördeyse). Fallback zinciri: seçilen dil → en → tr.
///
/// JSON formatı: bir liste (List) veya {"items":[...]} sarmalı.
class LocalizedContentLoader {
  LocalizedContentLoader._();

  /// [module] için [lang] dilindeki içerik listesini döndürür.
  /// Dosya yoksa/bozuksa sırayla en → tr denenir; hiçbiri yoksa boş liste.
  static Future<List<Map<String, dynamic>>> loadList(
    String module,
    String lang, {
    List<String>? fallback,
  }) async {
    final chain = <String>[
      lang,
      ...(fallback ?? const ['en', 'tr']),
    ];
    final seen = <String>{};
    for (final code in chain) {
      if (!seen.add(code)) continue;
      final data = await _tryLoad('assets/data/content/$module/$code.json');
      if (data != null && data.isNotEmpty) return data;
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>?> _tryLoad(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      final list = decoded is Map<String, dynamic>
          ? (decoded['items'] as List? ?? const [])
          : (decoded as List? ?? const []);
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return null; // dosya yok veya bozuk → fallback denenecek
    }
  }
}
