import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache management with invalidation rules for FamilyHub content.
///
/// Backed by Hive for fast local storage.
/// Tracks access counts and timestamps for cache analytics.
class ContentCacheService {
  ContentCacheService._();
  static final ContentCacheService _instance = ContentCacheService._();
  static ContentCacheService get instance => _instance;

  static const String _boxName = 'content_cache_v2';
  static const String _keyPrefix = 'familyhub_content_';
  static const String _metaPrefix = 'familyhub_meta_';

  Box<String>? _box;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _box = await Hive.openBox<String>(_boxName);
    _initialized = true;
  }

  // ── Core Operations ───────────────────────────────────────────────────

  /// Stores content with metadata tracking.
  Future<void> put({
    required String module,
    required String contentKey,
    required Map<String, dynamic> content,
  }) async {
    final box = _box;
    if (box == null) return;

    final cacheKey = '$_keyPrefix${module}_$contentKey';
    final metaKey = '$_metaPrefix${module}_$contentKey';
    final now = DateTime.now().toIso8601String();

    final meta = <String, dynamic>{
      'generated_at': now,
      'access_count': 0,
      'last_accessed': now,
      'module': module,
      'content_key': contentKey,
    };

    await box.put(cacheKey, jsonEncode(content));
    await box.put(metaKey, jsonEncode(meta));
  }

  /// Retrieves content and updates access statistics.
  Map<String, dynamic>? get({
    required String module,
    required String contentKey,
  }) {
    final box = _box;
    if (box == null) return null;

    final cacheKey = '$_keyPrefix${module}_$contentKey';
    final metaKey = '$_metaPrefix${module}_$contentKey';

    final cached = box.get(cacheKey);
    if (cached == null || cached.isEmpty) return null;

    // Update access stats
    final metaRaw = box.get(metaKey);
    if (metaRaw != null && metaRaw.isNotEmpty) {
      try {
        final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
        meta['access_count'] = (meta['access_count'] as num?)?.toInt() ?? 0 + 1;
        meta['last_accessed'] = DateTime.now().toIso8601String();
        box.put(metaKey, jsonEncode(meta));
      } catch (_) {
        // Meta corruption is non-fatal
      }
    }

    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Cache Invalidation ────────────────────────────────────────────────

  /// Checks if cached content is stale based on module-specific rules.
  ///
  /// Invalidation rules:
  /// - meal_planning: 30 days (monthly refresh)
  /// - child_development: 7 days (matches the V2 remote-update contract)
  /// - budget: 90 days (quarterly, economic data updates)
  /// - household: 90 days
  /// - future_planning: 7 days (weekly remote-source review)
  /// - default: 30 days
  bool isStale({
    required String module,
    required String contentKey,
  }) {
    final meta = _getMeta(module: module, contentKey: contentKey);
    if (meta == null) return true;

    final generatedAtStr = meta['generated_at'] as String?;
    if (generatedAtStr == null || generatedAtStr.isEmpty) return true;

    final generatedAt = DateTime.tryParse(generatedAtStr);
    if (generatedAt == null) return true;

    final age = DateTime.now().difference(generatedAt);

    final maxAgeDays = switch (module) {
      'meal_planning' => 30,
      'child_development' => 7,
      'budget' => 90,
      'household' => 90,
      'future_planning' => 7,
      _ => 30,
    };

    return age.inDays > maxAgeDays;
  }

  /// Returns cache metadata for analytics.
  CacheMeta? getMeta({
    required String module,
    required String contentKey,
  }) {
    final raw = _getMeta(module: module, contentKey: contentKey);
    if (raw == null) return null;
    return CacheMeta.fromJson(raw);
  }

  /// Invalidates all entries for a specific module.
  Future<void> invalidateModule(String module) async {
    final box = _box;
    if (box == null) return;

    final keysToDelete = box.keys.where((key) {
      return key is String &&
          (key.startsWith('$_keyPrefix$module') ||
              key.startsWith('$_metaPrefix$module'));
    }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Clears all cached content.
  Future<void> clearAll() async {
    final box = _box;
    if (box == null) return;
    await box.clear();
  }

  // ── Analytics ─────────────────────────────────────────────────────────

  /// Returns total cached entries count.
  int get entryCount {
    final box = _box;
    if (box == null) return 0;
    return box.keys.where((k) => k is String && k.startsWith(_keyPrefix)).length;
  }

  // ── Private ───────────────────────────────────────────────────────────

  Map<String, dynamic>? _getMeta({
    required String module,
    required String contentKey,
  }) {
    final box = _box;
    if (box == null) return null;

    final metaKey = '$_metaPrefix${module}_$contentKey';
    final metaRaw = box.get(metaKey);
    if (metaRaw == null || metaRaw.isEmpty) return null;

    try {
      return jsonDecode(metaRaw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ── Models ──────────────────────────────────────────────────────────────

class CacheMeta {
  final DateTime generatedAt;
  final int accessCount;
  final DateTime lastAccessed;
  final String module;
  final String contentKey;

  const CacheMeta({
    required this.generatedAt,
    required this.accessCount,
    required this.lastAccessed,
    required this.module,
    required this.contentKey,
  });

  factory CacheMeta.fromJson(Map<String, dynamic> json) {
    return CacheMeta(
      generatedAt: DateTime.parse(json['generated_at'] as String),
      accessCount: (json['access_count'] as num).toInt(),
      lastAccessed: DateTime.parse(json['last_accessed'] as String),
      module: json['module'] as String,
      contentKey: json['content_key'] as String,
    );
  }
}
