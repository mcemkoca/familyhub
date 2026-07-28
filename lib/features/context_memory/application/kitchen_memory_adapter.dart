/// Context Memory — mutfak modülü adapter'ı (Faz 7 entegrasyonu).
///
/// Modüller memory'ye DOĞRUDAN yazmaz; burada olay + aday üretilir, pipeline
/// politikayı uygular. Bu adapter kullanıcı ifadelerinden yemek tercihi ve
/// alerji çıkarır.
library;

import '../domain/memory_enums.dart';
import '../domain/memory_event.dart';
import '../domain/memory_record.dart';

/// Kanonik anahtar üretir — DİLE BAĞIMSIZ (prompt §17).
/// `mantar` → `food.disliked.mantar`; gösterim lokalize edilir.
String foodPreferenceKey({required String item, required bool liked}) {
  final slug = normalizeMemoryContent(item).replaceAll(' ', '_');
  return liked ? 'food.liked.$slug' : 'food.disliked.$slug';
}

String foodAllergyKey(String item) =>
    'food.allergy.${normalizeMemoryContent(item).replaceAll(' ', '_')}';

/// Bir cümleden yemek tercihi/alerji adayları çıkarır.
///
/// Kural tabanlı ve TUTUCU: emin olunmayan ifadeden aday üretilmez
/// (yanlış bilgi saklamak, hiç saklamamaktan kötüdür).
List<MemoryCandidate> extractKitchenCandidates({
  required String text,
  String? childId,
}) {
  final n = normalizeMemoryContent(text);
  if (n.isEmpty) return const [];

  final out = <MemoryCandidate>[];

  // ── Alerji (en yüksek öncelik — kritik kısıt) ────────────────────────────
  const allergyMarkers = ['alerjisi var', 'alerjik', 'allergie', 'allergy'];
  if (allergyMarkers.any(n.contains)) {
    final item = _extractItemBefore(n, allergyMarkers);
    if (item != null) {
      out.add(MemoryCandidate(
        kind: MemoryKind.restriction,
        scope: childId != null
            ? MemoryScope.childPrivate
            : MemoryScope.userPrivate,
        // Alerji sağlık verisidir; çocuksa daha korumalı sınıf.
        sensitivity: childId != null
            ? MemorySensitivity.minorData
            : MemorySensitivity.health,
        sourceType: MemorySourceType.userMessage,
        module: 'kitchen',
        key: foodAllergyKey(item),
        title: 'Alerji: $item',
        content: text.trim(),
        structuredData: {'item': item, 'type': 'allergy'},
        confidence: 1.0,
        importance: 0.95, // kritik kısıt
        explicit: true,
      ));
      return out; // alerji cümlesinden tercih çıkarma
    }
  }

  // ── Sevmeme ──────────────────────────────────────────────────────────────
  const dislikeMarkers = ['sevmiyor', 'sevmem', 'istemiyor', 'hoslanmiyor'];
  if (dislikeMarkers.any(n.contains)) {
    final item = _extractItemBefore(n, dislikeMarkers);
    if (item != null) {
      out.add(_pref(text, item, liked: false, childId: childId));
    }
  }

  // ── Sevme ────────────────────────────────────────────────────────────────
  const likeMarkers = ['seviyor', 'severim', 'bayiliyor'];
  if (likeMarkers.any(n.contains)) {
    final item = _extractItemBefore(n, likeMarkers);
    if (item != null) {
      out.add(_pref(text, item, liked: true, childId: childId));
    }
  }

  return out;
}

MemoryCandidate _pref(
  String original,
  String item, {
  required bool liked,
  String? childId,
}) =>
    MemoryCandidate(
      kind: MemoryKind.preference,
      scope:
          childId != null ? MemoryScope.childPrivate : MemoryScope.userPrivate,
      sensitivity: childId != null
          ? MemorySensitivity.minorData
          : MemorySensitivity.normal,
      sourceType: MemorySourceType.userMessage,
      module: 'kitchen',
      key: foodPreferenceKey(item: item, liked: liked),
      title: liked ? 'Seviyor: $item' : 'Sevmiyor: $item',
      content: original.trim(),
      structuredData: {'item': item, 'preference': liked ? 'like' : 'dislike'},
      confidence: 0.9,
      importance: 0.6,
      explicit: true,
    );

/// İşaretçiden ÖNCEKİ son anlamlı kelimeyi yemek adı olarak alır.
/// Bulunamazsa null → aday üretilmez (tutucu davranış).
String? _extractItemBefore(String normalized, List<String> markers) {
  for (final m in markers) {
    final i = normalized.indexOf(m);
    if (i <= 0) continue;
    final before = normalized.substring(0, i).trim();
    if (before.isEmpty) continue;
    final words = before.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty) continue;
    final candidate = words.last;
    // Zamir/bağlaç ise güvenilmez → aday üretme.
    const stop = {'ben', 'biz', 'onu', 'bunu', 'sunu', 'cok', 'hic', 'ama'};
    if (stop.contains(candidate)) return null;
    return candidate;
  }
  return null;
}

/// Mutfak modülünden memory olayı üretir.
MemoryEvent kitchenMemoryEvent({
  required String eventId,
  required String sourceId,
  String? userId,
  String? familyId,
  String? childId,
  String? conversationId,
  bool explicitRemember = false,
  DateTime? occurredAt,
}) =>
    MemoryEvent(
      id: eventId,
      eventType: 'kitchen_preference',
      module: 'kitchen',
      sourceId: sourceId,
      userId: userId,
      familyId: familyId,
      childId: childId,
      conversationId: conversationId,
      occurredAt: occurredAt ?? DateTime.now(),
      explicitRememberRequest: explicitRemember,
    );
