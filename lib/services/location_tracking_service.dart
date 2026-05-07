import 'dart:async';
import '../core/supabase_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'child_auth_service.dart';

/// Periodically uploads device location to Supabase `geolocations` table.
/// Works for both parent (authenticated) and child (anon) modes.
class LocationTrackingService {
  static final _client = SupabaseConfig.client;
  static Timer? _uploadTimer;
  static StreamSubscription<Position>? _positionSub;

  static bool get isTracking => _uploadTimer != null || _positionSub != null;

  // ═══════════════════════════════════════════════════════════════════════════
  // START / STOP
  // ═══════════════════════════════════════════════════════════════════════════

  static void startTracking({Duration interval = const Duration(seconds: 30)}) {
    if (isTracking) return;

    // Use position stream for real-time updates when moving,
    // fallback to timer for periodic uploads when stationary.
    _startPositionStream(interval);
  }

  static void stopTracking() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════════════════

  static void _startPositionStream(Duration interval) {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // metres
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
      (position) => _uploadPosition(position),
      onError: (_) {},
    );

    // Backup timer: ensure upload even when not moving
    _uploadTimer = Timer.periodic(interval, (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        await _uploadPosition(pos);
      } catch (_) {}
    });
  }

  static Future<void> _uploadPosition(Position position) async {
    try {
      final isParent = _client.auth.currentUser != null;
      final isChild = ChildAuthService.isChildMode;

      if (isParent) {
        await _uploadAsParent(position);
      } else if (isChild) {
        await _uploadAsChild(position);
      }
    } catch (_) {
      // Silently fail — location is best-effort
    }
  }

  static Future<void> _uploadAsParent(Position position) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    final profile = await _client
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    final familyId = profile?['family_id'] as String?;
    if (familyId == null) return;

    await _client.from('geolocations').insert({
      'user_id': userId,
      'family_id': familyId,
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'heading': position.heading,
      'is_moving': position.speed > 0.5,
    });
  }

  static Future<void> _uploadAsChild(Position position) async {
    final familyId = ChildAuthService.currentFamilyId;
    final childId = ChildAuthService.currentChildId;
    if (familyId == null || childId == null) return;

    await _client.from('geolocations').insert({
      'child_id': childId,
      'family_id': familyId,
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'heading': position.heading,
      'is_moving': position.speed > 0.5,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLE SHOT (for manual share)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> shareCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await _uploadPosition(position);
      return true;
    } catch (_) {
      return false;
    }
  }
}