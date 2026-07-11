/// AI öneri modeli — sistem önerileri + kullanıcı özel önerileri.
/// Sistem önerileri silinmez, GİZLENİR (resetlenebilir). Sıralama: sabitlenenler
/// önce, sonra özel, sonra görünür sistem. Resolver saf/test edilebilir.
library;

class AISuggestion {
  final String id;
  final String text;
  final bool isSystem;
  final bool isPinned;

  const AISuggestion({
    required this.id,
    required this.text,
    required this.isSystem,
    this.isPinned = false,
  });

  AISuggestion copyWith({String? text, bool? isPinned}) => AISuggestion(
        id: id,
        text: text ?? this.text,
        isSystem: isSystem,
        isPinned: isPinned ?? this.isPinned,
      );

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory AISuggestion.custom(String id, String text) =>
      AISuggestion(id: id, text: text, isSystem: false);
}

class AISuggestionResolver {
  const AISuggestionResolver._();

  /// Nihai öneri listesini üretir:
  ///  - gizlenmiş sistem önerileri çıkarılır
  ///  - pinned bayrağı uygulanır
  ///  - sıralama: sabitlenenler önce (özel→sistem), sonra kalanlar
  static List<AISuggestion> resolve({
    required List<AISuggestion> system,
    required List<AISuggestion> custom,
    required Set<String> hiddenSystemIds,
    required Set<String> pinnedIds,
  }) {
    final visibleSystem = system
        .where((s) => !hiddenSystemIds.contains(s.id))
        .map((s) => s.copyWith(isPinned: pinnedIds.contains(s.id)))
        .toList();
    final customP = custom
        .map((c) => c.copyWith(isPinned: pinnedIds.contains(c.id)))
        .toList();

    final all = [...customP, ...visibleSystem];
    // Sabit sıra korunur ama pinned öne alınır (stable sort).
    all.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return 0;
    });
    return all;
  }
}
