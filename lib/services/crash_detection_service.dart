// lib/services/crash_detection_service.dart
// High-level crash detection service: orchestrates engine, notifications, SOS

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/supabase_client.dart';
import '../domain/models/crash_event.dart';
import '../domain/models/crash_settings.dart';
import '../services/health_card_service.dart';
import 'crash_detection_engine.dart';

/// High-level service that wires the [CrashDetectionEngine] to
/// notifications, audio alarms, vibration, and SOS actions.
class CrashDetectionService {
  static final CrashDetectionService _instance =
      CrashDetectionService._internal();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._internal();

  final CrashDetectionEngine _engine = CrashDetectionEngine();
  CrashDetectionSettings? _settings;

  // ── Streams ──
  Stream<CrashEvent> get crashEventStream => _engine.crashEventStream;

  // ── State ──
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  CrashEvent? _activeEvent;
  CrashEvent? get activeEvent => _activeEvent;

  // ── Callbacks for UI layer ──
  ValueNotifier<CrashEvent?> activeEventNotifier = ValueNotifier(null);
  ValueNotifier<bool> isConfirmingNotifier = ValueNotifier(false);

  // ── SOS countdown ──
  Timer? _countdownTimer;
  ValueNotifier<int> countdownNotifier = ValueNotifier(30);

  // ═══════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════
  void initialize({
    required CrashDetectionSettings settings,
    VoidCallback? onAlarmTriggered,
  }) {
    _settings = settings;
    _engine.applySettings(settings);

    _engine.onConfirmationNeeded = (event) {
      _activeEvent = event;
      activeEventNotifier.value = event;
      isConfirmingNotifier.value = true;
      _triggerAlarm();
      _startCountdown(settings.effectiveThresholds.confirmationWindowSeconds);
      onAlarmTriggered?.call();
    };

    _engine.onAutoSos = (event) {
      _executeSOS(event);
    };

    _engine.onFalsePositive = () {
      _stopAlarm();
      isConfirmingNotifier.value = false;
      _activeEvent = null;
      activeEventNotifier.value = null;
    };
  }

  // ═══════════════════════════════════════════
  // SENSOR INPUTS (called by background service or UI)
  // ═══════════════════════════════════════════
  void feedAccelerometer(double x, double y, double z) {
    if (!_isMonitoring || _settings?.enabled != true) return;
    _engine.processAccelerometer(x, y, z);
  }

  void feedGyroscope(double x, double y, double z) {
    if (!_isMonitoring || _settings?.enabled != true) return;
    _engine.processGyroscope(x, y, z);
  }

  void feedGPS(
    double lat,
    double lng,
    double accuracy,
    double speed,
    double heading,
  ) {
    if (!_isMonitoring || _settings?.enabled != true) return;
    _engine.processGPS(lat, lng, accuracy, speed, heading);
  }

  // ═══════════════════════════════════════════
  // MONITORING CONTROL
  // ═══════════════════════════════════════════
  void startMonitoring() {
    _isMonitoring = true;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _engine.cancelPending();
    _stopAlarm();
    _countdownTimer?.cancel();
  }

  // ═══════════════════════════════════════════
  // ALARM
  // ═══════════════════════════════════════════
  bool _alarmActive = false;

  void _triggerAlarm() {
    if (_alarmActive) return;
    _alarmActive = true;

    final notif = _settings?.notifications;
    if (notif == null) return;

    // Vibration
    if (notif.vibration) {
      _startVibration(notif.vibrationPattern);
    }

    // Screen flash
    _startFlashAlarm();
  }

  void _stopAlarm() {
    _alarmActive = false;
    _stopFlashAlarm();
  }

  Timer? _flashTimer;

  void _startFlashAlarm() {
    _flashTimer?.cancel();
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_alarmActive) {
        timer.cancel();
        try { await TorchLight.disableTorch(); } catch (_) {}
        return;
      }
      try {
        await TorchLight.enableTorch();
        await Future.delayed(const Duration(milliseconds: 250));
        await TorchLight.disableTorch();
      } catch (_) {}
    });
  }

  void _stopFlashAlarm() {
    _flashTimer?.cancel();
    _flashTimer = null;
    try { TorchLight.disableTorch(); } catch (_) {}
  }

  void _startVibration(VibrationPattern pattern) {
    // Lightweight vibration patterns
    switch (pattern) {
      case VibrationPattern.sos:
        // short short short  long long long  short short short
        _vibrateSOS();
        break;
      case VibrationPattern.alarm:
        HapticFeedback.heavyImpact();
        break;
      case VibrationPattern.pulse:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  void _vibrateSOS() {
    // Best-effort SOS pattern via HapticFeedback
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_alarmActive) {
        timer.cancel();
        return;
      }
      HapticFeedback.heavyImpact();
    });
  }

  // ═══════════════════════════════════════════
  // COUNTDOWN
  // ═══════════════════════════════════════════
  void _startCountdown(int seconds) {
    countdownNotifier.value = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownNotifier.value <= 1) {
        timer.cancel();
        return;
      }
      countdownNotifier.value--;
    });
  }

  // ═══════════════════════════════════════════
  // USER RESPONSES
  // ═══════════════════════════════════════════
  void respondImOk() {
    if (_activeEvent == null) return;
    _stopAlarm();
    _countdownTimer?.cancel();
    _engine.userRespondedImOk(_activeEvent!);
    _activeEvent = null;
    activeEventNotifier.value = null;
    isConfirmingNotifier.value = false;
  }

  void respondNeedHelp() {
    if (_activeEvent == null) return;
    _stopAlarm();
    _countdownTimer?.cancel();
    _engine.userRespondedNeedHelp(_activeEvent!);
    // _activeEvent cleared by onAutoSos callback
  }

  void respondFalseAlarm() {
    respondImOk(); // Same flow
  }

  // ═══════════════════════════════════════════
  // SOS EXECUTION
  // ═══════════════════════════════════════════
  Future<void> _executeSOS(CrashEvent event) async {
    isConfirmingNotifier.value = false;
    _activeEvent = event;
    activeEventNotifier.value = event;

    final sos = _settings?.sosConfig;
    if (sos == null) return;

    // 1. Notify family members
    if (sos.autoNotifyFamily) {
      _notifyFamilyMembers(event);
    }

    // 2. Notify emergency contacts
    if (sos.autoNotifyContacts) {
      await _notifyEmergencyContacts(event);
    }

    // 3. Share location
    if (sos.shareLocation) {
      await _startLocationSharing(event);
    }

    // 4. Auto-call emergency (if enabled)
    if (sos.autoCallEmergency) {
      await _callEmergencyServices(event);
    }

    // 5. Share medical info
    if (sos.shareMedicalInfo) {
      await _shareMedicalInfo(event);
    }
  }

  void _notifyFamilyMembers(CrashEvent event) {
    final userId = SupabaseConfig.safeClient?.auth.currentUser?.id;
    if (userId == null) return;
    // Fire-and-forget: notify family members via Supabase Realtime / Edge Function
    SupabaseConfig.safeClient!.rpc('notify_family_crash', params: {
      'sender_id': userId,
      'family_id': event.familyId,
      'latitude': event.sensorData.gps.latitude,
      'longitude': event.sensorData.gps.longitude,
      'confidence': event.detection.confidence,
    }).catchError((_) {});
  }

  void callFamilyMembers() {
    if (_activeEvent != null) {
      _notifyFamilyMembers(_activeEvent!);
    }
  }

  Future<void> _notifyEmergencyContacts(CrashEvent event) async {
    final contacts = _settings?.emergencyContacts ?? [];
    for (final contact in contacts) {
      final phone = contact.phone;
      if (phone.isEmpty) continue;

      final message = 'ACIL DURUM: Kaza tespit edildi. '
          'Konum: ${event.sensorData.gps.latitude}, ${event.sensorData.gps.longitude}. '
          'Lütfen yardım için ara veya konuma gel.';

      // Launch SMS composer
      final smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }

      // Optional: auto-call after delay (if auto-call emergency is enabled globally)
      if (_settings?.sosConfig.autoCallEmergency == true) {
        await Future.delayed(const Duration(seconds: 3));
        final telUri = Uri(scheme: 'tel', path: phone);
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        }
      }
    }
  }

  Future<void> _startLocationSharing(CrashEvent event) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;
      final eventId = event.eventId;
      if (eventId == null || eventId.isEmpty) return;

      // Update crash event with location
      await client.from('crash_events').update({
        'latitude': event.sensorData.gps.latitude,
        'longitude': event.sensorData.gps.longitude,
        'location_shared_at': DateTime.now().toIso8601String(),
      }).eq('id', eventId);
    } catch (e) {
      debugPrint('CrashDetectionService location share error: $e');
    }
  }

  Future<void> _callEmergencyServices(CrashEvent event) async {
    const number = '112';
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareMedicalInfo(CrashEvent event) async {
    try {
      final healthData = await HealthCardService.load();
      if (healthData == null) return;

      final info = 'Sağlık Bilgileri:\n'
          'Kan Grubu: ${healthData.bloodType}\n'
          'Alerjiler: ${healthData.allergies.join(", ")}\n'
          'İlaçlar: ${healthData.medications.map((m) => m.name).join(", ")}\n'
          'Kronik Hastalıklar: ${healthData.chronicConditions.join(", ")}\n'
          'Organ Bağışı: ${healthData.organDonor ? "Evet" : "Hayır"}\n'
          'Acil Durum Kişisi: ${healthData.emergencyContactName} (${healthData.emergencyContactPhone})\n'
          'Doktor: ${healthData.doctorName} (${healthData.doctorPhone})';

      // Share via SMS to emergency contacts
      final contacts = _settings?.emergencyContacts ?? [];
      for (final contact in contacts) {
        final phone = contact.phone;
        if (phone.isEmpty) continue;
        final smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': info});
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }
    } catch (e) {
      debugPrint('CrashDetectionService share medical info error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════
  void dispose() {
    stopMonitoring();
    _engine.dispose();
    activeEventNotifier.dispose();
    isConfirmingNotifier.dispose();
    countdownNotifier.dispose();
  }
}
