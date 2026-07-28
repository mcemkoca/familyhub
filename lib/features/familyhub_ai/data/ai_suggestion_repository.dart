import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../domain/ai_suggestion.dart';

/// AI öneri kalıcılığı — kullanıcı-izole. Özel öneriler, gizlenen sistem
/// önerileri ve sabitlenenler ayrı anahtarlarda tutulur.
class AISuggestionRepository {
  AISuggestionRepository._();
  static final instance = AISuggestionRepository._();

  String get _uid => AuthService.currentUserId ?? 'anon';
  String get _customKey => 'ai_custom_suggestions_$_uid';
  String get _hiddenKey => 'ai_hidden_suggestions_$_uid';
  String get _pinnedKey => 'ai_pinned_suggestions_$_uid';

  List<AISuggestion> customSuggestions() {
    try {
      final raw = HiveService.getSetting(_customKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((m) => AISuggestion.custom(
              m['id'].toString(), m['text'].toString()))
          .toList();
    } catch (_) {
      // Hive hazır değil / bozuk veri → güvenli varsayılan.
      return [];
    }
  }

  Set<String> hiddenSystemIds() => _readSet(_hiddenKey);
  Set<String> pinnedIds() => _readSet(_pinnedKey);

  Set<String> _readSet(String key) {
    try {
      final raw = HiveService.getSetting(key);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveCustom(List<AISuggestion> list) =>
      HiveService.setSetting(
          _customKey, jsonEncode(list.map((e) => e.toJson()).toList()));

  Future<void> _saveSet(String key, Set<String> ids) =>
      HiveService.setSetting(key, jsonEncode(ids.toList()));

  Future<AISuggestion> addCustom(String text) async {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final s = AISuggestion.custom(id, text.trim());
    final list = customSuggestions()..insert(0, s);
    await _saveCustom(list);
    return s;
  }

  Future<void> editCustom(String id, String text) async {
    final list = customSuggestions()
        .map((s) => s.id == id ? s.copyWith(text: text.trim()) : s)
        .toList();
    await _saveCustom(list);
  }

  /// Özel öneriyi siler; sabitlenmişse pin de kaldırılır.
  Future<void> deleteCustom(String id) async {
    await _saveCustom(customSuggestions().where((s) => s.id != id).toList());
    final pins = pinnedIds()..remove(id);
    await _saveSet(_pinnedKey, pins);
  }

  /// Sistem önerisini gizler (silmez — resetlenebilir).
  Future<void> hideSystem(String id) async {
    final h = hiddenSystemIds()..add(id);
    await _saveSet(_hiddenKey, h);
  }

  Future<void> togglePin(String id) async {
    final p = pinnedIds();
    if (!p.add(id)) p.remove(id);
    await _saveSet(_pinnedKey, p);
  }

  /// Sistem önerilerini yeniden görünür yapar (gizlenenleri sıfırla).
  Future<void> resetHidden() => _saveSet(_hiddenKey, {});
}
