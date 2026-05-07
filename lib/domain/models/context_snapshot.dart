// ── SUB-CONTEXTS ───────────────────────────────────────────────────────

enum DetectedActivity { still, walking, running, driving, cycling }

enum EstimatedMood { positive, neutral, negative }

enum EstimatedAvailability { free, busy, focused }

class LocationContext {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String? placeName;
  final String? placeType;

  const LocationContext({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.placeName,
    this.placeType,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'place_name': placeName,
    'place_type': placeType,
  };

  factory LocationContext.fromJson(Map<String, dynamic> json) =>
      LocationContext(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        placeName: json['place_name'] as String?,
        placeType: json['place_type'] as String?,
      );
}

class TimeContext {
  final int hour;
  final int dayOfWeek;
  final bool isWeekend;
  final bool isHoliday;
  final String? season;

  const TimeContext({
    required this.hour,
    required this.dayOfWeek,
    this.isWeekend = false,
    this.isHoliday = false,
    this.season,
  });

  bool get isQuietHours => hour >= 22 || hour < 8;

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'day_of_week': dayOfWeek,
    'is_weekend': isWeekend,
    'is_holiday': isHoliday,
    'season': season,
  };

  factory TimeContext.fromJson(Map<String, dynamic> json) => TimeContext(
    hour: json['hour'] as int? ?? 0,
    dayOfWeek: json['day_of_week'] as int? ?? 1,
    isWeekend: json['is_weekend'] as bool? ?? false,
    isHoliday: json['is_holiday'] as bool? ?? false,
    season: json['season'] as String?,
  );

  factory TimeContext.now() {
    final now = DateTime.now();
    return TimeContext(
      hour: now.hour,
      dayOfWeek: now.weekday,
      isWeekend: now.weekday >= 6,
      isHoliday: false,
    );
  }
}

class ActivityContext {
  final DetectedActivity detectedActivity;
  final double confidence;

  const ActivityContext({
    this.detectedActivity = DetectedActivity.still,
    this.confidence = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'detected_activity': detectedActivity.name,
    'confidence': confidence,
  };

  factory ActivityContext.fromJson(Map<String, dynamic> json) =>
      ActivityContext(
        detectedActivity: DetectedActivity.values.firstWhere(
          (e) => e.name == json['detected_activity'],
          orElse: () => DetectedActivity.still,
        ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}

class DeviceContext {
  final int batteryLevel;
  final bool isCharging;
  final bool screenOn;
  final bool headphonesConnected;

  const DeviceContext({
    this.batteryLevel = 100,
    this.isCharging = false,
    this.screenOn = true,
    this.headphonesConnected = false,
  });

  Map<String, dynamic> toJson() => {
    'battery_level': batteryLevel,
    'is_charging': isCharging,
    'screen_on': screenOn,
    'headphones_connected': headphonesConnected,
  };

  factory DeviceContext.fromJson(Map<String, dynamic> json) => DeviceContext(
    batteryLevel: json['battery_level'] as int? ?? 100,
    isCharging: json['is_charging'] as bool? ?? false,
    screenOn: json['screen_on'] as bool? ?? true,
    headphonesConnected: json['headphones_connected'] as bool? ?? false,
  );
}

class EnvironmentContext {
  final String? weather;
  final double? temperature;
  final double? lightLevel;
  final double? noiseLevel;

  const EnvironmentContext({
    this.weather,
    this.temperature,
    this.lightLevel,
    this.noiseLevel,
  });

  Map<String, dynamic> toJson() => {
    'weather': weather,
    'temperature': temperature,
    'light_level': lightLevel,
    'noise_level': noiseLevel,
  };

  factory EnvironmentContext.fromJson(Map<String, dynamic> json) =>
      EnvironmentContext(
        weather: json['weather'] as String?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        lightLevel: (json['light_level'] as num?)?.toDouble(),
        noiseLevel: (json['noise_level'] as num?)?.toDouble(),
      );
}

class CognitiveContext {
  final double estimatedEnergy;
  final EstimatedMood estimatedMood;
  final EstimatedAvailability estimatedAvailability;

  const CognitiveContext({
    this.estimatedEnergy = 70,
    this.estimatedMood = EstimatedMood.positive,
    this.estimatedAvailability = EstimatedAvailability.free,
  });

  Map<String, dynamic> toJson() => {
    'estimated_energy': estimatedEnergy,
    'estimated_mood': estimatedMood.name,
    'estimated_availability': estimatedAvailability.name,
  };

  factory CognitiveContext.fromJson(Map<String, dynamic> json) =>
      CognitiveContext(
        estimatedEnergy: (json['estimated_energy'] as num?)?.toDouble() ?? 70,
        estimatedMood: EstimatedMood.values.firstWhere(
          (e) => e.name == json['estimated_mood'],
          orElse: () => EstimatedMood.positive,
        ),
        estimatedAvailability: EstimatedAvailability.values.firstWhere(
          (e) => e.name == json['estimated_availability'],
          orElse: () => EstimatedAvailability.free,
        ),
      );
}

class SocialContext {
  final List<String> nearbyFamilyMembers;
  final DateTime? lastInteraction;

  const SocialContext({
    this.nearbyFamilyMembers = const [],
    this.lastInteraction,
  });

  Map<String, dynamic> toJson() => {
    'nearby_family_members': nearbyFamilyMembers,
    'last_interaction': lastInteraction?.toIso8601String(),
  };

  factory SocialContext.fromJson(Map<String, dynamic> json) => SocialContext(
    nearbyFamilyMembers:
        (json['nearby_family_members'] as List?)?.cast<String>() ?? [],
    lastInteraction: json['last_interaction'] != null
        ? DateTime.tryParse(json['last_interaction'] as String)
        : null,
  );
}

// ── MAIN CONTEXT SNAPSHOT ──────────────────────────────────────────────

class ContextSnapshot {
  final String id;
  final String memberId;
  final String familyId;
  final DateTime timestamp;
  final LocationContext location;
  final TimeContext time;
  final ActivityContext activity;
  final DeviceContext device;
  final EnvironmentContext environment;
  final CognitiveContext cognitive;
  final SocialContext social;

  const ContextSnapshot({
    required this.id,
    required this.memberId,
    required this.familyId,
    required this.timestamp,
    this.location = const LocationContext(latitude: 0, longitude: 0),
    this.time = const TimeContext(hour: 0, dayOfWeek: 1),
    this.activity = const ActivityContext(),
    this.device = const DeviceContext(),
    this.environment = const EnvironmentContext(),
    this.cognitive = const CognitiveContext(),
    this.social = const SocialContext(),
  });

  ContextSnapshot copyWith({
    String? id,
    String? memberId,
    String? familyId,
    DateTime? timestamp,
    LocationContext? location,
    TimeContext? time,
    ActivityContext? activity,
    DeviceContext? device,
    EnvironmentContext? environment,
    CognitiveContext? cognitive,
    SocialContext? social,
  }) => ContextSnapshot(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    familyId: familyId ?? this.familyId,
    timestamp: timestamp ?? this.timestamp,
    location: location ?? this.location,
    time: time ?? this.time,
    activity: activity ?? this.activity,
    device: device ?? this.device,
    environment: environment ?? this.environment,
    cognitive: cognitive ?? this.cognitive,
    social: social ?? this.social,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'member_id': memberId,
    'family_id': familyId,
    'timestamp': timestamp.toIso8601String(),
    'location': location.toJson(),
    'time_context': time.toJson(),
    'activity': activity.toJson(),
    'device': device.toJson(),
    'environment': environment.toJson(),
    'cognitive': cognitive.toJson(),
    'social': social.toJson(),
  };

  factory ContextSnapshot.fromJson(Map<String, dynamic> json) =>
      ContextSnapshot(
        id: json['id'] as String? ?? '',
        memberId: json['member_id'] as String? ?? '',
        familyId: json['family_id'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        location: json['location'] != null
            ? LocationContext.fromJson(json['location'] as Map<String, dynamic>)
            : const LocationContext(latitude: 0, longitude: 0),
        time: json['time_context'] != null
            ? TimeContext.fromJson(json['time_context'] as Map<String, dynamic>)
            : const TimeContext(hour: 0, dayOfWeek: 1),
        activity: json['activity'] != null
            ? ActivityContext.fromJson(json['activity'] as Map<String, dynamic>)
            : const ActivityContext(),
        device: json['device'] != null
            ? DeviceContext.fromJson(json['device'] as Map<String, dynamic>)
            : const DeviceContext(),
        environment: json['environment'] != null
            ? EnvironmentContext.fromJson(
                json['environment'] as Map<String, dynamic>,
              )
            : const EnvironmentContext(),
        cognitive: json['cognitive'] != null
            ? CognitiveContext.fromJson(
                json['cognitive'] as Map<String, dynamic>,
              )
            : const CognitiveContext(),
        social: json['social'] != null
            ? SocialContext.fromJson(json['social'] as Map<String, dynamic>)
            : const SocialContext(),
      );
}
