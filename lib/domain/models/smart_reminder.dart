import 'package:flutter/material.dart';

// ── ENUMS ───────────────────────────────────────────────────────────────

enum ReminderState { active, triggered, snoozed, completed, expired }

enum TriggerType { location, time, behavior }

enum LocationTriggerType { enter, exit, nearby, leaveHome, arriveWork }

enum TimeTriggerType { absolute, relative, recurring, smartSuggest }

enum BehaviorTriggerType {
  appOpen,
  taskComplete,
  locationPattern,
  inactivity,
  energyLevel,
  socialContext,
  weatherChange,
  purchaseIntent,
}

enum CompositeLogic { and_, or_ }

enum ReminderTone { formal, friendly, urgent, gentle }

enum TargetAudienceType { individual, group, smartSelect }

enum DeliveryChannel { push, inApp, sms, voice, smartWatch }

// ── TRIGGER CONFIGS ────────────────────────────────────────────────────

class GeofenceConfig {
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String name;

  const GeofenceConfig({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'name': name,
      };

  factory GeofenceConfig.fromJson(Map<String, dynamic> json) => GeofenceConfig(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 200,
        name: json['name'] as String? ?? '',
      );
}

class LocationTrigger {
  final bool enabled;
  final LocationTriggerType type;
  final GeofenceConfig? geofence;
  final double proximityMeters;

  const LocationTrigger({
    this.enabled = false,
    this.type = LocationTriggerType.nearby,
    this.geofence,
    this.proximityMeters = 500,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'type': type.name,
        'geofence': geofence?.toJson(),
        'proximity_meters': proximityMeters,
      };

  factory LocationTrigger.fromJson(Map<String, dynamic> json) => LocationTrigger(
        enabled: json['enabled'] as bool? ?? false,
        type: LocationTriggerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LocationTriggerType.nearby,
        ),
        geofence: json['geofence'] != null
            ? GeofenceConfig.fromJson(json['geofence'] as Map<String, dynamic>)
            : null,
        proximityMeters: (json['proximity_meters'] as num?)?.toDouble() ?? 500,
      );
}

class SmartWindow {
  final TimeOfDay start;
  final TimeOfDay end;
  final List<String> preferredDays;

  const SmartWindow({
    required this.start,
    required this.end,
    this.preferredDays = const [],
  });

  Map<String, dynamic> toJson() => {
        'start_hour': start.hour,
        'start_minute': start.minute,
        'end_hour': end.hour,
        'end_minute': end.minute,
        'preferred_days': preferredDays,
      };

  factory SmartWindow.fromJson(Map<String, dynamic> json) => SmartWindow(
        start: TimeOfDay(
          hour: json['start_hour'] as int? ?? 9,
          minute: json['start_minute'] as int? ?? 0,
        ),
        end: TimeOfDay(
          hour: json['end_hour'] as int? ?? 18,
          minute: json['end_minute'] as int? ?? 0,
        ),
        preferredDays: (json['preferred_days'] as List?)?.cast<String>() ?? [],
      );
}

class TimeTrigger {
  final bool enabled;
  final TimeTriggerType type;
  final DateTime? absoluteTime;
  final int relativeMinutes;
  final String? cronExpression;
  final SmartWindow? smartWindow;

  const TimeTrigger({
    this.enabled = false,
    this.type = TimeTriggerType.absolute,
    this.absoluteTime,
    this.relativeMinutes = 0,
    this.cronExpression,
    this.smartWindow,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'type': type.name,
        'absolute_time': absoluteTime?.toIso8601String(),
        'relative_minutes': relativeMinutes,
        'cron_expression': cronExpression,
        'smart_window': smartWindow?.toJson(),
      };

  factory TimeTrigger.fromJson(Map<String, dynamic> json) => TimeTrigger(
        enabled: json['enabled'] as bool? ?? false,
        type: TimeTriggerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TimeTriggerType.absolute,
        ),
        absoluteTime: json['absolute_time'] != null
            ? DateTime.tryParse(json['absolute_time'] as String)
            : null,
        relativeMinutes: json['relative_minutes'] as int? ?? 0,
        cronExpression: json['cron_expression'] as String?,
        smartWindow: json['smart_window'] != null
            ? SmartWindow.fromJson(json['smart_window'] as Map<String, dynamic>)
            : null,
      );
}

class BehaviorCondition {
  final String field;
  final String operator;
  final dynamic value;

  const BehaviorCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
      };

  factory BehaviorCondition.fromJson(Map<String, dynamic> json) =>
      BehaviorCondition(
        field: json['field'] as String? ?? '',
        operator: json['operator'] as String? ?? 'eq',
        value: json['value'],
      );
}

class BehaviorTrigger {
  final bool enabled;
  final BehaviorTriggerType type;
  final List<BehaviorCondition> conditions;

  const BehaviorTrigger({
    this.enabled = false,
    this.type = BehaviorTriggerType.inactivity,
    this.conditions = const [],
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'type': type.name,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory BehaviorTrigger.fromJson(Map<String, dynamic> json) => BehaviorTrigger(
        enabled: json['enabled'] as bool? ?? false,
        type: BehaviorTriggerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BehaviorTriggerType.inactivity,
        ),
        conditions: (json['conditions'] as List?)
                ?.map((c) => BehaviorCondition.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class CompositeTrigger {
  final bool enabled;
  final CompositeLogic logic;
  final List<TriggerType> triggers;

  const CompositeTrigger({
    this.enabled = false,
    this.logic = CompositeLogic.and_,
    this.triggers = const [],
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'logic': logic.name,
        'triggers': triggers.map((t) => t.name).toList(),
      };

  factory CompositeTrigger.fromJson(Map<String, dynamic> json) =>
      CompositeTrigger(
        enabled: json['enabled'] as bool? ?? false,
        logic: CompositeLogic.values.firstWhere(
          (e) => e.name == json['logic'],
          orElse: () => CompositeLogic.and_,
        ),
        triggers: (json['triggers'] as List?)
                ?.map((t) => TriggerType.values.firstWhere(
                      (e) => e.name == t,
                      orElse: () => TriggerType.time,
                    ))
                .toList() ??
            [],
      );
}

class TriggerConfig {
  final LocationTrigger location;
  final TimeTrigger time;
  final BehaviorTrigger behavior;
  final CompositeTrigger composite;

  const TriggerConfig({
    this.location = const LocationTrigger(),
    this.time = const TimeTrigger(),
    this.behavior = const BehaviorTrigger(),
    this.composite = const CompositeTrigger(),
  });

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'time': time.toJson(),
        'behavior': behavior.toJson(),
        'composite': composite.toJson(),
      };

  factory TriggerConfig.fromJson(Map<String, dynamic> json) => TriggerConfig(
        location: json['location'] != null
            ? LocationTrigger.fromJson(json['location'] as Map<String, dynamic>)
            : const LocationTrigger(),
        time: json['time'] != null
            ? TimeTrigger.fromJson(json['time'] as Map<String, dynamic>)
            : const TimeTrigger(),
        behavior: json['behavior'] != null
            ? BehaviorTrigger.fromJson(json['behavior'] as Map<String, dynamic>)
            : const BehaviorTrigger(),
        composite: json['composite'] != null
            ? CompositeTrigger.fromJson(json['composite'] as Map<String, dynamic>)
            : const CompositeTrigger(),
      );
}

// ── CONTEXT SENSITIVITY ────────────────────────────────────────────────

class ContextSensitivity {
  final bool quietHoursRespect;
  final bool doNotDisturbOverride;
  final double interruptibilityThreshold;

  const ContextSensitivity({
    this.quietHoursRespect = true,
    this.doNotDisturbOverride = false,
    this.interruptibilityThreshold = 80,
  });

  Map<String, dynamic> toJson() => {
        'quiet_hours_respect': quietHoursRespect,
        'do_not_disturb_override': doNotDisturbOverride,
        'interruptibility_threshold': interruptibilityThreshold,
      };

  factory ContextSensitivity.fromJson(Map<String, dynamic> json) =>
      ContextSensitivity(
        quietHoursRespect: json['quiet_hours_respect'] as bool? ?? true,
        doNotDisturbOverride: json['do_not_disturb_override'] as bool? ?? false,
        interruptibilityThreshold:
            (json['interruptibility_threshold'] as num?)?.toDouble() ?? 80,
      );
}

// ── PERSONALIZATION ────────────────────────────────────────────────────

class Personalization {
  final ReminderTone tone;
  final bool includeContext;
  final String suggestedAction;

  const Personalization({
    this.tone = ReminderTone.friendly,
    this.includeContext = true,
    this.suggestedAction = 'Şimdi başla',
  });

  Map<String, dynamic> toJson() => {
        'tone': tone.name,
        'include_context': includeContext,
        'suggested_action': suggestedAction,
      };

  factory Personalization.fromJson(Map<String, dynamic> json) =>
      Personalization(
        tone: ReminderTone.values.firstWhere(
          (e) => e.name == json['tone'],
          orElse: () => ReminderTone.friendly,
        ),
        includeContext: json['include_context'] as bool? ?? true,
        suggestedAction: json['suggested_action'] as String? ?? 'Şimdi başla',
      );
}

// ── TARGET AUDIENCE ────────────────────────────────────────────────────

class SmartCriteria {
  final String? role;
  final String? availability;
  final String? proximity;

  const SmartCriteria({this.role, this.availability, this.proximity});

  Map<String, dynamic> toJson() => {
        'role': role,
        'availability': availability,
        'proximity': proximity,
      };

  factory SmartCriteria.fromJson(Map<String, dynamic> json) => SmartCriteria(
        role: json['role'] as String?,
        availability: json['availability'] as String?,
        proximity: json['proximity'] as String?,
      );
}

class TargetAudience {
  final TargetAudienceType type;
  final List<String> memberIds;
  final List<SmartCriteria> smartCriteria;

  const TargetAudience({
    this.type = TargetAudienceType.smartSelect,
    this.memberIds = const [],
    this.smartCriteria = const [],
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'member_ids': memberIds,
        'smart_criteria': smartCriteria.map((c) => c.toJson()).toList(),
      };

  factory TargetAudience.fromJson(Map<String, dynamic> json) => TargetAudience(
        type: TargetAudienceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TargetAudienceType.smartSelect,
        ),
        memberIds: (json['member_ids'] as List?)?.cast<String>() ?? [],
        smartCriteria: (json['smart_criteria'] as List?)
                ?.map((c) => SmartCriteria.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ── REMINDER STATUS ────────────────────────────────────────────────────

class ReminderStatus {
  final ReminderState state;
  final int triggerCount;
  final DateTime? lastTriggered;
  final DateTime? nextScheduled;
  final double completionRate;

  const ReminderStatus({
    this.state = ReminderState.active,
    this.triggerCount = 0,
    this.lastTriggered,
    this.nextScheduled,
    this.completionRate = 0,
  });

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'trigger_count': triggerCount,
        'last_triggered': lastTriggered?.toIso8601String(),
        'next_scheduled': nextScheduled?.toIso8601String(),
        'completion_rate': completionRate,
      };

  factory ReminderStatus.fromJson(Map<String, dynamic> json) => ReminderStatus(
        state: ReminderState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => ReminderState.active,
        ),
        triggerCount: json['trigger_count'] as int? ?? 0,
        lastTriggered: json['last_triggered'] != null
            ? DateTime.tryParse(json['last_triggered'] as String)
            : null,
        nextScheduled: json['next_scheduled'] != null
            ? DateTime.tryParse(json['next_scheduled'] as String)
            : null,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}

// ── MAIN SMART REMINDER MODEL ──────────────────────────────────────────

class SmartReminder {
  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final String? description;
  final TriggerConfig triggers;
  final ContextSensitivity contextSensitivity;
  final Personalization personalization;
  final TargetAudience targetAudience;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const SmartReminder({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    this.description,
    this.triggers = const TriggerConfig(),
    this.contextSensitivity = const ContextSensitivity(),
    this.personalization = const Personalization(),
    this.targetAudience = const TargetAudience(),
    this.status = const ReminderStatus(),
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  SmartReminder copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? title,
    String? description,
    TriggerConfig? triggers,
    ContextSensitivity? contextSensitivity,
    Personalization? personalization,
    TargetAudience? targetAudience,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) =>
      SmartReminder(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        createdBy: createdBy ?? this.createdBy,
        title: title ?? this.title,
        description: description ?? this.description,
        triggers: triggers ?? this.triggers,
        contextSensitivity: contextSensitivity ?? this.contextSensitivity,
        personalization: personalization ?? this.personalization,
        targetAudience: targetAudience ?? this.targetAudience,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'triggers': triggers.toJson(),
        'context_sensitivity': contextSensitivity.toJson(),
        'personalization': personalization.toJson(),
        'target_audience': targetAudience.toJson(),
        'status': status.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'version': version,
      };

  factory SmartReminder.fromJson(Map<String, dynamic> json) => SmartReminder(
        id: json['id'] as String? ?? '',
        familyId: json['family_id'] as String? ?? '',
        createdBy: json['created_by'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        triggers: json['triggers'] != null
            ? TriggerConfig.fromJson(json['triggers'] as Map<String, dynamic>)
            : const TriggerConfig(),
        contextSensitivity: json['context_sensitivity'] != null
            ? ContextSensitivity.fromJson(
                json['context_sensitivity'] as Map<String, dynamic>)
            : const ContextSensitivity(),
        personalization: json['personalization'] != null
            ? Personalization.fromJson(
                json['personalization'] as Map<String, dynamic>)
            : const Personalization(),
        targetAudience: json['target_audience'] != null
            ? TargetAudience.fromJson(
                json['target_audience'] as Map<String, dynamic>)
            : const TargetAudience(),
        status: json['status'] != null
            ? ReminderStatus.fromJson(json['status'] as Map<String, dynamic>)
            : const ReminderStatus(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        version: json['version'] as int? ?? 1,
      );
}

// ── PERSONALIZED MESSAGE ───────────────────────────────────────────────

class PersonalizedMessage {
  final String title;
  final String body;
  final String plainText;
  final String? suggestedAction;

  const PersonalizedMessage({
    required this.title,
    required this.body,
    required this.plainText,
    this.suggestedAction,
  });
}
