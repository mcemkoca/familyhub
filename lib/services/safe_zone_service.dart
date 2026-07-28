import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_logger.dart';
import '../core/supabase_client.dart';
import '../domain/models/safety_models.dart';
import 'auth_service.dart';
import 'hive_service.dart';
import 'localization/locale_service.dart';

/// Safe zone (geofence) management with distance-based checks.
/// Buluttan senkronlanır; oturum/aile yoksa yerel (Hive) olarak saklanır.
class SafeZoneService {
  static String get _defaultZoneName {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return const {'tr': 'Bölge', 'en': 'Zone', 'nl': 'Zone', 'fr': 'Zone'}[lang] ?? 'Bölge';
  }
  static List<SafeZone> _zones = [];
  static bool _initialized = false;

  static List<SafeZone> get zones => List.unmodifiable(_zones);

  static Future<void> initialize() async {
    if (_initialized) return;
    _loadLocal();
    await _loadFromSupabase();
    _initialized = true;
  }

  // ── Yerel (Hive) kalıcılık ──
  static void _loadLocal() {
    final raw = HiveService.getSetting('safe_zones_local');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _zones = list.map((e) {
        final r = e as Map<String, dynamic>;
        return SafeZone(
          id: r['id'] as String? ?? '',
          name: r['name'] as String? ?? _defaultZoneName,
          type: _parseType(r['type'] as String?),
          latitude: (r['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (r['longitude'] as num?)?.toDouble() ?? 0.0,
          radiusMeters: (r['radius_meters'] as num?)?.toDouble() ?? 100.0,
          address: r['address'] as String?,
        );
      }).toList();
    } catch (e, st) {
      // Sessizce yutulamaz: bölgeler yüklenmezse geofence uyarıları HİÇ
      // çalışmaz ve kullanıcı korunduğunu sanır (spec §11).
      AppLogger.logError(
        e,
        module: 'safety',
        operation: 'loadSafeZones',
        stackTrace: st,
      );
    }
  }

  static Future<void> _saveLocal() async {
    final list = _zones
        .map((z) => {
              'id': z.id,
              'name': z.name,
              'type': z.type.name,
              'latitude': z.latitude,
              'longitude': z.longitude,
              'radius_meters': z.radiusMeters,
              'address': z.address,
            })
        .toList();
    await HiveService.setSetting('safe_zones_local', jsonEncode(list));
  }

  static Future<void> _loadFromSupabase() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    try {
      final data = await client
          .from('safe_zones')
          .select('id, name, type, latitude, longitude, radius_meters, address')
          .order('created_at', ascending: true);

      final cloud = (data as List<dynamic>).map((row) {
        final r = row as Map<String, dynamic>;
        return SafeZone(
          id: r['id'] as String? ?? '',
          name: r['name'] as String? ?? _defaultZoneName,
          type: _parseType(r['type'] as String?),
          latitude: (r['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (r['longitude'] as num?)?.toDouble() ?? 0.0,
          radiusMeters: (r['radius_meters'] as num?)?.toDouble() ?? 100.0,
          address: r['address'] as String?,
        );
      }).toList();
      // Yerel-only (senkronlanmamış) bölgeleri koru.
      final cloudIds = cloud.map((z) => z.id).toSet();
      final localOnly =
          _zones.where((z) => !cloudIds.contains(z.id)).toList();
      _zones = [...cloud, ...localOnly];
      await _saveLocal();
    } catch (_) {
      // Bulut başarısız — yerel liste korunur.
    }
  }

  static SafeZoneType _parseType(String? value) {
    return switch (value) {
      'home' => SafeZoneType.home,
      'work' => SafeZoneType.work,
      'school' => SafeZoneType.school,
      _ => SafeZoneType.custom,
    };
  }

  static Future<bool> isInsideZone(SafeZone zone, {Position? position}) async {
    try {
      final pos = position ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8)),
          );
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        zone.latitude,
        zone.longitude,
      );
      return distance <= zone.radiusMeters;
    } catch (_) {
      // GPS fix yoksa/zaman aşımında bölge içinde sayma.
      return false;
    }
  }

  static Future<List<SafeZone>> getActiveZones({Position? position}) async {
    await initialize();
    final results = <SafeZone>[];
    for (final zone in _zones) {
      final inside = await isInsideZone(zone, position: position);
      if (inside) results.add(zone);
    }
    return results;
  }

  static Future<String> getDistanceText(
    SafeZone zone, {
    Position? position,
  }) async {
    try {
      final pos = position ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8)),
          );
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        zone.latitude,
        zone.longitude,
      );
      if (distance < 1000) {
        return '${distance.round()}m';
      }
      return '${(distance / 1000).toStringAsFixed(1)}km';
    } catch (_) {
      return '-';
    }
  }

  static Future<void> addZone(SafeZone zone) async {
    // Önce yerel listeye ekle (kullanıcı hemen görsün, asla patlamasın).
    _zones = [..._zones, zone];
    await _saveLocal();

    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    try {
      String? familyId;
      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      familyId = profile?['family_id'] as String?;
      if (familyId == null) return; // yerel kalır

      await client.from('safe_zones').insert({
        'family_id': familyId,
        'created_by': userId,
        'name': zone.name,
        'type': zone.type.name,
        'latitude': zone.latitude,
        'longitude': zone.longitude,
        'radius_meters': zone.radiusMeters,
        'address': zone.address,
      });
      await _loadFromSupabase();
    } catch (e) {
      debugPrint('addZone cloud failed, kept local: $e');
    }
  }

  static Future<void> removeZone(String id) async {
    _zones = _zones.where((z) => z.id != id).toList();
    await _saveLocal();

    final client = SupabaseConfig.safeClient;
    if (client == null) return;
    try {
      await client.from('safe_zones').delete().eq('id', id);
    } catch (e) {
      debugPrint('removeZone cloud failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> checkAllZones() async {
    await initialize();
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      return _zones.map((zone) {
        final distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          zone.latitude,
          zone.longitude,
        );
        return {
          'zone': zone,
          'distance': distance,
          'inside': distance <= zone.radiusMeters,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
