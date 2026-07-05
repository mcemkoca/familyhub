import 'dart:async';
import '../core/supabase_client.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../domain/models/safety_models.dart';
import 'child_auth_service.dart';

/// Real-time family safety service backed by Supabase.
/// Reads actual family members, their latest locations from `geolocations`,
/// and active SOS alerts from `sos_alerts`.
class SafetyService {
  SafetyService._();

  static final _client = SupabaseConfig.client;
  static StreamSubscription<dynamic>? _sosSub;
  static StreamSubscription<dynamic>? _geoSub;

  static final _statusController =
      StreamController<List<MemberSafetyStatus>>.broadcast();
  static final _alertController = StreamController<SafetyAlert>.broadcast();

  static Stream<List<MemberSafetyStatus>> get statusStream =>
      _statusController.stream;
  static Stream<SafetyAlert> get alertStream => _alertController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // START / STOP
  // ═══════════════════════════════════════════════════════════════════════════

  static void startMonitoring() {
    if (_geoSub != null) return;
    _loadRealData();
    _listenToGeolocations();
    _listenToSOSAlerts();
  }

  static void stopMonitoring() {
    _geoSub?.cancel();
    _geoSub = null;
    _sosSub?.cancel();
    _sosSub = null;
  }

  static void dispose() {
    stopMonitoring();
    _statusController.close();
    _alertController.close();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _loadRealData() async {
    try {
      // Find family_id (parent or child account)
      String? familyId;
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('family_id')
            .eq('id', user.id)
            .maybeSingle();
        familyId = profile?['family_id'] as String?;
      }
      familyId ??= ChildAuthService.currentFamilyId;
      if (familyId == null) return;

      // Load family members
      final profiles = await _client
          .from('profiles')
          .select('id, display_name, avatar_url')
          .eq('family_id', familyId);
      final children = await _client
          .from('child_accounts')
          .select('id, name, color')
          .eq('family_id', familyId);

      final members = <Map<String, dynamic>>[];
      for (final p in (profiles as List).cast<Map<String, dynamic>>()) {
        members.add({
          'id': p['id'] as String,
          'name': p['display_name'] as String? ?? 'Üye',
          'type': 'parent',
          'color': null,
        });
      }
      for (final c in (children as List).cast<Map<String, dynamic>>()) {
        members.add({
          'id': c['id'] as String,
          'name': c['name'] as String? ?? 'Çocuk',
          'type': 'child',
          'color': c['color'] as int?,
        });
      }

      // Load latest locations for each member (both user_id and child_id)
      final locations = <String, Map<String, dynamic>>{};
      for (final m in members) {
        final id = m['id'] as String;
        final loc = await _client
            .from('geolocations')
            .select('*')
            .or('user_id.eq.$id,child_id.eq.$id')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (loc != null) locations[id] = loc;
      }

      // Build MemberSafetyStatus list
      final statuses = <MemberSafetyStatus>[];
      for (final m in members) {
        final id = m['id'] as String;
        final name = m['name'] as String;
        final loc = locations[id];
        final color = _parseMemberColor(m['color'], id);

        final lat = (loc?['lat'] as num?)?.toDouble() ?? 0;
        final lng = (loc?['lng'] as num?)?.toDouble() ?? 0;
        final battery = (loc?['battery_level'] as num?)?.toInt() ?? 100;
        final accuracy = (loc?['accuracy'] as num?)?.toDouble() ?? 0;
        final createdAt = loc?['created_at'];
        final lastSeen = createdAt != null
            ? DateTime.tryParse(createdAt.toString())
            : null;
        final isOnline =
            lastSeen != null &&
            DateTime.now().difference(lastSeen).inMinutes < 30;

        final address = loc?['address'] as String?;
        final locationUpdate = LocationUpdate(
          latitude: lat,
          longitude: lng,
          accuracy: accuracy,
          batteryPercent: battery,
          signalStrength: _signalFromAccuracy(accuracy),
          timestamp: lastSeen ?? DateTime.now(),
          address: address,
        );

        statuses.add(
          MemberSafetyStatus(
            memberId: id,
            name: name,
            initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
            color: color,
            statusText: _statusTextFromLocation(isOnline, lastSeen, address),
            statusColor: isOnline
                ? (battery < 20 ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                : AppColors.error,
            isOnline: isOnline,
            lastSeen: lastSeen,
            lastLocation: locationUpdate,
            batteryPercent: battery,
            signalStrength: _signalFromAccuracy(accuracy),
            currentPlace:
                address ??
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            safeZones: const [],
            privacyLevel: LocationPrivacyLevel.full,
            panicActive: false,
          ),
        );
      }

      _statusController.add(statuses);
    } catch (e) {
      // Silently fail — keep previous data
    }
  }

  static void _listenToGeolocations() {
    _geoSub?.cancel();

    final user = _client.auth.currentUser;
    if (user != null) {
      _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle()
          .then((profile) {
            _startGeoStream(profile?['family_id'] as String?);
          });
    } else {
      _startGeoStream(ChildAuthService.currentFamilyId);
    }
  }

  static void _startGeoStream(String? familyId) {
    if (familyId == null) return;
    _geoSub = _client
        .from('geolocations')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .listen((_) => _loadRealData());
  }

  static void _listenToSOSAlerts() {
    _sosSub?.cancel();

    final user = _client.auth.currentUser;
    if (user != null) {
      _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle()
          .then((profile) {
            _startSOSStream(profile?['family_id'] as String?);
          });
    } else {
      _startSOSStream(ChildAuthService.currentFamilyId);
    }
  }

  static void _startSOSStream(String? familyId) {
    if (familyId == null) return;
    _sosSub = _client
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .listen((rows) {
          for (final row in rows.where((r) => r['status'] == 'active')) {
            _alertController.add(
              SafetyAlert(
                id: row['id'] as String,
                type: AlertType.panic,
                severity: AlertSeverity.critical,
                memberId: row['sender_id'] as String? ?? '',
                memberName: row['sender_name'] as String? ?? 'Bilinmeyen',
                message: row['message'] as String? ?? 'Acil durum!',
                timestamp:
                    DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                    DateTime.now(),
              ),
            );
          }
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Color _parseMemberColor(dynamic val, String id) {
    if (val == null) {
      final colors = [
        const Color(0xFF3B82F6),
        const Color(0xFFEC4899),
        const Color(0xFFF97316),
        const Color(0xFF10B981),
        const Color(0xFF8B5CF6),
      ];
      return colors[id.hashCode.abs() % colors.length];
    }
    if (val is int) return Color(val);
    if (val is String) {
      try {
        return Color(int.parse(val.replaceFirst('#', '0xFF')));
      } catch (e) { debugPrint('Safety error: $e'); }
    }
    return const Color(0xFF3B82F6);
  }

  static String _signalFromAccuracy(double? accuracy) {
    if (accuracy == null || accuracy > 100) return 'Zayıf';
    if (accuracy > 50) return 'Orta';
    return 'Güçlü';
  }

  static String _statusTextFromLocation(
    bool isOnline,
    DateTime? lastSeen,
    String? address,
  ) {
    if (!isOnline) {
      if (lastSeen != null) {
        final diff = DateTime.now().difference(lastSeen);
        if (diff.inDays > 0) return 'Son görülme: ${diff.inDays} gün';
        if (diff.inHours > 0) return 'Son görülme: ${diff.inHours}s';
        if (diff.inMinutes > 0) return 'Son görülme: ${diff.inMinutes} dk';
        return 'Son görülme: az önce';
      }
      return 'Çevrimdışı';
    }
    if (address != null && address.isNotEmpty) return address;
    return 'Aktif';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS (stubs for compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> triggerPanic(String memberId) async {
    // In real app this would send to backend
  }

  static Future<void> sendCheckInReminder(String memberId) async {
    // Stub
  }

  static List<SafetyAlert> getRecentAlerts() {
    return [];
  }

  static SafetyReport generateDailyReport() {
    return SafetyReport(
      date: DateTime.now(),
      memberReports: [],
      aiSuggestions: [],
    );
  }
}