// lib/services/crash_detection_service.dart
// High-level crash detection service: orchestrates engine, notifications, SOS

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/supabase_client.dart';
import '../domain/models/crash_event.dart';
import '../domain/models/crash_settings.dart';
import '../services/health_card_service.dart';
import '../services/hive_service.dart';
import 'crash_detection_engine.dart';
import 'localization/locale_service.dart';

/// High-level service that wires the [CrashDetectionEngine] to
/// notifications, audio alarms, vibration, and SOS actions.
class CrashDetectionService {
  static final CrashDetectionService _instance =
      CrashDetectionService._internal();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._internal();

  String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

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

  /// Yalnızca sesli/ışıklı alarmı susturur (geri sayım/izleme devam eder).
  void silenceAlarm() => _stopAlarm();

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
        try { await TorchLight.disableTorch(); } catch (e) { debugPrint('Crash detection error: $e'); }
        return;
      }
      try {
        await TorchLight.enableTorch();
        await Future.delayed(const Duration(milliseconds: 250));
        await TorchLight.disableTorch();
      } catch (e) { debugPrint('Crash detection error: $e'); }
    });
  }

  void _stopFlashAlarm() {
    _flashTimer?.cancel();
    _flashTimer = null;
    try { TorchLight.disableTorch(); } catch (e) { debugPrint('Crash detection error: $e'); }
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

  /// Ayarlardaki (bulut) + yerel (Hive) acil kişi telefonlarını birleştirir.
  static List<String> _allContactPhones(CrashDetectionSettings? settings) {
    final phones = <String>{};
    for (final EmergencyContact c
        in settings?.emergencyContacts ?? const <EmergencyContact>[]) {
      if (c.phone.isNotEmpty) phones.add(c.phone);
    }
    final raw = HiveService.getSetting('emergency_contacts');
    if (raw != null && raw.isNotEmpty) {
      try {
        for (final e in jsonDecode(raw) as List) {
          final p = (e as Map)['phone']?.toString() ?? '';
          if (p.isNotEmpty) phones.add(p);
        }
      } catch (_) {}
    }
    return phones.toList();
  }

  Future<void> _notifyEmergencyContacts(CrashEvent event) async {
    for (final phone in _allContactPhones(_settings)) {
      if (phone.isEmpty) continue;

      final latitude = event.sensorData.gps.latitude;
      final longitude = event.sensorData.gps.longitude;
      final message = _text({
        'tr': 'ACİL DURUM: Kaza tespit edildi. Konum: $latitude, $longitude. Lütfen yardım için arayın veya konuma gelin.',
        'en': 'EMERGENCY: A crash was detected. Location: $latitude, $longitude. Please call to help or come to the location.',
        'nl': 'NOODGEVAL: Er is een ongeval gedetecteerd. Locatie: $latitude, $longitude. Bel om te helpen of kom naar de locatie.',
        'fr': 'URGENCE : Un accident a été détecté. Position : $latitude, $longitude. Appelez pour aider ou rendez-vous sur place.',
      });

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

      final allergies = healthData.allergies.join(', ');
      final medications = healthData.medications.map((m) => m.name).join(', ');
      final conditions = healthData.chronicConditions.join(', ');
      final donor = healthData.organDonor
          ? _text(const {'tr': 'Evet', 'en': 'Yes', 'nl': 'Ja', 'fr': 'Oui'})
          : _text(const {'tr': 'Hayır', 'en': 'No', 'nl': 'Nee', 'fr': 'Non'});
      final info = _text({
        'tr': 'Sağlık Bilgileri:\nKan Grubu: ${healthData.bloodType}\nAlerjiler: $allergies\nİlaçlar: $medications\nKronik Hastalıklar: $conditions\nOrgan Bağışı: $donor\nAcil Durum Kişisi: ${healthData.emergencyContactName} (${healthData.emergencyContactPhone})\nDoktor: ${healthData.doctorName} (${healthData.doctorPhone})',
        'en': 'Medical Information:\nBlood Type: ${healthData.bloodType}\nAllergies: $allergies\nMedications: $medications\nChronic Conditions: $conditions\nOrgan Donor: $donor\nEmergency Contact: ${healthData.emergencyContactName} (${healthData.emergencyContactPhone})\nDoctor: ${healthData.doctorName} (${healthData.doctorPhone})',
        'nl': 'Medische gegevens:\nBloedgroep: ${healthData.bloodType}\nAllergieën: $allergies\nMedicijnen: $medications\nChronische aandoeningen: $conditions\nOrgaandonor: $donor\nContactpersoon voor noodgevallen: ${healthData.emergencyContactName} (${healthData.emergencyContactPhone})\nArts: ${healthData.doctorName} (${healthData.doctorPhone})',
        'fr': 'Informations médicales :\nGroupe sanguin : ${healthData.bloodType}\nAllergies : $allergies\nMédicaments : $medications\nMaladies chroniques : $conditions\nDon d’organes : $donor\nContact d’urgence : ${healthData.emergencyContactName} (${healthData.emergencyContactPhone})\nMédecin : ${healthData.doctorName} (${healthData.doctorPhone})',
      });

      // Share via SMS to emergency contacts (bulut + yerel)
      for (final phone in _allContactPhones(_settings)) {
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
