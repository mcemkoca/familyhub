import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../services/child_auth_service.dart';

class ChildLocationRepository {
  static final ChildLocationRepository _instance = ChildLocationRepository._internal();
  factory ChildLocationRepository() => _instance;
  ChildLocationRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  /// Share child's current location
  Future<void> shareLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    int? batteryLevel,
    bool isMoving = false,
  }) async {
    try {
      _checkSession();
      await _client.from('geolocations').insert({
        'family_id': _familyId!,
        'child_id': _childId!,
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'battery_level': batteryLevel,
        'is_moving': isMoving,
      });

      await ChildAuthService.logActivity(
        'location_shared',
        details: {
          'lat': latitude,
          'lng': longitude,
          'battery': batteryLevel,
        },
      );
    } catch (e, st) {
      debugPrint('ChildLocationRepository.shareLocation error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  /// Get last known location for current child
  Future<Map<String, dynamic>?> getLastLocation() async {
    try {
      _checkSession();
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', _childId!)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e, st) {
      debugPrint('ChildLocationRepository.getLastLocation error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  /// Get location history for current child
  Future<List<Map<String, dynamic>>> getLocationHistory({int limit = 50}) async {
    try {
      _checkSession();
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', _childId!)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      debugPrint('ChildLocationRepository.getLocationHistory error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  /// Watch family geolocations (for parents to see child's location)
  Stream<List<Map<String, dynamic>>> watchFamilyLocations() {
    try {
      final familyId = _familyId;
      if (familyId == null) return Stream.value([]);
      return _client
          .from('geolocations')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at')
          .map((data) => data.cast<Map<String, dynamic>>().toList());
    } catch (e, st) {
      debugPrint('ChildLocationRepository.watchFamilyLocations error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  /// Get last location for any child (parent view)
  Future<Map<String, dynamic>?> getChildLastLocation(String childId) async {
    try {
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e, st) {
      debugPrint('ChildLocationRepository.getChildLastLocation error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }
}
