import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'content_localizer.dart';
import '../localization/locale_service.dart';

/// Loads, localizes and persists the review-gated household-task catalog.
class HouseholdTaskContentService {
  HouseholdTaskContentService._();

  static final instance = HouseholdTaskContentService._();
  static const _assetPath = 'assets/data/household_tasks.json';
  static const _boxName = 'household_tasks_content';
  static const _activeKey = 'active';
  static const _updatedAtKey = 'updated_at';

  Map<String, dynamic>? _data;

  Future<void> initialize() async {
    final box = await Hive.openBox<String>(_boxName);
    final cached = box.get(_activeKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        _data = jsonDecode(cached) as Map<String, dynamic>;
        return;
      } catch (_) {
        // Corrupt cache falls back to the bundled, validated asset.
      }
    }
    final raw = await rootBundle.loadString(_assetPath);
    final lang = LocaleService.resolveInitialLocale().languageCode;
    _data = normalizeContent(jsonDecode(raw), lang) as Map<String, dynamic>;
    await box.put(_activeKey, raw);
  }

  bool get needsWeeklyRefresh {
    if (!Hive.isBoxOpen(_boxName)) return true;
    final raw = Hive.box<String>(_boxName).get(_updatedAtKey);
    final updatedAt = raw == null ? null : DateTime.tryParse(raw);
    return updatedAt == null ||
        DateTime.now().difference(updatedAt).inHours >= 168;
  }

  Map<String, dynamic>? weeklyTask({String language = 'tr'}) {
    final data = _data;
    if (data == null) return null;
    final locale = _locale(language);
    final translated = data['i18n'] as Map<String, dynamic>?;
    final localized = translated?[locale] as Map<String, dynamic>?;
    final tasks = localized?['weekly_task_catalog'] as List<dynamic>?;
    final variants = localized?['weekly_variants'] as List<dynamic>?;
    if (tasks == null ||
        tasks.isEmpty ||
        variants == null ||
        variants.isEmpty) {
      return null;
    }
    final week = _isoWeekNumber(DateTime.now());
    final task = Map<String, dynamic>.from(
      tasks[(week - 1) % tasks.length] as Map,
    );
    final variant =
        variants[((week - 1) ~/ tasks.length) % variants.length] as Map;
    final instruction = variant['instruction'] as String? ?? '';
    if (instruction.isNotEmpty) {
      task['description'] = '${task['description'] ?? ''} $instruction'.trim();
    }
    task['variant_id'] = variant['id'];
    return task;
  }

  List<Map<String, dynamic>> localizedTasks({String language = 'tr'}) {
    final data = _data;
    if (data == null) return const [];
    final locale = _locale(language);
    final tasks = data['tasks'] as List<dynamic>? ?? const [];
    final dictionary =
        data['task_translation_dictionary'] as Map<String, dynamic>? ??
        const {};
    return tasks.map((item) {
      final task = Map<String, dynamic>.from(item as Map);
      final key = task['translation_key'] as String?;
      final translations = key == null
          ? null
          : dictionary[key] as Map<String, dynamic>?;
      final text =
          translations?[locale] as Map<String, dynamic>? ??
          translations?['tr'] as Map<String, dynamic>?;
      if (text != null) {
        final sourceName = task['task_name'] as String? ?? '';
        final match = RegExp(r'(\d+)\)?$').firstMatch(sourceName);
        final number = match?.group(1);
        task['task_name'] = _restoreNumber(text['task_name'], number);
        task['description'] = _restoreNumber(text['description'], number);
        task['tips'] = List<String>.from(
          text['tips'] as List<dynamic>? ?? const [],
        );
      }
      return task;
    }).toList();
  }

  Future<bool> saveReviewedUpdate(Map<String, dynamic> payload) async {
    try {
      if (payload['module'] != 'household_tasks' ||
          payload['tasks'] is! List ||
          payload['weekly_task_catalog'] is! List ||
          payload['weekly_variants'] is! List ||
          payload['task_translation_dictionary'] is! Map) {
        return false;
      }
      final i18n = payload['i18n'];
      if (i18n is! Map ||
          const {'tr', 'en', 'nl', 'fr'}.any((code) => i18n[code] is! Map)) {
        return false;
      }
      final ids = (payload['weekly_task_catalog'] as List)
          .map((item) => (item as Map)['id'])
          .toList();
      if (ids.any((id) => id == null) || ids.toSet().length != ids.length) {
        return false;
      }

      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      final raw = jsonEncode(payload);
      final revision =
          (payload['content_revision'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      await box.put('revision_$revision', raw);
      await box.put(_activeKey, raw);
      await box.put(_updatedAtKey, DateTime.now().toUtc().toIso8601String());
      _data = payload;
      return true;
    } catch (_) {
      return false;
    }
  }

  String _locale(String language) =>
      const {'tr', 'en', 'nl', 'fr'}.contains(language) ? language : 'tr';

  String _restoreNumber(dynamic value, String? number) {
    final text = value as String? ?? '';
    if (number == null) return text;
    return text.replaceFirst(RegExp(r'\d+(?=\)?$)'), number);
  }

  int _isoWeekNumber(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final firstWeekThursday = firstThursday.add(
      Duration(days: 4 - firstThursday.weekday),
    );
    return 1 + thursday.difference(firstWeekThursday).inDays ~/ 7;
  }
}
