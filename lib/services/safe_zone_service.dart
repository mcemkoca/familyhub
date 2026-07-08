import 'package:geolocator/geolocator.dart';
import '../core/supabase_client.dart';
import '../domain/models/safety_models.dart';

/// Safe zone (geofence) management with distance-based checks.
/// Syncs from Supabase; falls back to empty list if not logged in.
class SafeZoneService {
  static List<SafeZone> _zones = [];
  static bool _initialized = false;

  static List<SafeZone> get zones => List.unmodifiable(_zones);

  static Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromSupabase();
    _initialized = true;
  }

  static Future<void> _loadFromSupabase() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    try {
      final data = await client
          .from('safe_zones')
          .select('id, name, type, latitude, longitude, radius_meters, address')
          .order('created_at', ascending: true);

      _zones = (data as List<dynamic>).map((row) {
        final r = row as Map<String, dynamic>;
        return SafeZone(
          id: r['id'] as String? ?? '',
          name: r['name'] as String? ?? 'Bölge',
          type: _parseType(r['type'] as String?),
          latitude: (r['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (r['longitude'] as num?)?.toDouble() ?? 0.0,
          radiusMeters: (r['radius_meters'] as num?)?.toDouble() ?? 100.0,
          address: r['address'] as String?,
        );
      }).toList();
    } catch (_) {
      _zones = [];
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
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    await client.from('safe_zones').insert({
      'name': zone.name,
      'type': zone.type.name,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'radius_meters': zone.radiusMeters,
      'address': zone.address,
    });
    await _loadFromSupabase();
  }

  static Future<void> removeZone(String id) async {
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    await client.from('safe_zones').delete().eq('id', id);
    await _loadFromSupabase();
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
