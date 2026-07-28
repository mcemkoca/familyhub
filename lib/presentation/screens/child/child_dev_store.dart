import 'dart:convert';
import '../../../services/hive_service.dart';
import 'child_dev_content.dart';

/// Gelişim gözlemi kaydı.
class Observation {
  final String area; // devArea key
  final String note;
  final String mood; // cok_iyi, iyi, orta, zor, cok_zor
  final String skill; // kolay, zorlandi, yardimla, yapmadi
  final String dateIso;
  final List<String> media;

  const Observation({
    required this.area,
    required this.note,
    required this.mood,
    required this.skill,
    required this.dateIso,
    this.media = const [],
  });

  Map<String, dynamic> toJson() => {
        'area': area,
        'note': note,
        'mood': mood,
        'skill': skill,
        'date': dateIso,
        'media': media,
      };

  factory Observation.fromJson(Map<String, dynamic> j) => Observation(
        area: j['area']?.toString() ?? 'dil',
        note: j['note']?.toString() ?? '',
        mood: j['mood']?.toString() ?? 'iyi',
        skill: j['skill']?.toString() ?? 'kolay',
        dateIso: j['date']?.toString() ?? DateTime.now().toIso8601String(),
        media: (j['media'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  DateTime get date => DateTime.tryParse(dateIso) ?? DateTime.now();
}

/// Gelişim verilerinin (gözlemler, değerlendirme, alan skorları) kalıcı deposu.
class DevStore {
  static String _obsKey(String childId) => 'dev_obs_$childId';
  static String _assessKey(String childId) => 'dev_assess_$childId';

  // ── Gözlemler ──────────────────────────────────────────────────────────
  static List<Observation> observations(String childId) {
    final raw = HiveService.getSetting(_obsKey(childId));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Observation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addObservation(String childId, Observation obs) async {
    final list = observations(childId);
    list.insert(0, obs);
    final trimmed = list.length > 200 ? list.sublist(0, 200) : list;
    await HiveService.setSetting(
        _obsKey(childId), jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  // ── Değerlendirme (beceri durumları) ─────────────────────────────────────
  static Map<String, String> assessment(String childId) {
    final raw = HiveService.getSetting(_assessKey(childId));
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> setAssessment(
      String childId, String key, String state) async {
    final map = assessment(childId);
    map[key] = state;
    await HiveService.setSetting(_assessKey(childId), jsonEncode(map));
  }

  // ── Alan skorları ────────────────────────────────────────────────────────
  /// Değerlendirmeden alan yüzdesi (0-100).
  /// yapiyor=1.0, bazen=0.5, henuz=0.0, emin=hariç.
  /// Cevap yoksa 0 döner (boş ama çalışır — sahte taban değer YOK).
  static int areaScore(String childId, String areaKey, String devGroup) {
    final assess = assessment(childId);
    final items = assessmentFor(devGroup);
    double total = 0;
    int answered = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i].$1 != areaKey) continue;
      final st = assess['$devGroup|$i'];
      if (st == null || st == 'emin') continue;
      answered++;
      if (st == 'yapiyor') total += 1.0;
      if (st == 'bazen') total += 0.5;
    }
    if (answered == 0) return 0;
    return (total / answered * 100).round();
  }

  static int overallScore(String childId, String devGroup) {
    final scores =
        devAreas.map((a) => areaScore(childId, a.key, devGroup)).toList();
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// Değerlendirme tamamlanma oranı (0.0-1.0).
  static double assessmentProgress(String childId, String devGroup) {
    final items = assessmentFor(devGroup);
    if (items.isEmpty) return 0;
    final assess = assessment(childId);
    var answered = 0;
    for (var i = 0; i < items.length; i++) {
      if (assess.containsKey('$devGroup|$i')) answered++;
    }
    return answered / items.length;
  }
}
