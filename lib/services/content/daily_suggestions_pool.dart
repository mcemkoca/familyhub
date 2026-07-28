import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../../domain/models/ai_suggestion.dart';
import 'content_localizer.dart';

/// 400+ günlük öneri havuzu — içerik `assets/data/daily_suggestions.json`'dan
/// yüklenir ve aktif dile (i18n merge) indirgenir. Çeviri eklenmemiş
/// title/description alanları Türkçe temele döner (bozulmaz).
///
/// Kullanım: ekran `await DailySuggestionsPool.ensureLoaded(lang)` çağırdıktan
/// sonra `pickDaily`/`pickMore` senkron kullanılabilir.
class DailySuggestionsPool {
  static final _random = Random();

  static List<AISuggestion> _pool = const [];
  static Map<String, List<String>> _tips = const {};
  static String? _loadedLang;

  static List<AISuggestion> get all => List.unmodifiable(_pool);

  /// Aktif dildeki havuzu yükler (aynı dil için tekrar okumaz).
  static Future<void> ensureLoaded(String lang) async {
    if (_loadedLang == lang && _pool.isNotEmpty) return;
    try {
      final txt =
          await rootBundle.loadString('assets/data/daily_suggestions.json');
      final raw = jsonDecode(txt) as Map<String, dynamic>;

      // Öneriler: her öğe i18n alt-obje deseni → normalizeContent aktif dile indirger.
      final sugs = (raw['suggestions'] as List? ?? const []);
      _pool = sugs
          .map((e) => normalizeContent(e, lang))
          .whereType<Map<String, dynamic>>()
          .map((m) => _fromMap(m))
          .toList();

      // İpuçları: { type: {tr:[...],en:[...]} } → aktif dil listesi.
      final tipsRaw = raw['tips'] as Map? ?? const {};
      _tips = {
        for (final e in tipsRaw.entries)
          e.key.toString(): _pickList(e.value, lang),
      };

      // Görev rotasyon servisi verisini yapılandır.
      ChoreRotationService._configure(raw, lang, _tips);

      _loadedLang = lang;
    } catch (_) {
      // Dosya yok/bozuk → boş havuz (ekran boş durum gösterir).
      _pool = const [];
      _loadedLang = lang;
    }
  }

  static AISuggestion _fromMap(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'task').toString();
    return AISuggestion(
      id: (m['id'] ?? '').toString(),
      type: type,
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      action: _actionForType(type),
      difficulty: (m['difficulty'] ?? '').toString(),
      durationMinutes: (m['duration_minutes'] as num?)?.toInt() ?? 0,
      servings: (m['servings'] as num?)?.toInt(),
      calories: (m['calories'] as num?)?.toInt(),
      ingredients: const [],
      tips: [_randomTip(type)],
      isNew: false,
      shareable: true,
      allowAlternatives: false,
      progress: 0,
      isFavorite: false,
      assignedTo: null,
      estimatedCost: null,
      userComment: null,
      badge: null,
      nutritionInfo: null,
      alternativeOptions: const [],
    );
  }

  static List<AISuggestion> pickDaily({
    required DateTime date,
    required List<String> excludedIds,
    int count = 4,
  }) {
    final choreSuggestion = ChoreRotationService.getTodayChore(date);

    final available = _pool
        .where((s) => !excludedIds.contains(s.id))
        .where((s) => s.type != 'chore')
        .toList();

    final seed = date.year * 10000 + date.month * 100 + date.day;
    final dailyRandom = Random(seed);
    available.shuffle(dailyRandom);

    final picked = available.take(count - 1).toList();
    return [choreSuggestion, ...picked];
  }

  static List<AISuggestion> pickMore({
    required DateTime date,
    required List<String> alreadyShownIds,
    int count = 5,
  }) {
    final available =
        _pool.where((s) => !alreadyShownIds.contains(s.id)).toList();

    final seed = date.year * 10000 + date.month * 100 + date.day + 9999;
    final random = Random(seed);
    available.shuffle(random);

    return available.take(count).toList();
  }

  static String _actionForType(String type) {
    switch (type) {
      case 'recipe':
        return 'show_detail';
      case 'chore':
        return 'create_task';
      case 'social':
        return 'create_event';
      case 'health':
        return 'show_detail';
      case 'education':
        return 'show_detail';
      case 'finance':
        return 'navigate_budget';
      case 'safety':
        return 'show_detail';
      default:
        return 'show_detail';
    }
  }

  static String _randomTip(String type) {
    final list = _tips[type] ?? _tips['default'] ?? const [];
    if (list.isEmpty) return '';
    return list[_random.nextInt(list.length)];
  }
}

/// Dil-kodu → String haritasını [lang] için seçer (fallback lang→en→tr).
String _pickStr(dynamic map, String lang) {
  if (map is Map) {
    for (final code in [lang, 'en', 'tr']) {
      final v = map[code];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  return map is String ? map : '';
}

/// Dil-kodu → List haritasını [lang] için seçer (fallback lang→en→tr).
List<String> _pickList(dynamic map, String lang) {
  if (map is Map) {
    for (final code in [lang, 'en', 'tr']) {
      final v = map[code];
      if (v is List && v.isNotEmpty) {
        return v.map((e) => e.toString()).toList();
      }
    }
  }
  return const [];
}

// ── Chore Rotation Service ──
class ChoreRotationService {
  static List<Map<String, dynamic>> _chores = const [];
  static List<String> _members = const ['Anne', 'Baba', 'Çocuk 1', 'Çocuk 2'];
  static Map<String, String> _labels = const {};
  static List<String> _choreTips = const [];
  static String _lang = 'tr';

  /// [raw] = daily_suggestions.json kök objesi; içerikleri [lang]'e indirger.
  static void _configure(
      Map<String, dynamic> raw, String lang, Map<String, List<String>> tips) {
    _lang = lang;
    final choresRaw = (raw['chores'] as List? ?? const []);
    _chores = choresRaw.map((e) {
      final m = normalizeContent(e, lang);
      return (m is Map) ? m.cast<String, dynamic>() : <String, dynamic>{};
    }).toList();

    final members = raw['members'];
    final picked = _pickList(members, lang);
    if (picked.isNotEmpty) _members = picked;

    final labelsRaw = raw['labels'] as Map? ?? const {};
    _labels = {
      for (final e in labelsRaw.entries)
        e.key.toString(): _pickStr(e.value, lang),
    };

    _choreTips = [
      _labels['choreTip1'] ?? '',
      _labels['choreTip2'] ?? '',
      _labels['choreTip3'] ?? '',
    ].where((s) => s.isNotEmpty).toList();
  }

  static String _l(String key, String fallback) =>
      (_labels[key]?.isNotEmpty ?? false) ? _labels[key]! : fallback;

  static AISuggestion getTodayChore(DateTime date) {
    // Havuz yüklenmediyse güvenli varsayılan.
    if (_chores.isEmpty) {
      return AISuggestion(
        id: 'chore_fallback',
        type: 'chore',
        title: _l('choreBadge', 'Günün Görevi'),
        description: '',
        action: 'create_task',
        difficulty: 'Kolay',
        durationMinutes: 15,
        servings: null,
        calories: null,
        ingredients: const [],
        tips: const [],
        isNew: true,
        shareable: true,
        allowAlternatives: true,
        progress: 0,
        isFavorite: false,
        assignedTo: null,
        estimatedCost: _l('free', 'Ücretsiz'),
        userComment: null,
        badge: _l('choreBadge', 'Günün Görevi'),
        nutritionInfo: null,
        alternativeOptions: const [],
      );
    }

    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final chore = _chores[dayOfYear % _chores.length];
    final member = _members[dayOfYear % _members.length];
    final responsible = _l('responsible', 'Sorumlu');

    return AISuggestion(
      id: (chore['id'] ?? 'chore').toString(),
      type: 'chore',
      title: (chore['title'] ?? '').toString(),
      description:
          '${chore['description'] ?? ''}\n\n🎯 $responsible: $member',
      action: 'create_task',
      difficulty: 'Kolay',
      durationMinutes: (chore['duration'] as num?)?.toInt() ?? 15,
      servings: null,
      calories: null,
      ingredients: const [],
      tips: _choreTips,
      isNew: true,
      shareable: true,
      allowAlternatives: true,
      progress: 0,
      isFavorite: false,
      assignedTo: member,
      estimatedCost: _l('free', 'Ücretsiz'),
      userComment: null,
      badge: '🧹 ${_l('choreBadge', 'Günün Görevi')}',
      nutritionInfo: null,
      alternativeOptions: [
        AlternativeOption(
          title: _l('altPickTitle', 'Başka Görev Seç'),
          description:
              _l('altPickDesc', 'Bugün farklı bir temizlik görevi yapın.'),
          reason: _l('altPickReason', 'Değişiklik iyi gelir.'),
        ),
        AlternativeOption(
          title: _l('altHelpTitle', 'Yardım Et'),
          description:
              _l('altHelpDesc', 'Aile üyesine yardım edin, birlikte yapın.'),
          reason: _l('altHelpReason', 'Birlikte daha hızlı.'),
        ),
        AlternativeOption(
          title: _l('altPostponeTitle', 'Ertele'),
          description: _l('altPostponeDesc', 'Yarın yapın ama unutmayın!'),
          reason: _l('altPostponeReason', 'Mola da hakkınız.'),
        ),
      ],
    );
  }

  static List<Map<String, dynamic>> getWeeklySchedule(DateTime startDate) {
    final result = <Map<String, dynamic>>[];
    if (_chores.isEmpty) return result;
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
      final chore = _chores[dayOfYear % _chores.length];
      final member = _members[dayOfYear % _members.length];
      result.add({
        'day': DateFormat('EEEE', _lang).format(day),
        'date': DateFormat('dd MMM', _lang).format(day),
        'chore': (chore['title'] ?? '').toString(),
        'member': member,
        'duration': (chore['duration'] as num?)?.toInt() ?? 0,
      });
    }
    return result;
  }
}
