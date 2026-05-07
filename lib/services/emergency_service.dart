import 'dart:async';
import '../core/supabase_client.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

/// Global realtime SOS service.
/// All SOS alerts are persisted to Supabase `sos_alerts` table and
/// broadcast via realtime to every family member (parents + children).
class EmergencyService {
  static final _sosController = StreamController<SOSAlert>.broadcast();
  static final _cancelController = StreamController<SOSCancel>.broadcast();
  static Stream<SOSAlert> get sosStream => _sosController.stream;
  static Stream<SOSCancel> get cancelStream => _cancelController.stream;

  static final _client = SupabaseConfig.client;
  static StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL BROADCAST (for in-app UI)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> sendSOSAlert({
    required String userName,
    required Position? location,
    required String message,
  }) async {
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();

    _sosController.add(SOSAlert(
      userName: userName,
      lat: location?.latitude ?? 0,
      lng: location?.longitude ?? 0,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  static Future<void> sendSOSCancel({
    required String userName,
    required String familyId,
    required String message,
  }) async {
    HapticFeedback.heavyImpact();
    _cancelController.add(SOSCancel(
      userName: userName,
      familyId: familyId,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE PERSISTENCE (cross-device sync)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Persist a new SOS alert to Supabase and broadcast locally.
  static Future<void> triggerSOS({
    required String familyId,
    required String senderId,
    required String senderName,
    required String senderType, // 'parent' | 'child'
    required Position? location,
    String message = 'Acil durum!',
  }) async {
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();

    try {
      await _client.from('sos_alerts').insert({
        'family_id': familyId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_type': senderType,
        'lat': location?.latitude,
        'lng': location?.longitude,
        'accuracy': location?.accuracy,
        'message': message,
        'status': 'active',
      });
    } catch (e) {
      // Still broadcast locally even if network fails
      _sosController.add(SOSAlert(
        userName: senderName,
        lat: location?.latitude ?? 0,
        lng: location?.longitude ?? 0,
        message: '$message (Çevrimdışı)',
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Resolve an active SOS alert.
  static Future<void> resolveSOS(String alertId, {required String resolvedBy}) async {
    await _client.from('sos_alerts').update({
      'status': 'resolved',
      'resolved_by': resolvedBy,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  /// Mark as false alarm.
  static Future<void> falseAlarmSOS(String alertId, {required String resolvedBy}) async {
    await _client.from('sos_alerts').update({
      'status': 'false_alarm',
      'resolved_by': resolvedBy,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  /// Get active alerts for a family.
  static Future<List<Map<String, dynamic>>> getActiveAlerts(String familyId) async {
    final response = await _client
        .from('sos_alerts')
        .select('*')
        .eq('family_id', familyId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get recent alert history for a family.
  static Future<List<Map<String, dynamic>>> getAlertHistory(String familyId, {int limit = 20}) async {
    final response = await _client
        .from('sos_alerts')
        .select('*')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME LISTENING (family-scoped)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start listening to realtime SOS alerts for a specific family.
  /// Returns a stream of raw Supabase rows.
  static Stream<List<Map<String, dynamic>>> listenToFamilySOS(String familyId) {
    return _client
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  /// Subscribe and auto-broadcast to local SOS stream.
  static void startRealtimeListener(String familyId) {
    _realtimeSub?.cancel();
    _realtimeSub = listenToFamilySOS(familyId).listen((rows) {
      for (final row in rows.where((r) => r['status'] == 'active')) {
        _sosController.add(SOSAlert(
          id: row['id'] as String?,
          userName: row['sender_name'] as String? ?? 'Bilinmeyen',
          lat: (row['lat'] as num?)?.toDouble() ?? 0,
          lng: (row['lng'] as num?)?.toDouble() ?? 0,
          message: row['message'] as String? ?? 'Acil durum!',
          timestamp: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          senderType: row['sender_type'] as String?,
        ));
      }
    });
  }

  static void stopRealtimeListener() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE CALL
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launched) return true;
      // Fallback to platform default
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static void dispose() {
    _realtimeSub?.cancel();
    _sosController.close();
    _cancelController.close();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODELS
// ═════════════════════════════════════════════════════════════════════════════

class SOSAlert {
  final String? id;
  final String userName;
  final double lat;
  final double lng;
  final String message;
  final DateTime timestamp;
  final String? senderType;

  SOSAlert({
    this.id,
    required this.userName,
    required this.lat,
    required this.lng,
    required this.message,
    required this.timestamp,
    this.senderType,
  });
}

class SOSCancel {
  final String userName;
  final String familyId;
  final String message;
  final DateTime timestamp;

  SOSCancel({
    required this.userName,
    required this.familyId,
    required this.message,
    required this.timestamp,
  });
}