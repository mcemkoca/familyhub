import '../domain/localized_content.dart';

/// İçerik tekilleştirme — aynı canonical URL + content hash tekrar eklenmez.
/// Deterministik sıra: id'e göre sıralanır (gürültüsüz git diff).
class ContentDeduplicator {
  const ContentDeduplicator._();

  /// Yeni gelenleri mevcutlarla birleştirir; dedup anahtarı çakışanları atlar.
  /// Idempotent: aynı girdi tekrar uygulanınca sonuç değişmez.
  static List<LocalizedContent> merge(
    List<LocalizedContent> existing,
    List<LocalizedContent> incoming,
  ) {
    final byKey = <String, LocalizedContent>{};
    for (final c in existing) {
      byKey[c.dedupKey] = c;
    }
    for (final c in incoming) {
      byKey.putIfAbsent(c.dedupKey, () => c);
    }
    final out = byKey.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// Tek listedeki tekrarları kaldırır (ilk görülen kazanır).
  static List<LocalizedContent> unique(List<LocalizedContent> items) =>
      merge(const [], items);
}
