/// RFC 4180 uyumlu, saf (I/O'suz) CSV kodlayıcı — test edilebilir çekirdek.
/// Virgül, çift tırnak ve satır sonu içeren alanları güvenle escape eder.
class CsvExporter {
  const CsvExporter._();

  /// [headers] + [rows] → tek CSV metni. Her satır alan sayısı = header sayısı
  /// olmak zorunda değildir; olduğu gibi kodlanır (çağıran tutarlılık sağlar).
  static String encode(List<String> headers, List<List<String>> rows) {
    final buffer = StringBuffer();
    buffer.writeln(_encodeRow(headers));
    for (final row in rows) {
      buffer.writeln(_encodeRow(row));
    }
    return buffer.toString();
  }

  static String _encodeRow(List<String> fields) =>
      fields.map(_encodeField).join(',');

  static String _encodeField(String value) {
    final needsQuote = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuote) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
