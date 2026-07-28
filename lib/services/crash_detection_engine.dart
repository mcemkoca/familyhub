// lib/services/crash_detection_engine.dart
// Multi-sensor crash detection engine with confidence scoring

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../domain/models/crash_event.dart';
import '../domain/models/crash_settings.dart';

/// Callback when a crash event needs confirmation
typedef CrashConfirmationCallback = void Function(CrashEvent event);

/// Callback when SOS is auto-triggered
typedef AutoSosCallback = void Function(CrashEvent event);

/// Multi-sensor crash detection engine.
/// Listens to accelerometer, gyroscope, and GPS streams,
/// fuses data, computes confidence, and triggers confirmation/SOS flow.
class CrashDetectionEngine {
  static final CrashDetectionEngine _instance =
      CrashDetectionEngine._internal();
  factory CrashDetectionEngine() => _instance;
  CrashDetectionEngine._internal();

  // ── Thresholds (overridden by settings) ──
  double _impactGThreshold = 4.0;
  final double _jerkThreshold = 200.0; // m/s³
  double _rolloverThreshold = 5.0; // rad/s
  final double _spinThreshold = 8.0; // rad/s²
  final double _decelerationThreshold = 10.0; // m/s² per second
  final double _confirmationThreshold = 0.65;
  int _confirmationWindowSeconds = 30;

  // ── State ──
  CrashEvent? _pendingCrashEvent;
  DateTime? _lastAccelTime;
  double _lastAccelMagnitude = 9.81;
  double _lastGForce = 1.0;
  DateTime? _freeFallStartTime;
  int _rolloverCounter = 0;
  double? _lastAngularVelocity;
  CrashGpsData? _lastPosition;
  DateTime? _lastPositionTime;

  // ── Stream controllers ──
  final _crashEventController = StreamController<CrashEvent>.broadcast();
  Stream<CrashEvent> get crashEventStream => _crashEventController.stream;

  // ── Callbacks ──
  CrashConfirmationCallback? onConfirmationNeeded;
  AutoSosCallback? onAutoSos;
  VoidCallback? onFalsePositive;

  // ── Settings ──
  void applySettings(CrashDetectionSettings settings) {
    final t = settings.effectiveThresholds;
    _impactGThreshold = t.minImpactG;
    _confirmationWindowSeconds = t.confirmationWindowSeconds;
    _rolloverThreshold = t.rolloverThreshold;
  }

  // ═══════════════════════════════════════════
  // ACCELEROMETER PROCESSING
  // ═══════════════════════════════════════════
  void processAccelerometer(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    final gForce = magnitude / 9.81;
    final now = DateTime.now();

    // High jerk detection
    if (_lastAccelTime != null) {
      final dtMicros = now.difference(_lastAccelTime!).inMicroseconds;
      if (dtMicros > 0) {
        final dt = dtMicros / 1000000.0;
        final jerk = (magnitude - _lastAccelMagnitude).abs() / dt;
        if (jerk > _jerkThreshold) {
          _potentialCrashDetected(
            trigger: CrashTriggerType.highJerk,
            accelData: AccelerometerData(
              x: x,
              y: y,
              z: z,
              magnitude: magnitude,
              peakG: gForce,
            ),
            extra: {'jerk': jerk},
          );
        }
      }
    }

    // High impact detection
    if (gForce > _impactGThreshold) {
      _potentialCrashDetected(
        trigger: CrashTriggerType.highImpact,
        accelData: AccelerometerData(
          x: x,
          y: y,
          z: z,
          magnitude: magnitude,
          peakG: gForce,
        ),
      );
    }

    // Free fall detection (near 0G)
    if (gForce < 0.3 && _lastGForce > 0.8) {
      _freeFallStartTime = now;
    }

    // Free fall + impact
    if (_freeFallStartTime != null && gForce > 3.0) {
      final freeFallDuration = now
          .difference(_freeFallStartTime!)
          .inMilliseconds;
      if (freeFallDuration > 100) {
        _potentialCrashDetected(
          trigger: CrashTriggerType.freeFall,
          accelData: AccelerometerData(
            x: x,
            y: y,
            z: z,
            magnitude: magnitude,
            peakG: gForce,
          ),
          extra: {'freeFallDurationMs': freeFallDuration},
        );
      }
      _freeFallStartTime = null;
    }

    _lastAccelTime = now;
    _lastAccelMagnitude = magnitude;
    _lastGForce = gForce;
  }

  // ═══════════════════════════════════════════
  // GYROSCOPE PROCESSING
  // ═══════════════════════════════════════════
  void processGyroscope(double x, double y, double z) {
    final angularVelocity = sqrt(x * x + y * y + z * z);

    // Rollover detection
    if (angularVelocity > _rolloverThreshold) {
      _rolloverCounter++;
      if (_rolloverCounter > 5) {
        _potentialCrashDetected(
          trigger: CrashTriggerType.rollover,
          gyroData: GyroscopeData(roll: x, pitch: y, yaw: z),
          extra: {'rolloverCount': _rolloverCounter},
        );
      }
    } else {
      _rolloverCounter = 0;
    }

    // Sudden spin
    if (_lastAngularVelocity != null) {
      final delta = (angularVelocity - _lastAngularVelocity!).abs();
      if (delta > _spinThreshold) {
        _potentialCrashDetected(
          trigger: CrashTriggerType.suddenSpin,
          gyroData: GyroscopeData(roll: x, pitch: y, yaw: z),
          extra: {'spinDelta': delta},
        );
      }
    }

    _lastAngularVelocity = angularVelocity;
  }

  // ═══════════════════════════════════════════
  // GPS PROCESSING
  // ═══════════════════════════════════════════
  void processGPS(
    double latitude,
    double longitude,
    double accuracy,
    double speed,
    double heading,
  ) {
    final now = DateTime.now();
    final currentPos = CrashGpsData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
    );

    if (_lastPosition != null && _lastPositionTime != null) {
      final speedChange = (_lastPosition!.speed - speed).abs();
      final timeDelta = now.difference(_lastPositionTime!).inSeconds;
      if (timeDelta > 0) {
        final deceleration = speedChange / timeDelta;
        if (deceleration > _decelerationThreshold && speed < 2) {
          _potentialCrashDetected(
            trigger: CrashTriggerType.suddenStop,
            gpsData: currentPos,
            extra: {
              'speedBefore': _lastPosition!.speed,
              'deceleration': deceleration,
            },
          );
        }
      }
    }

    _lastPosition = currentPos;
    _lastPositionTime = now;
  }

  // ═══════════════════════════════════════════
  // POTENTIAL CRASH DETECTION
  // ═══════════════════════════════════════════
  void _potentialCrashDetected({
    required CrashTriggerType trigger,
    AccelerometerData? accelData,
    GyroscopeData? gyroData,
    CrashGpsData? gpsData,
    Map<String, dynamic>? extra,
  }) {
    final now = DateTime.now();

    // Debounce: if pending event is < 2s old, merge
    if (_pendingCrashEvent != null &&
        now.difference(_pendingCrashEvent!.detection.timestamp).inSeconds < 2) {
      _mergeTrigger(
        _pendingCrashEvent!,
        trigger,
        accelData,
        gyroData,
        gpsData,
        extra,
      );
    } else {
      _pendingCrashEvent = _createNewCrashEvent(
        trigger: trigger,
        accelData: accelData,
        gyroData: gyroData,
        gpsData: gpsData,
        extra: extra,
        now: now,
      );
    }

    // Check threshold
    if (_pendingCrashEvent!.detection.confidence >= _confirmationThreshold) {
      final event = _pendingCrashEvent!;
      _pendingCrashEvent = null;
      _confirmCrash(event);
    }
  }

  CrashEvent _createNewCrashEvent({
    required CrashTriggerType trigger,
    AccelerometerData? accelData,
    GyroscopeData? gyroData,
    CrashGpsData? gpsData,
    Map<String, dynamic>? extra,
    required DateTime now,
  }) {
    final sensorData = CrashSensorData(
      accelerometer: accelData ?? AccelerometerData.zero(),
      gyroscope: gyroData,
      gps: gpsData ?? _lastPosition ?? const CrashGpsData(),
    );

    final double initialConfidence = _initialConfidence(trigger, extra);

    return CrashEvent(
      familyId: '', // filled by service layer
      memberId: '',
      memberName: '',
      detection: CrashDetection(
        timestamp: now,
        confidence: initialConfidence,
        triggerType: trigger,
      ),
      sensorData: sensorData,
      context: const CrashContext(),
      response: CrashResponse(),
      createdAt: now,
    );
  }

  void _mergeTrigger(
    CrashEvent existing,
    CrashTriggerType newTrigger,
    AccelerometerData? accelData,
    GyroscopeData? gyroData,
    CrashGpsData? gpsData,
    Map<String, dynamic>? extra,
  ) {
    existing.detection.confidence = _calculateMergedConfidence(
      existing,
      newTrigger,
      accelData,
      gyroData,
      gpsData,
      extra,
    );

    // Update peak G
    if (accelData != null &&
        accelData.peakG > existing.sensorData.accelerometer.peakG) {
      existing.sensorData = CrashSensorData(
        accelerometer: accelData,
        gyroscope: gyroData ?? existing.sensorData.gyroscope,
        gps: gpsData ?? existing.sensorData.gps,
        barometer: existing.sensorData.barometer,
        microphone: existing.sensorData.microphone,
      );
    }
  }

  // ═══════════════════════════════════════════
  // CONFIDENCE CALCULATION
  // ═══════════════════════════════════════════
  double _initialConfidence(
    CrashTriggerType trigger,
    Map<String, dynamic>? extra,
  ) {
    switch (trigger) {
      case CrashTriggerType.highImpact:
        final g = (extra?['gForce'] as double?) ?? 4.0;
        if (g > 8) return 0.7;
        if (g > 6) return 0.55;
        return 0.4;
      case CrashTriggerType.rollover:
        return 0.65;
      case CrashTriggerType.suddenStop:
        return 0.45;
      case CrashTriggerType.freeFall:
        return 0.6;
      case CrashTriggerType.highJerk:
        return 0.35;
      case CrashTriggerType.suddenSpin:
        return 0.4;
      case CrashTriggerType.multiSensor:
        return 0.5;
    }
  }

  double _calculateMergedConfidence(
    CrashEvent existing,
    CrashTriggerType newTrigger,
    AccelerometerData? accelData,
    GyroscopeData? gyroData,
    CrashGpsData? gpsData,
    Map<String, dynamic>? extra,
  ) {
    var confidence = existing.detection.confidence;

    // Multi-sensor bonus
    final hasAccel =
        existing.sensorData.accelerometer.peakG > 0 || accelData != null;
    final hasGyro = existing.sensorData.gyroscope != null || gyroData != null;
    final hasGPS = existing.sensorData.gps.speed > 0 || gpsData != null;

    if (hasAccel && hasGyro) confidence += 0.15;
    if (hasAccel && hasGPS) confidence += 0.15;
    if (hasGyro && hasGPS) confidence += 0.10;

    // Trigger-specific bonuses
    switch (newTrigger) {
      case CrashTriggerType.highImpact:
        final g = accelData?.peakG ?? 0;
        if (g > 8) confidence += 0.2;
        break;
      case CrashTriggerType.rollover:
        confidence += 0.25;
        break;
      case CrashTriggerType.freeFall:
        confidence += 0.2;
        break;
      case CrashTriggerType.suddenStop:
        final decel = (extra?['deceleration'] as double?) ?? 0;
        if (decel > 10) confidence += 0.15;
        break;
      default:
        break;
    }

    // Context bonus
    if (existing.context.activity == ActivityType.driving) confidence += 0.1;
    if (existing.sensorData.gps.speed > 30 / 3.6) confidence += 0.1; // >30 km/h

    return min(1.0, confidence);
  }

  // ═══════════════════════════════════════════
  // CONFIRMATION & SOS FLOW
  // ═══════════════════════════════════════════
  void _confirmCrash(CrashEvent event) {
    event.response.status = CrashResponseStatus.confirming;
    event.response.confirmationWindow = ConfirmationWindow(
      startedAt: DateTime.now(),
    );

    _crashEventController.add(event);
    onConfirmationNeeded?.call(event);

    // Start countdown
    _startConfirmationCountdown(event);
  }

  Timer? _confirmationTimer;

  void _startConfirmationCountdown(CrashEvent event) {
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(
      Duration(seconds: _confirmationWindowSeconds),
      () {
        if (event.response.status == CrashResponseStatus.confirming) {
          _autoTriggerSOS(event);
        }
      },
    );
  }

  void _autoTriggerSOS(CrashEvent event) {
    event.response.status = CrashResponseStatus.autoSos;
    event.response.sosTriggered = SosTriggered(
      triggeredAt: DateTime.now(),
      autoTriggered: true,
    );
    _crashEventController.add(event);
    onAutoSos?.call(event);
  }

  // ═══════════════════════════════════════════
  // USER RESPONSES
  // ═══════════════════════════════════════════
  void userRespondedImOk(CrashEvent event) {
    _confirmationTimer?.cancel();
    event.response.status = CrashResponseStatus.falseAlarm;
    event.response.confirmationWindow = ConfirmationWindow(
      startedAt: event.response.confirmationWindow?.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      userResponded: true,
      responseType: UserResponseType.imOk,
    );
    onFalsePositive?.call();
  }

  void userRespondedNeedHelp(CrashEvent event) {
    _confirmationTimer?.cancel();
    event.response.status = CrashResponseStatus.autoSos;
    event.response.confirmationWindow = ConfirmationWindow(
      startedAt: event.response.confirmationWindow?.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      userResponded: true,
      responseType: UserResponseType.needHelp,
    );
    _autoTriggerSOS(event);
  }

  void cancelPending() {
    _confirmationTimer?.cancel();
    _pendingCrashEvent = null;
  }

  // ═══════════════════════════════════════════
  // FALSE POSITIVE PREVENTION
  // ═══════════════════════════════════════════
  bool quickFalsePositiveCheck(CrashEvent event) {
    // A. Low speed check
    if (event.sensorData.gps.speed < 5 / 3.6 && // < 5 km/h
        event.detection.triggerType != CrashTriggerType.freeFall) {
      return true;
    }

    // B. Phone drop (single sensor, low G)
    if (event.detection.triggerType == CrashTriggerType.highImpact &&
        event.sensorData.accelerometer.peakG < 4 &&
        event.sensorData.gyroscope == null) {
      return true;
    }

    // C. Running / cycling with low G
    if ((event.context.activity == ActivityType.running ||
            event.context.activity == ActivityType.cycling) &&
        event.detection.triggerType == CrashTriggerType.highImpact &&
        event.sensorData.accelerometer.peakG < 6) {
      return true;
    }

    return false;
  }

  // ═══════════════════════════════════════════
  // SIMULATION
  // ═══════════════════════════════════════════
  CrashEvent simulateCrash({
    required CrashTriggerType trigger,
    double confidence = 0.85,
    double peakG = 6.5,
  }) {
    final now = DateTime.now();
    final event = CrashEvent(
      familyId: 'sim',
      memberId: 'sim',
      memberName: 'Test',
      detection: CrashDetection(
        timestamp: now,
        confidence: confidence,
        triggerType: trigger,
      ),
      sensorData: CrashSensorData(
        accelerometer: AccelerometerData(
          x: 0,
          y: 0,
          z: peakG * 9.81,
          magnitude: peakG * 9.81,
          peakG: peakG,
        ),
        gps: const CrashGpsData(
          latitude: 0.0,
          longitude: 0.0,
          speed: 15,
        ),
      ),
      context: const CrashContext(
        activity: ActivityType.driving,
        transportMode: TransportModeCrash.car,
      ),
      response: CrashResponse(),
      createdAt: now,
    );
    _confirmCrash(event);
    return event;
  }

  void dispose() {
    _confirmationTimer?.cancel();
    _crashEventController.close();
  }
}
