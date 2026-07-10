/// AI güvenlik yardımcıları — prompt injection tespiti ve context minimizasyonu.
/// Bu katman AI'ya GÖNDERİLECEK veriyi minimize eder ve GELEN talimatları
/// (injection) tespit eder. Authorization AI'da DEĞİL, servis katmanındadır.
class AIGuardrails {
  AIGuardrails._();

  static final _injectionPatterns = <RegExp>[
    RegExp(r'ignore\s+(all\s+)?previous', caseSensitive: false),
    RegExp(r'önceki\s+(tüm\s+)?talimat', caseSensitive: false),
    RegExp(r'system\s+prompt', caseSensitive: false),
    RegExp(r'sistem\s+prompt', caseSensitive: false),
    RegExp(r'api[_\s-]?key', caseSensitive: false),
    RegExp(r'tüm\s+aile(lerin)?\s+veri', caseSensitive: false),
    RegExp(r'other\s+famil(y|ies)', caseSensitive: false),
    RegExp(r'diğer\s+aile', caseSensitive: false),
    RegExp(r'export\s+all', caseSensitive: false),
    RegExp(r'bearer\s+', caseSensitive: false),
  ];

  /// Kullanıcı girdisi prompt injection / veri sızdırma denemesi içeriyor mu?
  static bool looksLikeInjection(String input) {
    return _injectionPatterns.any((re) => re.hasMatch(input));
  }

  /// AI'ya gönderilecek bağlamı minimize eder — yalnızca sayısal özet,
  /// hassas ham veri (isim/sağlık/finans detayı) GÖNDERİLMEZ.
  static Map<String, Object?> minimizedContext({
    required int pendingTasks,
    required int todayEvents,
    required int pendingShopping,
    required int memberCount,
  }) {
    return {
      'pendingTasks': pendingTasks,
      'todayEvents': todayEvents,
      'pendingShopping': pendingShopping,
      'memberCount': memberCount,
      // İsim, sağlık, finans detayı, konum KASITLI olarak yok.
    };
  }
}
