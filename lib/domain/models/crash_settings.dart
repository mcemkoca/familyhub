// lib/domain/models/crash_settings.dart
// Crash detection user settings & emergency contacts

enum CrashSensitivity { low, medium, high, custom }

enum VibrationPattern { sos, alarm, pulse }

enum CrashTestResult { passed, failed }

// ─────────────────────────────────────────────
// CUSTOM THRESHOLDS
// ─────────────────────────────────────────────

class CustomThresholds {
  final double minImpactG; // default 4G
  final double minSpeedChange; // m/s
  final double rolloverThreshold; // rad/s
  final int confirmationWindowSeconds; // default 30

  const CustomThresholds({
    this.minImpactG = 4.0,
    this.minSpeedChange = 8.0,
    this.rolloverThreshold = 5.0,
    this.confirmationWindowSeconds = 30,
  });

  factory CustomThresholds.fromJson(Map<String, dynamic> json) =>
      CustomThresholds(
        minImpactG: (json['minImpactG'] as num?)?.toDouble() ?? 4.0,
        minSpeedChange: (json['minSpeedChange'] as num?)?.toDouble() ?? 8.0,
        rolloverThreshold:
            (json['rolloverThreshold'] as num?)?.toDouble() ?? 5.0,
        confirmationWindowSeconds:
            (json['confirmationWindowSeconds'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toJson() => {
        'minImpactG': minImpactG,
        'minSpeedChange': minSpeedChange,
        'rolloverThreshold': rolloverThreshold,
        'confirmationWindowSeconds': confirmationWindowSeconds,
      };
}

// ─────────────────────────────────────────────
// EMERGENCY CONTACT
// ─────────────────────────────────────────────

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;
  final int priority;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation = '',
    this.priority = 1,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relation: json['relation'] as String? ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
        'priority': priority,
      };
}

// ─────────────────────────────────────────────
// SOS CONFIG
// ─────────────────────────────────────────────

class SosConfig {
  final bool autoCallEmergency;
  final bool autoNotifyFamily;
  final bool autoNotifyContacts;
  final bool shareLocation;
  final bool shareMedicalInfo;

  const SosConfig({
    this.autoCallEmergency = false,
    this.autoNotifyFamily = true,
    this.autoNotifyContacts = true,
    this.shareLocation = true,
    this.shareMedicalInfo = true,
  });

  factory SosConfig.fromJson(Map<String, dynamic> json) => SosConfig(
        autoCallEmergency: json['autoCallEmergency'] as bool? ?? false,
        autoNotifyFamily: json['autoNotifyFamily'] as bool? ?? true,
        autoNotifyContacts: json['autoNotifyContacts'] as bool? ?? true,
        shareLocation: json['shareLocation'] as bool? ?? true,
        shareMedicalInfo: json['shareMedicalInfo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'autoCallEmergency': autoCallEmergency,
        'autoNotifyFamily': autoNotifyFamily,
        'autoNotifyContacts': autoNotifyContacts,
        'shareLocation': shareLocation,
        'shareMedicalInfo': shareMedicalInfo,
      };
}

// ─────────────────────────────────────────────
// NOTIFICATION SETTINGS
// ─────────────────────────────────────────────

class CrashNotificationSettings {
  final bool soundAlert;
  final String soundType; // 'crash_alarm', 'siren', 'plain'
  final bool vibration;
  final VibrationPattern vibrationPattern;
  final bool screenFlash;
  final bool maxVolume;
  final bool bypassDnd;

  const CrashNotificationSettings({
    this.soundAlert = true,
    this.soundType = 'crash_alarm',
    this.vibration = true,
    this.vibrationPattern = VibrationPattern.sos,
    this.screenFlash = true,
    this.maxVolume = true,
    this.bypassDnd = false,
  });

  factory CrashNotificationSettings.fromJson(Map<String, dynamic> json) =>
      CrashNotificationSettings(
        soundAlert: json['soundAlert'] as bool? ?? true,
        soundType: json['soundType'] as String? ?? 'crash_alarm',
        vibration: json['vibration'] as bool? ?? true,
        vibrationPattern: VibrationPattern.values.firstWhere(
          (e) => e.name == json['vibrationPattern'],
          orElse: () => VibrationPattern.sos,
        ),
        screenFlash: json['screenFlash'] as bool? ?? true,
        maxVolume: json['maxVolume'] as bool? ?? true,
        bypassDnd: json['bypassDnd'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'soundAlert': soundAlert,
        'soundType': soundType,
        'vibration': vibration,
        'vibrationPattern': vibrationPattern.name,
        'screenFlash': screenFlash,
        'maxVolume': maxVolume,
        'bypassDnd': bypassDnd,
      };
}

// ─────────────────────────────────────────────
// TEST MODE
// ─────────────────────────────────────────────

class CrashTestMode {
  final bool enabled;
  final DateTime? lastTestDate;
  final CrashTestResult? lastResult;

  const CrashTestMode({
    this.enabled = false,
    this.lastTestDate,
    this.lastResult,
  });

  factory CrashTestMode.fromJson(Map<String, dynamic> json) => CrashTestMode(
        enabled: json['enabled'] as bool? ?? false,
        lastTestDate: json['lastTestDate'] != null
            ? DateTime.tryParse(json['lastTestDate'] as String)
            : null,
        lastResult: json['lastResult'] != null
            ? CrashTestResult.values.firstWhere(
                (e) => e.name == json['lastResult'],
                orElse: () => CrashTestResult.passed,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'lastTestDate': lastTestDate?.toIso8601String(),
        'lastResult': lastResult?.name,
      };
}

// ─────────────────────────────────────────────
// MAIN SETTINGS
// ─────────────────────────────────────────────

class CrashDetectionSettings {
  final String memberId;
  final bool enabled;
  final CrashSensitivity sensitivity;
  final CustomThresholds customThresholds;
  final SosConfig sosConfig;
  final List<EmergencyContact> emergencyContacts;
  final CrashNotificationSettings notifications;
  final CrashTestMode testMode;
  final DateTime updatedAt;

  const CrashDetectionSettings({
    required this.memberId,
    this.enabled = true,
    this.sensitivity = CrashSensitivity.medium,
    this.customThresholds = const CustomThresholds(),
    this.sosConfig = const SosConfig(),
    this.emergencyContacts = const [],
    this.notifications = const CrashNotificationSettings(),
    this.testMode = const CrashTestMode(),
    required this.updatedAt,
  });

  factory CrashDetectionSettings.fromJson(Map<String, dynamic> json) =>
      CrashDetectionSettings(
        memberId: json['memberId'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        sensitivity: CrashSensitivity.values.firstWhere(
          (e) => e.name == json['sensitivity'],
          orElse: () => CrashSensitivity.medium,
        ),
        customThresholds: json['customThresholds'] != null
            ? CustomThresholds.fromJson(
                json['customThresholds'] as Map<String, dynamic>)
            : const CustomThresholds(),
        sosConfig: json['sosConfig'] != null
            ? SosConfig.fromJson(
                json['sosConfig'] as Map<String, dynamic>)
            : const SosConfig(),
        emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
                ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notifications: json['notifications'] != null
            ? CrashNotificationSettings.fromJson(
                json['notifications'] as Map<String, dynamic>)
            : const CrashNotificationSettings(),
        testMode: json['testMode'] != null
            ? CrashTestMode.fromJson(
                json['testMode'] as Map<String, dynamic>)
            : const CrashTestMode(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String) ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'enabled': enabled,
        'sensitivity': sensitivity.name,
        'customThresholds': customThresholds.toJson(),
        'sosConfig': sosConfig.toJson(),
        'emergencyContacts':
            emergencyContacts.map((e) => e.toJson()).toList(),
        'notifications': notifications.toJson(),
        'testMode': testMode.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Resolve effective thresholds based on sensitivity level
  CustomThresholds get effectiveThresholds {
    switch (sensitivity) {
      case CrashSensitivity.low:
        return const CustomThresholds(
          minImpactG: 6.0,
          minSpeedChange: 12.0,
          rolloverThreshold: 7.0,
          confirmationWindowSeconds: 20,
        );
      case CrashSensitivity.medium:
        return const CustomThresholds(
          minImpactG: 4.0,
          minSpeedChange: 8.0,
          rolloverThreshold: 5.0,
          confirmationWindowSeconds: 30,
        );
      case CrashSensitivity.high:
        return const CustomThresholds(
          minImpactG: 2.5,
          minSpeedChange: 5.0,
          rolloverThreshold: 3.0,
          confirmationWindowSeconds: 45,
        );
      case CrashSensitivity.custom:
        return customThresholds;
    }
  }
}
