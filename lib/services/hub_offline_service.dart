import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'localization/locale_service.dart';

/// Connectivity-aware offline fallback service for Hub data.
/// Uses Hive for local caching when offline.
class HubOfflineService {
  static String get _offlineError {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return const {'tr': 'İnternet bağlantısı yok ve önbellekte veri yok', 'en': 'There is no internet connection and no cached data', 'nl': 'Er is geen internetverbinding en er zijn geen gegevens in de cache', 'fr': 'Aucune connexion Internet et aucune donnée en cache'}[lang] ?? 'İnternet bağlantısı yok ve önbellekte veri yok';
  }
  static final _connectivity = Connectivity();
  static late Box<String> _cacheBox;

  static Future<void> init() async {
    _cacheBox = Hive.isBoxOpen('hub_offline_cache')
        ? Hive.box<String>('hub_offline_cache')
        : await Hive.openBox<String>('hub_offline_cache');
  }

  static Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  /// Execute an online fetch with offline fallback.
  static Future<T> withOfflineFallback<T>({
    required String cacheKey,
    required Future<T> Function() online,
    required T Function(dynamic json) fromJson,
    required dynamic Function(T data) toJson,
    required T defaultValue,
  }) async {
    final isConnected = await isOnline;

    if (isConnected) {
      try {
        final result = await online();
        // Save to cache
        final raw = jsonEncode(toJson(result));
        await _cacheBox.put(cacheKey, raw);
        return result;
      } catch (e) {
        // Online failed, try cache
        final cached = _cacheBox.get(cacheKey);
        if (cached != null) {
          try {
            return fromJson(jsonDecode(cached));
          } catch (_) {
            // Cache corrupted, return default
          }
        }
        throw Exception(_offlineError);
      }
    } else {
      // Offline: read from cache
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) {
        try {
          return fromJson(jsonDecode(cached));
        } catch (_) {
          // Cache corrupted
        }
      }
      throw Exception(_offlineError);
    }
  }

  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }
}
