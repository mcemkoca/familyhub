import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../hive_service.dart';
import 'ai_engine.dart';
import '../../core/app_logger.dart';

/// Uygulamanın tüm bölümlerini internet/AI (Gemini) ile besleyen birleşik
/// içerik motoru. Sonuçlar Hive'da önbelleğe alınır:
///   - `weekly`  → ISO hafta bazında (haftada bir yenilenir)
///   - `daily`   → gün bazında (her gün yenilenir)
/// Böylece Gemini'nin ücretsiz kota limiti (dakikada 20 istek) korunur ve
/// çevrimdışıyken son içerik gösterilir.
class AiContentService {
  static const _cachePrefix = 'aicontent_';

  /// ISO hafta anahtarı: 2026-W27 gibi.
  static String _weekKey() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, 1, 1);
    final days = now.difference(firstDay).inDays;
    final week = ((days + firstDay.weekday - 1) / 7).floor() + 1;
    return '${now.year}-W$week';
  }

  static String _dayKey() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  /// Haftalık önbellekli JSON liste içeriği döndürür.
  /// [topic] benzersiz bir anahtar, [prompt] Gemini'ye gönderilir.
  /// [listKey] JSON kökündeki dizi alanının adı (ör. "items").
  /// Gemini başarısız olursa [fallback] döner.
  static Future<List<Map<String, dynamic>>> weeklyList({
    required String topic,
    required String prompt,
    String listKey = 'items',
    required List<Map<String, dynamic>> fallback,
    int maxTokens = 900,
    bool forceRefresh = false,
  }) {
    return _cachedList(
      cacheKey: '$_cachePrefix${topic}_${_weekKey()}',
      prompt: prompt,
      listKey: listKey,
      fallback: fallback,
      maxTokens: maxTokens,
      forceRefresh: forceRefresh,
    );
  }

  /// Günlük önbellekli JSON liste içeriği döndürür.
  static Future<List<Map<String, dynamic>>> dailyList({
    required String topic,
    required String prompt,
    String listKey = 'items',
    required List<Map<String, dynamic>> fallback,
    int maxTokens = 900,
    bool forceRefresh = false,
  }) {
    return _cachedList(
      cacheKey: '$_cachePrefix${topic}_${_dayKey()}',
      prompt: prompt,
      listKey: listKey,
      fallback: fallback,
      maxTokens: maxTokens,
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<Map<String, dynamic>>> _cachedList({
    required String cacheKey,
    required String prompt,
    required String listKey,
    required List<Map<String, dynamic>> fallback,
    required int maxTokens,
    required bool forceRefresh,
  }) async {
    if (!forceRefresh) {
      final cached = HiveService.getSetting(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final parsed = _parseList(cached, listKey);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    try {
      // Üst-sınır timeout: AIEngine çoklu-sağlayıcı + retry ile uzayabilir;
      // bu olmadan ekran "yenileniyor"da takılı kalır. Aşınca fallback döner.
      final res = await AIEngine.generate(
        prompt: prompt,
        format: AIResponseFormat.json,
        maxTokens: maxTokens,
        temperature: 0.7,
      ).timeout(const Duration(seconds: 18));
      final parsed = _parseList(res.content, listKey);
      if (parsed.isNotEmpty) {
        await HiveService.setSetting(cacheKey, jsonEncode({listKey: parsed}));
        return parsed;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AiContentService fallback: $e');
    }
    return fallback;
  }

  static List<Map<String, dynamic>> _parseList(String raw, String listKey) {
    try {
      var s = raw.trim();
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) s = s.substring(start, end + 1);
      final obj = jsonDecode(s);
      final list = obj is Map ? obj[listKey] : (obj is List ? obj : null);
      if (list is List) {
        return list
            .whereType<Map<dynamic, dynamic>>()
            .map<Map<String, dynamic>>(
                (e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    } catch (e) {
      // Best-effort: bozuk önbellek yok sayılır, boş liste ile yeniden üretilir.
      AppLogger.logBestEffort(e, module: 'ai', operation: 'parseCachedContent');
    }
    return const [];
  }

  /// Kullanıcının ülke koduna göre bölge market adları.
  static List<String> marketsForCountry(String country) {
    switch (country.toUpperCase()) {
      case 'BE':
        return const ['Colruyt', 'Aldi', 'Lidl', 'Delhaize', 'Carrefour'];
      case 'NL':
        return const ['Albert Heijn', 'Jumbo', 'Lidl', 'Aldi', 'Dirk'];
      case 'FR':
        return const ['Carrefour', 'Leclerc', 'Lidl', 'Auchan', 'Intermarché'];
      case 'DE':
        return const ['Aldi', 'Lidl', 'Rewe', 'Edeka', 'Kaufland'];
      case 'TR':
        return const ['BIM', 'A101', 'Migros', 'ŞOK', 'CarrefourSA'];
      default:
        return const ['Lidl', 'Aldi', 'Carrefour'];
    }
  }
}
