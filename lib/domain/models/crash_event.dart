// lib/domain/models/crash_event.dart
// Auto-generated crash detection domain models

import 'dart:math';

// ─────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────

enum CrashTriggerType {
  highImpact,
  rollover,
  suddenStop,
  freeFall,
  multiSensor,
  highJerk,
  suddenSpin,
}

enum CrashResponseStatus {
  detected,
  confirming,
  userResponded,
  autoSos,
  falseAlarm,
  resolved,
}

enum UserResponseType {
  imOk,
  needHelp,
  falseAlarm,
  noResponse,
}

enum NotificationType {
  push,
  sms,
  call,
  email,
  emergencyServices,
}

enum Severity {
  none,
  minor,
  moderate,
  severe,
  critical,
}

enum ActivityType {
  driving,
  cycling,
  walking,
  running,
  stationary,
}

enum TransportModeCrash {
  car,
  motorcycle,
  bicycle,
  bus,
  train,
  onFoot,
}

enum RoadType {
  highway,
  urban,
  rural,
  parking,
}

enum TimeOfDay {
  day,
  night,
  dawn,
  dusk,
}

// ─────────────────────────────────────────────
// ACCELEROMETER DATA
// ─────────────────────────────────────────────

class AccelerometerData {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final double peakG;

  const AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    this.peakG = 0,
  });

  factory AccelerometerData.zero() => const AccelerometerData(
        x: 0,
        y: 0,
        z: 0,
        magnitude: 0,
        peakG: 0,
      );

  factory AccelerometerData.fromJson(Map<String, dynamic> json) =>
      AccelerometerData(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        z: (json['z'] as num?)?.toDouble() ?? 0,
        magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0,
        peakG: (json['peakG'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'magnitude': magnitude,
        'peakG': peakG,
      };

  double get gForce => magnitude / 9.81;
}

// ─────────────────────────────────────────────
// GYROSCOPE DATA
// ─────────────────────────────────────────────

class GyroscopeData {
  final double roll;
  final double pitch;
  final double yaw;

  const GyroscopeData({
    this.roll = 0,
    this.pitch = 0,
    this.yaw = 0,
  });

  factory GyroscopeData.fromJson(Map<String, dynamic> json) => GyroscopeData(
        roll: (json['roll'] as num?)?.toDouble() ?? 0,
        pitch: (json['pitch'] as num?)?.toDouble() ?? 0,
        yaw: (json['yaw'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'roll': roll,
        'pitch': pitch,
        'yaw': yaw,
      };

  double get angularVelocity =>
      sqrt(roll * roll + pitch * pitch + yaw * yaw);
}

// ─────────────────────────────────────────────
// GPS DATA
// ─────────────────────────────────────────────

class CrashGpsData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;

  const CrashGpsData({
    this.latitude = 0,
    this.longitude = 0,
    this.accuracy = 0,
    this.speed = 0,
    this.heading = 0,
  });

  factory CrashGpsData.fromJson(Map<String, dynamic> json) => CrashGpsData(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0,
        heading: (json['heading'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
      };
}

// ─────────────────────────────────────────────
// BAROMETER DATA
// ─────────────────────────────────────────────

class BarometerData {
  final double pressure;
  final double altitude;

  const BarometerData({
    this.pressure = 0,
    this.altitude = 0,
  });

  factory BarometerData.fromJson(Map<String, dynamic> json) => BarometerData(
        pressure: (json['pressure'] as num?)?.toDouble() ?? 0,
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'pressure': pressure,
        'altitude': altitude,
      };
}

// ─────────────────────────────────────────────
// MICROPHONE DATA
// ─────────────────────────────────────────────

class MicrophoneData {
  final double peakDecibel;
  final List<String> detectedSounds;

  const MicrophoneData({
    this.peakDecibel = 0,
    this.detectedSounds = const [],
  });

  factory MicrophoneData.fromJson(Map<String, dynamic> json) =>
      MicrophoneData(
        peakDecibel: (json['peakDecibel'] as num?)?.toDouble() ?? 0,
        detectedSounds:
            (json['detectedSounds'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'peakDecibel': peakDecibel,
        'detectedSounds': detectedSounds,
      };
}

// ─────────────────────────────────────────────
// SENSOR DATA AGGREGATE
// ─────────────────────────────────────────────

class CrashSensorData {
  final AccelerometerData accelerometer;
  final GyroscopeData? gyroscope;
  final CrashGpsData gps;
  final BarometerData? barometer;
  final MicrophoneData? microphone;

  const CrashSensorData({
    required this.accelerometer,
    this.gyroscope,
    required this.gps,
    this.barometer,
    this.microphone,
  });

  factory CrashSensorData.fromJson(Map<String, dynamic> json) =>
      CrashSensorData(
        accelerometer: json['accelerometer'] != null
            ? AccelerometerData.fromJson(
                json['accelerometer'] as Map<String, dynamic>)
            : AccelerometerData.zero(),
        gyroscope: json['gyroscope'] != null
            ? GyroscopeData.fromJson(
                json['gyroscope'] as Map<String, dynamic>)
            : null,
        gps: json['gps'] != null
            ? CrashGpsData.fromJson(json['gps'] as Map<String, dynamic>)
            : const CrashGpsData(),
        barometer: json['barometer'] != null
            ? BarometerData.fromJson(
                json['barometer'] as Map<String, dynamic>)
            : null,
        microphone: json['microphone'] != null
            ? MicrophoneData.fromJson(
                json['microphone'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'accelerometer': accelerometer.toJson(),
        'gyroscope': gyroscope?.toJson(),
        'gps': gps.toJson(),
        'barometer': barometer?.toJson(),
        'microphone': microphone?.toJson(),
      };
}

// ─────────────────────────────────────────────
// DETECTION INFO
// ─────────────────────────────────────────────

class CrashDetection {
  final DateTime timestamp;
  double confidence;
  final CrashTriggerType triggerType;

  CrashDetection({
    required this.timestamp,
    this.confidence = 0,
    required this.triggerType,
  });

  factory CrashDetection.fromJson(Map<String, dynamic> json) => CrashDetection(
        timestamp: DateTime.tryParse(json['timestamp'] as String) ??
            DateTime.now(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        triggerType: CrashTriggerType.values.firstWhere(
          (e) => e.name == json['triggerType'],
          orElse: () => CrashTriggerType.highImpact,
        ),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        'triggerType': triggerType.name,
      };
}

// ─────────────────────────────────────────────
// CONTEXT
// ─────────────────────────────────────────────

class CrashContext {
  final ActivityType activity;
  final TransportModeCrash transportMode;
  final String weather;
  final RoadType? roadType;
  final TimeOfDay timeOfDay;

  const CrashContext({
    this.activity = ActivityType.stationary,
    this.transportMode = TransportModeCrash.onFoot,
    this.weather = '',
    this.roadType,
    this.timeOfDay = TimeOfDay.day,
  });

  factory CrashContext.fromJson(Map<String, dynamic> json) => CrashContext(
        activity: ActivityType.values.firstWhere(
          (e) => e.name == json['activity'],
          orElse: () => ActivityType.stationary,
        ),
        transportMode: TransportModeCrash.values.firstWhere(
          (e) => e.name == json['transportMode'],
          orElse: () => TransportModeCrash.onFoot,
        ),
        weather: json['weather'] as String? ?? '',
        roadType: json['roadType'] != null
            ? RoadType.values.firstWhere(
                (e) => e.name == json['roadType'],
                orElse: () => RoadType.urban,
              )
            : null,
        timeOfDay: TimeOfDay.values.firstWhere(
          (e) => e.name == json['timeOfDay'],
          orElse: () => TimeOfDay.day,
        ),
      );

  Map<String, dynamic> toJson() => {
        'activity': activity.name,
        'transportMode': transportMode.name,
        'weather': weather,
        'roadType': roadType?.name,
        'timeOfDay': timeOfDay.name,
      };
}

// ─────────────────────────────────────────────
// CONFIRMATION WINDOW
// ─────────────────────────────────────────────

class ConfirmationWindow {
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool userResponded;
  final UserResponseType? responseType;

  const ConfirmationWindow({
    this.startedAt,
    this.endedAt,
    this.userResponded = false,
    this.responseType,
  });

  factory ConfirmationWindow.fromJson(Map<String, dynamic> json) =>
      ConfirmationWindow(
        startedAt: DateTime.tryParse(json['startedAt'] as String) ??
            DateTime.now(),
        endedAt: json['endedAt'] != null
            ? DateTime.tryParse(json['endedAt'] as String)
            : null,
        userResponded: json['userResponded'] as bool? ?? false,
        responseType: json['responseType'] != null
            ? UserResponseType.values.firstWhere(
                (e) => e.name == json['responseType'],
                orElse: () => UserResponseType.noResponse,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'userResponded': userResponded,
        'responseType': responseType?.name,
      };
}

// ─────────────────────────────────────────────
// SOS TRIGGERED
// ─────────────────────────────────────────────

class SosTriggered {
  final DateTime triggeredAt;
  final bool autoTriggered;

  const SosTriggered({
    required this.triggeredAt,
    required this.autoTriggered,
  });

  factory SosTriggered.fromJson(Map<String, dynamic> json) => SosTriggered(
        triggeredAt: DateTime.tryParse(json['triggeredAt'] as String) ??
            DateTime.now(),
        autoTriggered: json['autoTriggered'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'triggeredAt': triggeredAt.toIso8601String(),
        'autoTriggered': autoTriggered,
      };
}

// ─────────────────────────────────────────────
// NOTIFICATION SENT
// ─────────────────────────────────────────────

class CrashNotificationSent {
  final NotificationType type;
  final String recipient;
  final DateTime sentAt;
  final bool delivered;

  const CrashNotificationSent({
    required this.type,
    required this.recipient,
    required this.sentAt,
    this.delivered = false,
  });

  factory CrashNotificationSent.fromJson(Map<String, dynamic> json) =>
      CrashNotificationSent(
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.push,
        ),
        recipient: json['recipient'] as String? ?? '',
        sentAt: DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now(),
        delivered: json['delivered'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'recipient': recipient,
        'sentAt': sentAt.toIso8601String(),
        'delivered': delivered,
      };
}

// ─────────────────────────────────────────────
// RESPONSE
// ─────────────────────────────────────────────

class CrashResponse {
  CrashResponseStatus status;
  ConfirmationWindow? confirmationWindow;
  SosTriggered? sosTriggered;
  final List<CrashNotificationSent> notificationsSent;

  CrashResponse({
    this.status = CrashResponseStatus.detected,
    this.confirmationWindow,
    this.sosTriggered,
    this.notificationsSent = const [],
  });

  factory CrashResponse.fromJson(Map<String, dynamic> json) => CrashResponse(
        status: CrashResponseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CrashResponseStatus.detected,
        ),
        confirmationWindow: json['confirmationWindow'] != null
            ? ConfirmationWindow.fromJson(
                json['confirmationWindow'] as Map<String, dynamic>)
            : null,
        sosTriggered: json['sosTriggered'] != null
            ? SosTriggered.fromJson(
                json['sosTriggered'] as Map<String, dynamic>)
            : null,
        notificationsSent: (json['notificationsSent'] as List<dynamic>?)
                ?.map((e) =>
                    CrashNotificationSent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'confirmationWindow': confirmationWindow?.toJson(),
        'sosTriggered': sosTriggered?.toJson(),
        'notificationsSent':
            notificationsSent.map((n) => n.toJson()).toList(),
      };
}

// ─────────────────────────────────────────────
// OUTCOME
// ─────────────────────────────────────────────

class CrashOutcome {
  final Severity severity;
  final List<String> injuries;
  final String? vehicleDamage;
  final bool emergencyServicesCalled;
  final bool hospitalVisit;

  const CrashOutcome({
    this.severity = Severity.none,
    this.injuries = const [],
    this.vehicleDamage,
    this.emergencyServicesCalled = false,
    this.hospitalVisit = false,
  });

  factory CrashOutcome.fromJson(Map<String, dynamic> json) => CrashOutcome(
        severity: Severity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => Severity.none,
        ),
        injuries:
            (json['injuries'] as List<dynamic>?)?.cast<String>() ?? [],
        vehicleDamage: json['vehicleDamage'] as String?,
        emergencyServicesCalled:
            json['emergencyServicesCalled'] as bool? ?? false,
        hospitalVisit: json['hospitalVisit'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'injuries': injuries,
        'vehicleDamage': vehicleDamage,
        'emergencyServicesCalled': emergencyServicesCalled,
        'hospitalVisit': hospitalVisit,
      };
}

// ─────────────────────────────────────────────
// ML FEATURES
// ─────────────────────────────────────────────

class CrashMlFeatures {
  final double? preCrashSpeed;
  final double? speedChange;
  final String? impactDirection;
  final bool airbagDeployed;
  final bool seatbeltUsed;

  const CrashMlFeatures({
    this.preCrashSpeed,
    this.speedChange,
    this.impactDirection,
    this.airbagDeployed = false,
    this.seatbeltUsed = false,
  });

  factory CrashMlFeatures.fromJson(Map<String, dynamic> json) =>
      CrashMlFeatures(
        preCrashSpeed: (json['preCrashSpeed'] as num?)?.toDouble(),
        speedChange: (json['speedChange'] as num?)?.toDouble(),
        impactDirection: json['impactDirection'] as String?,
        airbagDeployed: json['airbagDeployed'] as bool? ?? false,
        seatbeltUsed: json['seatbeltUsed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'preCrashSpeed': preCrashSpeed,
        'speedChange': speedChange,
        'impactDirection': impactDirection,
        'airbagDeployed': airbagDeployed,
        'seatbeltUsed': seatbeltUsed,
      };
}

// ─────────────────────────────────────────────
// MAIN CRASH EVENT
// ─────────────────────────────────────────────

class CrashEvent {
  String? eventId;
  final String familyId;
  final String memberId;
  final String memberName;
  final CrashDetection detection;
  CrashSensorData sensorData;
  final CrashContext context;
  final CrashResponse response;
  final CrashOutcome? outcome;
  final CrashMlFeatures? mlFeatures;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? reviewedBy;
  final bool isFalsePositive;

  CrashEvent({
    this.eventId,
    required this.familyId,
    required this.memberId,
    required this.memberName,
    required this.detection,
    required this.sensorData,
    required this.context,
    required this.response,
    this.outcome,
    this.mlFeatures,
    required this.createdAt,
    this.resolvedAt,
    this.reviewedBy,
    this.isFalsePositive = false,
  });

  factory CrashEvent.fromJson(Map<String, dynamic> json) => CrashEvent(
        eventId: json['eventId'] as String?,
        familyId: json['familyId'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        memberName: json['memberName'] as String? ?? '',
        detection: CrashDetection.fromJson(
            json['detection'] as Map<String, dynamic>),
        sensorData: CrashSensorData.fromJson(
            json['sensorData'] as Map<String, dynamic>),
        context:
            CrashContext.fromJson(json['context'] as Map<String, dynamic>),
        response:
            CrashResponse.fromJson(json['response'] as Map<String, dynamic>),
        outcome: json['outcome'] != null
            ? CrashOutcome.fromJson(json['outcome'] as Map<String, dynamic>)
            : null,
        mlFeatures: json['mlFeatures'] != null
            ? CrashMlFeatures.fromJson(
                json['mlFeatures'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] as String) ??
            DateTime.now(),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'] as String)
            : null,
        reviewedBy: json['reviewedBy'] as String?,
        isFalsePositive: json['isFalsePositive'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'familyId': familyId,
        'memberId': memberId,
        'memberName': memberName,
        'detection': detection.toJson(),
        'sensorData': sensorData.toJson(),
        'context': context.toJson(),
        'response': response.toJson(),
        'outcome': outcome?.toJson(),
        'mlFeatures': mlFeatures?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
        'isFalsePositive': isFalsePositive,
      };

  /// Computed severity label for UI
  String get severityLabel {
    if (detection.confidence >= 0.9) return 'KRİTİK';
    if (detection.confidence >= 0.7) return 'CİDDİ';
    if (detection.confidence >= 0.5) return 'ORTA';
    return 'DÜŞÜK';
  }

  /// Whether this event is still active (needs user attention)
  bool get isActive =>
      response.status == CrashResponseStatus.detected ||
      response.status == CrashResponseStatus.confirming;
}
