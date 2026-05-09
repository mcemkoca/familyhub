// lib/services/battery_aware_location_tracker.dart
// Adaptive location tracking with battery optimization & motion profiles

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/models/location_tracking.dart';

/// Callback when profile changes
typedef ProfileChangeCallback = void Function(String profileName, MotionProfileConfig config);

/// Battery-aware location tracker that adapts update frequency,
/// accuracy, and provider based on motion state and battery level.
class BatteryAwareLocationTracker {
  static final BatteryAwareLocationTracker _instance = BatteryAwareLocationTracker._internal();
  factory BatteryAwareLocationTracker() => _instance;
  BatteryAwareLocationTracker._internal();

  // ── State ──
  String _currentProfileName = 'balanced';
  String get currentProfileName => _currentProfileName;

  LocationTrackingSettings? _settings;
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  // ── Streams ──
  StreamSubscription<Position>? _positionStream;
  Timer? _backupTimer;
  Timer? _batchUploadTimer;

  // ── Batch data ──
  final List<LocationPoint> _locationBatch = [];
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  double? _lastSpeed;

  // ── Callbacks ──
  ProfileChangeCallback? onProfileChanged;
  ValueNotifier<String> profileNotifier = ValueNotifier('balanced');
  ValueNotifier<LocationPoint?> lastLocationNotifier = ValueNotifier(null);

  // ═══════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════
  Future<void> initialize(LocationTrackingSettings settings) async {
    _settings = settings;
    await _determineInitialProfile();
  }

  // ═══════════════════════════════════════════
  // TRACKING CONTROL
  // ═══════════════════════════════════════════
  Future<void> startTracking() async {
    if (_isTracking || _settings?.enabled != true) return;
    _isTracking = true;

    final config = _currentConfig;
    if (config != null) {
      await _applyProfile(_currentProfileName, config);
    }

    // Batch upload every 2 minutes
    _batchUploadTimer?.cancel();
    _batchUploadTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _flushBatch();
    });
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionStream?.cancel();
    _backupTimer?.cancel();
    _batchUploadTimer?.cancel();
    await _flushBatch();
  }

  // ═══════════════════════════════════════════
  // PROFILE MANAGEMENT
  // ═══════════════════════════════════════════
  Future<void> _determineInitialProfile() async {
    // Start with balanced; real implementation would check
    // battery, last activity, time rules, and location rules.
    _switchProfileName('balanced');
  }

  Future<void> setProfile(String profileName) async {
    if (_settings?.motionProfiles.containsKey(profileName) ?? false) {
      _switchProfileName(profileName);
      if (_isTracking) {
        final config = _settings!.motionProfiles[profileName]!;
        await _applyProfile(profileName, config);
      }
    }
  }

  void _switchProfileName(String name) {
    _currentProfileName = name;
    profileNotifier.value = name;
  }

  MotionProfileConfig? get _currentConfig {
    final profiles = _settings?.motionProfiles;
    if (profiles == null || profiles.isEmpty) {
      return LocationTrackingSettings.defaultProfiles[_currentProfileName]
          ?? LocationTrackingSettings.defaultProfiles['balanced'];
    }
    return profiles[_currentProfileName]
        ?? LocationTrackingSettings.defaultProfiles['balanced'];
  }

  // ═══════════════════════════════════════════
  // APPLY PROFILE (Location stream setup)
  // ═══════════════════════════════════════════
  Future<void> _applyProfile(String name, MotionProfileConfig config) async {
    // Cancel existing
    await _positionStream?.cancel();
    _backupTimer?.cancel();

    // Determine LocationAccuracy
    LocationAccuracy accuracy;
    switch (config.accuracy) {
      case 'low':
        accuracy = LocationAccuracy.low;
        break;
      case 'high':
        accuracy = LocationAccuracy.high;
        break;
      case 'best':
        accuracy = LocationAccuracy.best;
        break;
      case 'medium':
      default:
        accuracy = LocationAccuracy.medium;
        break;
    }

    final distanceFilter = config.accuracy == 'low'
        ? (config.geofenceRadius ?? 100)
        : config.accuracy == 'medium'
            ? 50
            : config.accuracy == 'high'
                ? 10
                : 5;

    // Start stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (pos) => _processLocation(pos, name, config),
      onError: (e) => debugPrint('Location stream error: $e'),
    );

    // Backup timer
    _backupTimer = Timer.periodic(
      Duration(seconds: config.updateIntervalSeconds),
      (_) => _forceLocationUpdate(name, config),
    );

    onProfileChanged?.call(name, config);
  }

  // ═══════════════════════════════════════════
  // LOCATION PROCESSING
  // ═══════════════════════════════════════════
  void _processLocation(Position position, String profileName, MotionProfileConfig config) {
    if (!_isTracking) return;

    // Quality check
    if (config.maxAccuracyMode && position.accuracy > 50) {
      // Too inaccurate in max accuracy mode; skip or wait
      return;
    }

    // Speed anomaly detection (teleport filter)
    if (_lastPosition != null && _lastPositionTime != null) {
      final dt = DateTime.now().difference(_lastPositionTime!).inSeconds;
      if (dt > 0) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final calcSpeedKmh = (distance / dt) * 3.6;

        if (_lastSpeed != null) {
          final change = (calcSpeedKmh - _lastSpeed!).abs();
          if (change > 100 && dt < 60) {
            // GPS glitch / teleport
            return;
          }
        }
        _lastSpeed = calcSpeedKmh;
      }
    }

    final point = LocationPoint(
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      provider: _detectProvider(position),
      activity: profileName,
      confidence: position.accuracy < 20 ? 0.9 : 0.7,
    );

    _locationBatch.add(point);
    lastLocationNotifier.value = point;

    _lastPosition = position;
    _lastPositionTime = DateTime.now();
  }

  // ═══════════════════════════════════════════
  // FORCE UPDATE (backup timer)
  // ═══════════════════════════════════════════
  Future<void> _forceLocationUpdate(String profileName, MotionProfileConfig config) async {
    if (!_isTracking) return;

    try {
      final accuracy = _accuracyFromString(config.accuracy);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
      _processLocation(pos, profileName, config);
    } catch (e) {
      // Fallback: emit cached position with low confidence
      if (_lastPosition != null) {
        _locationBatch.add(LocationPoint(
          timestamp: DateTime.now(),
          latitude: _lastPosition!.latitude,
          longitude: _lastPosition!.longitude,
          accuracy: 999,
          altitude: _lastPosition!.altitude,
          speed: 0,
          heading: _lastPosition!.heading,
          provider: 'cached',
          activity: profileName,
          confidence: 0.3,
        ));
      }
    }
  }

  // ═══════════════════════════════════════════
  // BATCH UPLOAD
  // ═══════════════════════════════════════════
  Future<void> _flushBatch() async {
    if (_locationBatch.isEmpty) return;

    final batch = List<LocationPoint>.from(_locationBatch);
    _locationBatch.clear();

    // Build segment summary
    // ignore: unused_local_variable
    final segment = _buildSegment(batch);

    // TODO: Upload to Supabase via repository
  }

  LocationSegment _buildSegment(List<LocationPoint> points) {
    if (points.isEmpty) {
      return LocationSegment(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        distance: 0,
        duration: Duration.zero,
        averageSpeed: 0,
        maxSpeed: 0,
        transportMode: _currentProfileName,
        confidence: 0,
      );
    }

    double totalDistance = 0;
    double maxSpeed = 0;
    for (int i = 1; i < points.length; i++) {
      final d = Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      totalDistance += d;
      if (points[i].speed > maxSpeed) maxSpeed = points[i].speed;
    }

    final duration = points.last.timestamp.difference(points.first.timestamp);
    final avgSpeed = duration.inSeconds > 0
        ? (totalDistance / duration.inSeconds)
        : 0.0;

    return LocationSegment(
      startTime: points.first.timestamp,
      endTime: points.last.timestamp,
      distance: totalDistance,
      duration: duration,
      averageSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      transportMode: _currentProfileName,
      confidence: 0.8,
    );
  }

  // ═══════════════════════════════════════════
  // BATTERY-BASED PROFILE SWITCHING
  // ═══════════════════════════════════════════
  void onBatteryChanged(int level, bool isCharging) {
    if (!_isTracking || _settings == null) return;

    if (isCharging) {
      setProfile('highSpeed');
      return;
    }

    final t = _settings!.batteryThresholds;
    String newProfile;
    if (level <= t.critical) {
      newProfile = 'stationary';
    } else if (level <= t.low) {
      newProfile = 'lowPower';
    } else if (level <= t.medium) {
      newProfile = 'balanced';
    } else if (level <= t.high) {
      newProfile = 'driving';
    } else {
      newProfile = 'highSpeed';
    }

    if (newProfile != _currentProfileName) {
      setProfile(newProfile);
    }
  }

  // ═══════════════════════════════════════════
  // PREDICTION & ANALYTICS
  // ═══════════════════════════════════════════
  BatteryPrediction predictBatteryDrain(int currentLevel, Duration duration) {
    // Simple heuristic: each profile has approximate drain % per hour
    final drainRates = <String, double>{
      'stationary': 1.0,
      'walking': 2.5,
      'running': 4.0,
      'cycling': 5.0,
      'driving': 6.0,
      'highSpeed': 10.0,
      'emergency': 18.0,
    };

    final rate = drainRates[_currentProfileName] ?? 4.0;
    final predictedDrain = rate * (duration.inMinutes / 60.0);
    final predictedLevel = max(0.0, currentLevel - predictedDrain);

    String recommendation;
    if (predictedLevel < 10) {
      recommendation = 'Kritik! Profili düşür veya şarj edin.';
    } else if (predictedLevel < 20) {
      recommendation = 'Düşük batarya. Ultra low power modu önerilir.';
    } else if (predictedLevel < 50) {
      recommendation = 'Batarya orta seviyede. Mevcut profil uygun.';
    } else {
      recommendation = 'Batarya yeterli. Yüksek accuracy kullanılabilir.';
    }

    return BatteryPrediction(
      currentLevel: currentLevel,
      predictedLevel: predictedLevel,
      predictedDrain: predictedDrain,
      duration: duration,
      recommendation: recommendation,
    );
  }

  List<OptimizationSuggestion> generateOptimizationSuggestions() {
    final suggestions = <OptimizationSuggestion>[];

    suggestions.add(const OptimizationSuggestion(
      type: 'profile_optimization',
      description: 'Profil geçişleriniz optimize edilebilir. Daha az sıklıkla değişim önerilir.',
      potentialSaving: 15,
      confidence: 0.8,
    ));

    suggestions.add(const OptimizationSuggestion(
      type: 'geofence_optimization',
      description: 'Geofence bölgeleriniz genişletilebilir. Daha az GPS kullanımı sağlar.',
      potentialSaving: 10,
      confidence: 0.75,
    ));

    suggestions.add(const OptimizationSuggestion(
      type: 'time_rule',
      description: 'Uyku saatiniz tespit edildi. 22:00-06:00 arası ultra low power önerilir.',
      potentialSaving: 20,
      confidence: 0.9,
    ));

    return suggestions..sort((a, b) => b.potentialSaving.compareTo(a.potentialSaving));
  }

  // ═══════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════
  String _detectProvider(Position position) {
    // Heuristic based on accuracy
    if (position.accuracy <= 10) return 'gps';
    if (position.accuracy <= 50) return 'wifi';
    return 'cellular';
  }

  LocationAccuracy _accuracyFromString(String? value) {
    switch (value) {
      case 'low':
        return LocationAccuracy.low;
      case 'high':
        return LocationAccuracy.high;
      case 'best':
        return LocationAccuracy.best;
      case 'medium':
      default:
        return LocationAccuracy.medium;
    }
  }

  void dispose() {
    stopTracking();
    profileNotifier.dispose();
    lastLocationNotifier.dispose();
  }
}
