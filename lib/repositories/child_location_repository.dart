import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../services/child_auth_service.dart';

class ChildLocationRepository with RepositoryErrorHandler {
  static final ChildLocationRepository _instance =
      ChildLocationRepository._internal();
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
    return handleRepositoryCall(() async {
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
        details: {'lat': latitude, 'lng': longitude, 'battery': batteryLevel},
      );
    }, 'shareLocation');
  }

  /// Get last known location for current child
  Future<Map<String, dynamic>?> getLastLocation() async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', _childId!)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    }, 'getLastLocation');
  }

  /// Get location history for current child
  Future<List<Map<String, dynamic>>> getLocationHistory({
    int limit = 50,
  }) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', _childId!)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    }, 'getLocationHistory');
  }

  /// Get last location for any child (parent view)
  Future<Map<String, dynamic>?> getChildLastLocation(String childId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from('geolocations')
          .select('*')
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    }, 'getChildLastLocation');
  }
}
