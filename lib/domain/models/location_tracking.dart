// lib/domain/models/location_tracking.dart
// Battery-aware location tracking domain models

// ─────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────

enum TrackingPriority { battery, balanced, accuracy, custom }

enum TrackingProfileType {
  ultraLowPower,
  stationary,
  lowPower,
  balanced,
  highAccuracy,
  maximumAccuracy,
  emergency,
}

enum LocationProvider { gps, wifi, cellular, fused, cached }

enum TransportMode { stationary, walking, running, cycling, driving, highSpeed, emergency }

// ─────────────────────────────────────────────
// BATTERY THRESHOLDS
// ─────────────────────────────────────────────

class BatteryThresholds {
  final int critical;
  final int low;
  final int medium;
  final int high;
  final int full;

  const BatteryThresholds({
    this.critical = 10,
    this.low = 20,
    this.medium = 50,
    this.high = 80,
    this.full = 100,
  });

  factory BatteryThresholds.fromJson(Map<String, dynamic> json) =>
      BatteryThresholds(
        critical: (json['critical'] as num?)?.toInt() ?? 10,
        low: (json['low'] as num?)?.toInt() ?? 20,
        medium: (json['medium'] as num?)?.toInt() ?? 50,
        high: (json['high'] as num?)?.toInt() ?? 80,
        full: (json['full'] as num?)?.toInt() ?? 100,
      );

  Map<String, dynamic> toJson() => {
        'critical': critical,
        'low': low,
        'medium': medium,
        'high': high,
        'full': full,
      };
}

// ─────────────────────────────────────────────
// MOTION PROFILE CONFIG
// ─────────────────────────────────────────────

class MotionProfileConfig {
  final int updateIntervalSeconds;
  final String accuracy; // low, medium, high, best
  final List<String> providers;
  final bool useGeofence;
  final int? geofenceRadius;
  final bool maxAccuracyMode;

  const MotionProfileConfig({
    required this.updateIntervalSeconds,
    required this.accuracy,
    required this.providers,
    this.useGeofence = false,
    this.geofenceRadius,
    this.maxAccuracyMode = false,
  });

  factory MotionProfileConfig.fromJson(Map<String, dynamic> json) =>
      MotionProfileConfig(
        updateIntervalSeconds:
            (json['updateInterval'] as num?)?.toInt() ?? 60,
        accuracy: json['accuracy'] as String? ?? 'medium',
        providers:
            (json['providers'] as List<dynamic>?)?.cast<String>() ?? ['gps'],
        useGeofence: json['useGeofence'] as bool? ?? false,
        geofenceRadius: (json['geofenceRadius'] as num?)?.toInt(),
        maxAccuracyMode: json['maxAccuracyMode'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'updateInterval': updateIntervalSeconds,
        'accuracy': accuracy,
        'providers': providers,
        'useGeofence': useGeofence,
        'geofenceRadius': geofenceRadius,
        'maxAccuracyMode': maxAccuracyMode,
      };
}

// ─────────────────────────────────────────────
// TRANSITION RULE
// ─────────────────────────────────────────────

class TransitionRule {
  final String from;
  final String to;
  final String trigger; // accelerometer_threshold, speed_threshold, etc.
  final double? threshold;
  final double? speed;
  final int delaySeconds;
  final int? durationSeconds;
  final bool immediate;

  const TransitionRule({
    required this.from,
    required this.to,
    required this.trigger,
    this.threshold,
    this.speed,
    this.delaySeconds = 0,
    this.durationSeconds,
    this.immediate = false,
  });

  factory TransitionRule.fromJson(Map<String, dynamic> json) => TransitionRule(
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        trigger: json['trigger'] as String? ?? '',
        threshold: (json['threshold'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        delaySeconds: (json['delay'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['duration'] as num?)?.toInt(),
        immediate: json['immediate'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'trigger': trigger,
        'threshold': threshold,
        'speed': speed,
        'delay': delaySeconds,
        'duration': durationSeconds,
        'immediate': immediate,
      };
}

// ─────────────────────────────────────────────
// TIME RULE
// ─────────────────────────────────────────────

class TimeRule {
  final String timeRange; // "22:00-06:00"
  final String profile;
  final String reason;

  const TimeRule({
    required this.timeRange,
    required this.profile,
    required this.reason,
  });

  factory TimeRule.fromJson(Map<String, dynamic> json) => TimeRule(
        timeRange: json['timeRange'] as String? ?? '',
        profile: json['profile'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'timeRange': timeRange,
        'profile': profile,
        'reason': reason,
      };
}

// ─────────────────────────────────────────────
// LOCATION RULE
// ─────────────────────────────────────────────

class LocationRule {
  final String place;
  final String profile;
  final int geofenceRadius;

  const LocationRule({
    required this.place,
    required this.profile,
    required this.geofenceRadius,
  });

  factory LocationRule.fromJson(Map<String, dynamic> json) => LocationRule(
        place: json['place'] as String? ?? '',
        profile: json['profile'] as String? ?? '',
        geofenceRadius: (json['geofenceRadius'] as num?)?.toInt() ?? 100,
      );

  Map<String, dynamic> toJson() => {
        'place': place,
        'profile': profile,
        'geofenceRadius': geofenceRadius,
      };
}

// ─────────────────────────────────────────────
// POWER OPTIMIZATION
// ─────────────────────────────────────────────

class PowerOptimization {
  final bool adaptiveBrightness;
  final bool backgroundRefresh;
  final bool networkBatching;
  final bool locationCache;
  final bool motionCoProcessor;

  const PowerOptimization({
    this.adaptiveBrightness = true,
    this.backgroundRefresh = true,
    this.networkBatching = true,
    this.locationCache = true,
    this.motionCoProcessor = true,
  });

  factory PowerOptimization.fromJson(Map<String, dynamic> json) =>
      PowerOptimization(
        adaptiveBrightness: json['adaptiveBrightness'] as bool? ?? true,
        backgroundRefresh: json['backgroundRefresh'] as bool? ?? true,
        networkBatching: json['networkBatching'] as bool? ?? true,
        locationCache: json['locationCache'] as bool? ?? true,
        motionCoProcessor: json['motionCoProcessor'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'adaptiveBrightness': adaptiveBrightness,
        'backgroundRefresh': backgroundRefresh,
        'networkBatching': networkBatching,
        'locationCache': locationCache,
        'motionCoProcessor': motionCoProcessor,
      };
}

// ─────────────────────────────────────────────
// LOCATION TRACKING SETTINGS
// ─────────────────────────────────────────────

class LocationTrackingSettings {
  final String memberId;
  final String familyId;
  final bool enabled;
  final TrackingPriority priority;
  final BatteryThresholds batteryThresholds;
  final Map<String, MotionProfileConfig> motionProfiles;
  final List<TransitionRule> transitionRules;
  final PowerOptimization powerOptimization;
  final List<TimeRule> timeRules;
  final List<LocationRule> locationRules;
  final bool notifyProfileChanges;
  final DateTime updatedAt;

  const LocationTrackingSettings({
    required this.memberId,
    required this.familyId,
    this.enabled = true,
    this.priority = TrackingPriority.balanced,
    this.batteryThresholds = const BatteryThresholds(),
    this.motionProfiles = const {},
    this.transitionRules = const [],
    this.powerOptimization = const PowerOptimization(),
    this.timeRules = const [],
    this.locationRules = const [],
    this.notifyProfileChanges = false,
    required this.updatedAt,
  });

  factory LocationTrackingSettings.fromJson(Map<String, dynamic> json) {
    final profilesRaw = json['motionProfiles'] as Map<String, dynamic>?;
    final profiles = <String, MotionProfileConfig>{};
    if (profilesRaw != null) {
      for (final entry in profilesRaw.entries) {
        profiles[entry.key] = MotionProfileConfig.fromJson(
            entry.value as Map<String, dynamic>);
      }
    }

    return LocationTrackingSettings(
      memberId: json['member_id'] as String? ?? json['memberId'] as String? ?? '',
      familyId: json['family_id'] as String? ?? json['familyId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      priority: TrackingPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TrackingPriority.balanced,
      ),
      batteryThresholds: (json['battery_thresholds'] ?? json['batteryThresholds']) != null
          ? BatteryThresholds.fromJson(
              (json['battery_thresholds'] ?? json['batteryThresholds']) as Map<String, dynamic>)
          : const BatteryThresholds(),
      motionProfiles: profiles,
      transitionRules: ((json['transition_rules'] ?? json['transitionRules']) as List<dynamic>?)
              ?.map((e) => TransitionRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      powerOptimization: (json['power_optimization'] ?? json['powerOptimization']) != null
          ? PowerOptimization.fromJson(
              (json['power_optimization'] ?? json['powerOptimization']) as Map<String, dynamic>)
          : const PowerOptimization(),
      timeRules: ((json['time_rules'] ?? json['timeRules']) as List<dynamic>?)
              ?.map((e) => TimeRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      locationRules: ((json['location_rules'] ?? json['locationRules']) as List<dynamic>?)
              ?.map((e) => LocationRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notifyProfileChanges: (json['notify_profile_changes'] ?? json['notifyProfileChanges']) as bool? ?? false,
      updatedAt: DateTime.tryParse(
              json['updated_at'] as String? ?? json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'familyId': familyId,
        'enabled': enabled,
        'priority': priority.name,
        'batteryThresholds': batteryThresholds.toJson(),
        'motionProfiles': motionProfiles.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'transitionRules': transitionRules.map((r) => r.toJson()).toList(),
        'powerOptimization': powerOptimization.toJson(),
        'timeRules': timeRules.map((r) => r.toJson()).toList(),
        'locationRules': locationRules.map((r) => r.toJson()).toList(),
        'notifyProfileChanges': notifyProfileChanges,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Default motion profiles if none configured
  static Map<String, MotionProfileConfig> get defaultProfiles => {
        'stationary': const MotionProfileConfig(
          updateIntervalSeconds: 300,
          accuracy: 'low',
          providers: ['wifi', 'cellular'],
          useGeofence: true,
          geofenceRadius: 100,
        ),
        'walking': const MotionProfileConfig(
          updateIntervalSeconds: 60,
          accuracy: 'medium',
          providers: ['wifi', 'cellular', 'gps'],
        ),
        'running': const MotionProfileConfig(
          updateIntervalSeconds: 30,
          accuracy: 'medium',
          providers: ['gps', 'cellular'],
        ),
        'cycling': const MotionProfileConfig(
          updateIntervalSeconds: 15,
          accuracy: 'high',
          providers: ['gps'],
        ),
        'driving': const MotionProfileConfig(
          updateIntervalSeconds: 10,
          accuracy: 'high',
          providers: ['gps'],
        ),
        'highSpeed': const MotionProfileConfig(
          updateIntervalSeconds: 5,
          accuracy: 'best',
          providers: ['gps'],
        ),
        'emergency': const MotionProfileConfig(
          updateIntervalSeconds: 3,
          accuracy: 'best',
          providers: ['gps', 'wifi', 'cellular'],
          maxAccuracyMode: true,
        ),
      };
}

// ─────────────────────────────────────────────
// LOCATION POINT
// ─────────────────────────────────────────────

class LocationPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final String provider;
  final String activity;
  final double confidence;

  const LocationPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.provider,
    required this.activity,
    this.confidence = 0.7,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        timestamp: DateTime.tryParse(json['timestamp'] as String) ??
            DateTime.now(),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0,
        heading: (json['heading'] as num?)?.toDouble() ?? 0,
        provider: json['provider'] as String? ?? 'fused',
        activity: json['activity'] as String? ?? 'unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'provider': provider,
        'activity': activity,
        'confidence': confidence,
      };
}

// ─────────────────────────────────────────────
// LOCATION SEGMENT
// ─────────────────────────────────────────────

class LocationSegment {
  final DateTime startTime;
  final DateTime endTime;
  final double distance;
  final Duration duration;
  final double averageSpeed;
  final double maxSpeed;
  final String transportMode;
  final double confidence;

  const LocationSegment({
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.transportMode,
    required this.confidence,
  });

  factory LocationSegment.fromJson(Map<String, dynamic> json) =>
      LocationSegment(
        startTime: DateTime.tryParse(json['startTime'] as String) ??
            DateTime.now(),
        endTime: DateTime.tryParse(json['endTime'] as String) ??
            DateTime.now(),
        distance: (json['distance'] as num?)?.toDouble() ?? 0,
        duration: Duration(seconds: (json['duration'] as num?)?.toInt() ?? 0),
        averageSpeed: (json['averageSpeed'] as num?)?.toDouble() ?? 0,
        maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0,
        transportMode: json['transportMode'] as String? ?? 'unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distance': distance,
        'duration': duration.inSeconds,
        'averageSpeed': averageSpeed,
        'maxSpeed': maxSpeed,
        'transportMode': transportMode,
        'confidence': confidence,
      };
}

// ─────────────────────────────────────────────
// LOCATION BATCH (HISTORY)
// ─────────────────────────────────────────────

class LocationBatch {
  final String? batchId;
  final String memberId;
  final String familyId;
  final DateTime recordedAt;
  final DateTime? uploadedAt;
  final int batchSize;
  final int? batteryAtStart;
  final String powerProfile;
  final List<LocationPoint> locations;
  final LocationSegment? segment;

  const LocationBatch({
    this.batchId,
    required this.memberId,
    required this.familyId,
    required this.recordedAt,
    this.uploadedAt,
    required this.batchSize,
    this.batteryAtStart,
    required this.powerProfile,
    required this.locations,
    this.segment,
  });

  factory LocationBatch.fromJson(Map<String, dynamic> json) => LocationBatch(
        batchId: json['batch_id'] as String? ?? json['batchId'] as String?,
        memberId: json['member_id'] as String? ?? json['memberId'] as String? ?? '',
        familyId: json['family_id'] as String? ?? json['familyId'] as String? ?? '',
        recordedAt: DateTime.tryParse(
                json['recorded_at'] as String? ?? json['recordedAt'] as String? ?? '') ??
            DateTime.now(),
        uploadedAt: (json['uploaded_at'] ?? json['uploadedAt']) != null
            ? DateTime.tryParse((json['uploaded_at'] ?? json['uploadedAt']) as String)
            : null,
        batchSize: ((json['batch_size'] ?? json['batchSize']) as num?)?.toInt() ?? 0,
        batteryAtStart: ((json['battery_at_start'] ?? json['batteryAtStart']) as num?)?.toInt(),
        powerProfile: json['power_profile'] as String? ?? json['powerProfile'] as String? ?? 'balanced',
        locations: (json['locations'] as List<dynamic>?)
                ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        segment: json['segment'] != null
            ? LocationSegment.fromJson(json['segment'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'memberId': memberId,
        'familyId': familyId,
        'recordedAt': recordedAt.toIso8601String(),
        'uploadedAt': uploadedAt?.toIso8601String(),
        'batchSize': batchSize,
        'batteryAtStart': batteryAtStart,
        'powerProfile': powerProfile,
        'locations': locations.map((l) => l.toJson()).toList(),
        'segment': segment?.toJson(),
      };
}

// ─────────────────────────────────────────────
// BATTERY LOG
// ─────────────────────────────────────────────

class BatteryLog {
  final String? logId;
  final String memberId;
  final DateTime timestamp;
  final int batteryLevel;
  final double? temperature;
  final double? voltage;
  final String? health;
  final bool isCharging;
  final String? chargeType;
  final String trackingProfile;
  final int updateInterval;
  final String accuracy;
  final String provider;
  final int locationsRecorded;
  final double? estimatedDrain;

  const BatteryLog({
    this.logId,
    required this.memberId,
    required this.timestamp,
    required this.batteryLevel,
    this.temperature,
    this.voltage,
    this.health,
    required this.isCharging,
    this.chargeType,
    required this.trackingProfile,
    required this.updateInterval,
    required this.accuracy,
    required this.provider,
    required this.locationsRecorded,
    this.estimatedDrain,
  });

  factory BatteryLog.fromJson(Map<String, dynamic> json) => BatteryLog(
        logId: json['logId'] as String?,
        memberId: json['memberId'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String) ??
            DateTime.now(),
        batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 0,
        temperature: (json['temperature'] as num?)?.toDouble(),
        voltage: (json['voltage'] as num?)?.toDouble(),
        health: json['health'] as String?,
        isCharging: json['isCharging'] as bool? ?? false,
        chargeType: json['chargeType'] as String?,
        trackingProfile: json['trackingProfile'] as String? ?? 'balanced',
        updateInterval: (json['updateInterval'] as num?)?.toInt() ?? 60,
        accuracy: json['accuracy'] as String? ?? 'medium',
        provider: json['provider'] as String? ?? 'gps',
        locationsRecorded:
            (json['locationsRecorded'] as num?)?.toInt() ?? 0,
        estimatedDrain: (json['estimatedDrain'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'memberId': memberId,
        'timestamp': timestamp.toIso8601String(),
        'batteryLevel': batteryLevel,
        'temperature': temperature,
        'voltage': voltage,
        'health': health,
        'isCharging': isCharging,
        'chargeType': chargeType,
        'trackingProfile': trackingProfile,
        'updateInterval': updateInterval,
        'accuracy': accuracy,
        'provider': provider,
        'locationsRecorded': locationsRecorded,
        'estimatedDrain': estimatedDrain,
      };
}

// ─────────────────────────────────────────────
// TRACKING ANALYTICS
// ─────────────────────────────────────────────

class TrackingAnalytics {
  final String memberId;
  final DateTime date;
  final int totalLocations;
  final double totalDistance;
  final Duration activeTime;
  final Duration stationaryTime;
  final double batteryUsed;
  final Map<String, int> profileUsageMinutes;
  final double locationsPerBatteryPercent;
  final double accuracyAchieved;
  final double optimalProfilePercentage;
  final List<OptimizationSuggestion> aiRecommendations;

  const TrackingAnalytics({
    required this.memberId,
    required this.date,
    required this.totalLocations,
    required this.totalDistance,
    required this.activeTime,
    required this.stationaryTime,
    required this.batteryUsed,
    required this.profileUsageMinutes,
    required this.locationsPerBatteryPercent,
    required this.accuracyAchieved,
    required this.optimalProfilePercentage,
    this.aiRecommendations = const [],
  });

  factory TrackingAnalytics.fromJson(Map<String, dynamic> json) {
    final profileMap = json['profileUsage'] as Map<String, dynamic>?;
    final usage = <String, int>{};
    if (profileMap != null) {
      for (final e in profileMap.entries) {
        usage[e.key] = (e.value as num).toInt();
      }
    }

    return TrackingAnalytics(
      memberId: json['memberId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String) ?? DateTime.now(),
      totalLocations: (json['totalLocations'] as num?)?.toInt() ?? 0,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0,
      activeTime: Duration(
          minutes: (json['activeTimeMinutes'] as num?)?.toInt() ?? 0),
      stationaryTime: Duration(
          minutes: (json['stationaryTimeMinutes'] as num?)?.toInt() ?? 0),
      batteryUsed: (json['batteryUsed'] as num?)?.toDouble() ?? 0,
      profileUsageMinutes: usage,
      locationsPerBatteryPercent:
          (json['locationsPerBatteryPercent'] as num?)?.toDouble() ?? 0,
      accuracyAchieved:
          (json['accuracyAchieved'] as num?)?.toDouble() ?? 0,
      optimalProfilePercentage:
          (json['optimalProfilePercentage'] as num?)?.toDouble() ?? 0,
      aiRecommendations: (json['aiRecommendations'] as List<dynamic>?)
              ?.map((e) =>
                  OptimizationSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'date': date.toIso8601String(),
        'totalLocations': totalLocations,
        'totalDistance': totalDistance,
        'activeTimeMinutes': activeTime.inMinutes,
        'stationaryTimeMinutes': stationaryTime.inMinutes,
        'batteryUsed': batteryUsed,
        'profileUsage': profileUsageMinutes,
        'locationsPerBatteryPercent': locationsPerBatteryPercent,
        'accuracyAchieved': accuracyAchieved,
        'optimalProfilePercentage': optimalProfilePercentage,
        'aiRecommendations':
            aiRecommendations.map((r) => r.toJson()).toList(),
      };
}

// ─────────────────────────────────────────────
// OPTIMIZATION SUGGESTION
// ─────────────────────────────────────────────

class OptimizationSuggestion {
  final String type;
  final String description;
  final double potentialSaving;
  final double confidence;

  const OptimizationSuggestion({
    required this.type,
    required this.description,
    required this.potentialSaving,
    required this.confidence,
  });

  factory OptimizationSuggestion.fromJson(Map<String, dynamic> json) =>
      OptimizationSuggestion(
        type: json['type'] as String? ?? '',
        description: json['description'] as String? ?? '',
        potentialSaving: (json['potentialSaving'] as num?)?.toDouble() ?? 0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'potentialSaving': potentialSaving,
        'confidence': confidence,
      };
}

// ─────────────────────────────────────────────
// BATTERY PREDICTION
// ─────────────────────────────────────────────

class BatteryPrediction {
  final int currentLevel;
  final double predictedLevel;
  final double predictedDrain;
  final Duration duration;
  final String recommendation;

  const BatteryPrediction({
    required this.currentLevel,
    required this.predictedLevel,
    required this.predictedDrain,
    required this.duration,
    required this.recommendation,
  });
}
