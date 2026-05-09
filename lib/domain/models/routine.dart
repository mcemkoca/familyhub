import 'package:flutter/material.dart';

// ── ENUMS ───────────────────────────────────────────────────────────────

enum RoutineType { morning, evening, weekly, custom, seasonal, eventBased }

enum RoutineState { scheduled, active, paused, completed, cancelled }

enum TriggerType { time, location, manual, voice, smartSuggest }

enum StepActionType {
  checklist,
  timer,
  reminder,
  smartHome,
  appOpen,
  locationCheck,
  photoUpload,
  voiceNote,
}

enum CompletionCriteriaType {
  manualCheck,
  autoDetect,
  photoProof,
  locationVerify,
}

enum StepStatus { pending, inProgress, completed, skipped, blocked }

enum ParticipantRole { leader, participant, observer }

enum RecurrencePattern { daily, weekdays, weekends, weekly, custom }

enum CelebrationType { confetti, sound, animation }

enum RoutineDifficulty { easy, medium, hard }

// ── ROUTINE TRIGGER ────────────────────────────────────────────────────

class RoutineTrigger {
  final TriggerType type;
  final TimeOfDay? time;
  final String? geofenceId;
  final String? geofenceAction;
  final String? voiceCommand;
  final List<SmartCondition>? smartConditions;

  const RoutineTrigger({
    this.type = TriggerType.manual,
    this.time,
    this.geofenceId,
    this.geofenceAction,
    this.voiceCommand,
    this.smartConditions,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'time': time != null
            ? {'hour': time!.hour, 'minute': time!.minute}
            : null,
        'geofence_id': geofenceId,
        'geofence_action': geofenceAction,
        'voice_command': voiceCommand,
        'smart_conditions': smartConditions?.map((c) => c.toJson()).toList(),
      };

  factory RoutineTrigger.fromJson(Map<String, dynamic> json) => RoutineTrigger(
        type: TriggerType.values.firstWhere(
          (e) => e.name == (json['type'] as String?),
          orElse: () => TriggerType.manual,
        ),
        time: json['time'] != null
            ? TimeOfDay(
                hour: (json['time'] as Map<String, dynamic>)['hour'] as int? ?? 0,
                minute: (json['time'] as Map<String, dynamic>)['minute'] as int? ?? 0,
              )
            : null,
        geofenceId: json['geofence_id'] as String?,
        geofenceAction: json['geofence_action'] as String?,
        voiceCommand: json['voice_command'] as String?,
        smartConditions: (json['smart_conditions'] as List?)
            ?.map((c) => SmartCondition.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class SmartCondition {
  final String condition;
  final String suggestedRoutine;

  const SmartCondition({
    required this.condition,
    required this.suggestedRoutine,
  });

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'suggested_routine': suggestedRoutine,
      };

  factory SmartCondition.fromJson(Map<String, dynamic> json) => SmartCondition(
        condition: json['condition'] as String? ?? '',
        suggestedRoutine: json['suggested_routine'] as String? ?? '',
      );
}

// ── STEP ACTION ────────────────────────────────────────────────────────

class StepAction {
  final StepActionType type;
  final Map<String, dynamic> config;

  const StepAction({
    this.type = StepActionType.checklist,
    this.config = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'config': config,
      };

  factory StepAction.fromJson(Map<String, dynamic> json) => StepAction(
        type: StepActionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => StepActionType.checklist,
        ),
        config: (json['config'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

// ── COMPLETION CRITERIA ────────────────────────────────────────────────

class CompletionCriteria {
  final CompletionCriteriaType type;
  final List<Map<String, dynamic>>? autoDetectConfig;

  const CompletionCriteria({
    this.type = CompletionCriteriaType.manualCheck,
    this.autoDetectConfig,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'auto_detect_config': autoDetectConfig,
      };

  factory CompletionCriteria.fromJson(Map<String, dynamic> json) =>
      CompletionCriteria(
        type: CompletionCriteriaType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CompletionCriteriaType.manualCheck,
        ),
        autoDetectConfig: (json['auto_detect_config'] as List?)
            ?.map((c) => (c as Map).cast<String, dynamic>())
            .toList(),
      );
}

// ── STEP REWARD ────────────────────────────────────────────────────────

class StepReward {
  final int points;
  final bool streakBonus;
  final CelebrationType celebrationType;

  const StepReward({
    this.points = 10,
    this.streakBonus = false,
    this.celebrationType = CelebrationType.confetti,
  });

  Map<String, dynamic> toJson() => {
        'points': points,
        'streak_bonus': streakBonus,
        'celebration_type': celebrationType.name,
      };

  factory StepReward.fromJson(Map<String, dynamic> json) => StepReward(
        points: json['points'] as int? ?? 10,
        streakBonus: json['streak_bonus'] as bool? ?? false,
        celebrationType: CelebrationType.values.firstWhere(
          (e) => e.name == json['celebration_type'],
          orElse: () => CelebrationType.confetti,
        ),
      );
}

// ── ROUTINE STEP ───────────────────────────────────────────────────────

class RoutineStep {
  final String id;
  final int order;
  final String title;
  final String? description;
  final String? taskId;
  final bool taskAutoAssign;
  final int estimatedDuration; // dakika
  final bool isFlexible;
  final TimeOfDay? timeWindowStart;
  final TimeOfDay? timeWindowEnd;
  final List<String> dependsOn;
  final bool canParallel;
  final List<StepAction> actions;
  final CompletionCriteria completionCriteria;
  final StepReward? reward;
  final StepStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedBy;
  final String? photoUrl;
  final String? voiceNote;

  const RoutineStep({
    required this.id,
    required this.order,
    required this.title,
    this.description,
    this.taskId,
    this.taskAutoAssign = false,
    this.estimatedDuration = 5,
    this.isFlexible = false,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.dependsOn = const [],
    this.canParallel = false,
    this.actions = const [],
    this.completionCriteria = const CompletionCriteria(),
    this.reward,
    this.status = StepStatus.pending,
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.photoUrl,
    this.voiceNote,
  });

  RoutineStep copyWith({
    String? id,
    int? order,
    String? title,
    String? description,
    String? taskId,
    bool? taskAutoAssign,
    int? estimatedDuration,
    bool? isFlexible,
    TimeOfDay? timeWindowStart,
    TimeOfDay? timeWindowEnd,
    List<String>? dependsOn,
    bool? canParallel,
    List<StepAction>? actions,
    CompletionCriteria? completionCriteria,
    StepReward? reward,
    StepStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedBy,
    String? photoUrl,
    String? voiceNote,
  }) =>
      RoutineStep(
        id: id ?? this.id,
        order: order ?? this.order,
        title: title ?? this.title,
        description: description ?? this.description,
        taskId: taskId ?? this.taskId,
        taskAutoAssign: taskAutoAssign ?? this.taskAutoAssign,
        estimatedDuration: estimatedDuration ?? this.estimatedDuration,
        isFlexible: isFlexible ?? this.isFlexible,
        timeWindowStart: timeWindowStart ?? this.timeWindowStart,
        timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
        dependsOn: dependsOn ?? this.dependsOn,
        canParallel: canParallel ?? this.canParallel,
        actions: actions ?? this.actions,
        completionCriteria: completionCriteria ?? this.completionCriteria,
        reward: reward ?? this.reward,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        completedBy: completedBy ?? this.completedBy,
        photoUrl: photoUrl ?? this.photoUrl,
        voiceNote: voiceNote ?? this.voiceNote,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'title': title,
        'description': description,
        'task_id': taskId,
        'task_auto_assign': taskAutoAssign,
        'estimated_duration': estimatedDuration,
        'is_flexible': isFlexible,
        'time_window_start': timeWindowStart != null
            ? {'hour': timeWindowStart!.hour, 'minute': timeWindowStart!.minute}
            : null,
        'time_window_end': timeWindowEnd != null
            ? {'hour': timeWindowEnd!.hour, 'minute': timeWindowEnd!.minute}
            : null,
        'depends_on': dependsOn,
        'can_parallel': canParallel,
        'actions': actions.map((a) => a.toJson()).toList(),
        'completion_criteria': completionCriteria.toJson(),
        'reward': reward?.toJson(),
        'status': status.name,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'completed_by': completedBy,
        'photo_url': photoUrl,
        'voice_note': voiceNote,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        id: json['id'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        taskId: json['task_id'] as String?,
        taskAutoAssign: json['task_auto_assign'] as bool? ?? false,
        estimatedDuration: json['estimated_duration'] as int? ?? 5,
        isFlexible: json['is_flexible'] as bool? ?? false,
        timeWindowStart: json['time_window_start'] != null
            ? TimeOfDay(
                hour: (json['time_window_start'] as Map<String, dynamic>)['hour'] as int? ?? 0,
                minute: (json['time_window_start'] as Map<String, dynamic>)['minute'] as int? ?? 0,
              )
            : null,
        timeWindowEnd: json['time_window_end'] != null
            ? TimeOfDay(
                hour: (json['time_window_end'] as Map<String, dynamic>)['hour'] as int? ?? 0,
                minute: (json['time_window_end'] as Map<String, dynamic>)['minute'] as int? ?? 0,
              )
            : null,
        dependsOn: (json['depends_on'] as List?)?.cast<String>() ?? [],
        canParallel: json['can_parallel'] as bool? ?? false,
        actions: (json['actions'] as List?)
                ?.map((a) => StepAction.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        completionCriteria: json['completion_criteria'] != null
            ? CompletionCriteria.fromJson(
                json['completion_criteria'] as Map<String, dynamic>)
            : const CompletionCriteria(),
        reward: json['reward'] != null
            ? StepReward.fromJson(json['reward'] as Map<String, dynamic>)
            : null,
        status: StepStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => StepStatus.pending,
        ),
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        completedBy: json['completed_by'] as String?,
        photoUrl: json['photo_url'] as String?,
        voiceNote: json['voice_note'] as String?,
      );
}

// ── PARTICIPANT ────────────────────────────────────────────────────────

class RoutineParticipant {
  final String memberId;
  final ParticipantRole role;
  final List<String> assignedSteps;
  final bool isRequired;

  const RoutineParticipant({
    required this.memberId,
    this.role = ParticipantRole.participant,
    this.assignedSteps = const [],
    this.isRequired = true,
  });

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'role': role.name,
        'assigned_steps': assignedSteps,
        'is_required': isRequired,
      };

  factory RoutineParticipant.fromJson(Map<String, dynamic> json) =>
      RoutineParticipant(
        memberId: json['member_id'] as String? ?? '',
        role: ParticipantRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ParticipantRole.participant,
        ),
        assignedSteps: (json['assigned_steps'] as List?)?.cast<String>() ?? [],
        isRequired: json['is_required'] as bool? ?? true,
      );
}

// ── RECURRENCE ─────────────────────────────────────────────────────────

class RoutineRecurrence {
  final bool enabled;
  final RecurrencePattern pattern;
  final List<String> customDays;
  final List<String> exceptions;

  const RoutineRecurrence({
    this.enabled = false,
    this.pattern = RecurrencePattern.daily,
    this.customDays = const [],
    this.exceptions = const [],
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'pattern': pattern.name,
        'custom_days': customDays,
        'exceptions': exceptions,
      };

  factory RoutineRecurrence.fromJson(Map<String, dynamic> json) =>
      RoutineRecurrence(
        enabled: json['enabled'] as bool? ?? false,
        pattern: RecurrencePattern.values.firstWhere(
          (e) => e.name == json['pattern'],
          orElse: () => RecurrencePattern.daily,
        ),
        customDays: (json['custom_days'] as List?)?.cast<String>() ?? [],
        exceptions: (json['exceptions'] as List?)?.cast<String>() ?? [],
      );
}

// ── AI PROFILE ─────────────────────────────────────────────────────────

class RoutineAIProfile {
  final double successRate;
  final double averageCompletionTime;
  final List<PreferredOrder> preferredOrder;
  final Map<String, double> energyPattern;

  const RoutineAIProfile({
    this.successRate = 0,
    this.averageCompletionTime = 0,
    this.preferredOrder = const [],
    this.energyPattern = const {},
  });

  Map<String, dynamic> toJson() => {
        'success_rate': successRate,
        'average_completion_time': averageCompletionTime,
        'preferred_order': preferredOrder.map((o) => o.toJson()).toList(),
        'energy_pattern': energyPattern,
      };

  factory RoutineAIProfile.fromJson(Map<String, dynamic> json) =>
      RoutineAIProfile(
        successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
        averageCompletionTime:
            (json['average_completion_time'] as num?)?.toDouble() ?? 0,
        preferredOrder: (json['preferred_order'] as List?)
                ?.map((o) => PreferredOrder.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
        energyPattern: (json['energy_pattern'] as Map?)
                ?.cast<String, num>()
                .map((k, v) => MapEntry(k, v.toDouble())) ??
            {},
      );
}

class PreferredOrder {
  final String stepId;
  final double confidence;

  const PreferredOrder({required this.stepId, this.confidence = 0.5});

  Map<String, dynamic> toJson() => {
        'step_id': stepId,
        'confidence': confidence,
      };

  factory PreferredOrder.fromJson(Map<String, dynamic> json) => PreferredOrder(
        stepId: json['step_id'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}

// ── MAIN ROUTINE MODEL ─────────────────────────────────────────────────

class Routine {
  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final RoutineType type;
  final RoutineTrigger trigger;
  final List<RoutineStep> steps;
  final RoutineStatus status;
  final RoutineRecurrence recurrence;
  final List<RoutineParticipant> participants;
  final RoutineAIProfile aiProfile;
  final bool isTemplate;
  final String? templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const Routine({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    this.description,
    this.icon = 'sunrise',
    this.color = '#FF9800',
    this.type = RoutineType.morning,
    this.trigger = const RoutineTrigger(),
    this.steps = const [],
    this.status = const RoutineStatus(),
    this.recurrence = const RoutineRecurrence(),
    this.participants = const [],
    this.aiProfile = const RoutineAIProfile(),
    this.isTemplate = false,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  int get estimatedTotalDuration =>
      steps.fold<int>(0, (sum, s) => sum + s.estimatedDuration);

  Routine copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? name,
    String? description,
    String? icon,
    String? color,
    RoutineType? type,
    RoutineTrigger? trigger,
    List<RoutineStep>? steps,
    RoutineStatus? status,
    RoutineRecurrence? recurrence,
    List<RoutineParticipant>? participants,
    RoutineAIProfile? aiProfile,
    bool? isTemplate,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) =>
      Routine(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        createdBy: createdBy ?? this.createdBy,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        type: type ?? this.type,
        trigger: trigger ?? this.trigger,
        steps: steps ?? this.steps,
        status: status ?? this.status,
        recurrence: recurrence ?? this.recurrence,
        participants: participants ?? this.participants,
        aiProfile: aiProfile ?? this.aiProfile,
        isTemplate: isTemplate ?? this.isTemplate,
        templateId: templateId ?? this.templateId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'created_by': createdBy,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'type': type.name,
        'trigger': trigger.toJson(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'status': status.toJson(),
        'recurrence': recurrence.toJson(),
        'participants': participants.map((p) => p.toJson()).toList(),
        'ai_profile': aiProfile.toJson(),
        'is_template': isTemplate,
        'template_id': templateId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'version': version,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String? ?? '',
        familyId: json['family_id'] as String? ?? '',
        createdBy: json['created_by'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        icon: json['icon'] as String? ?? 'sunrise',
        color: json['color'] as String? ?? '#FF9800',
        type: RoutineType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RoutineType.morning,
        ),
        trigger: json['trigger'] != null
            ? RoutineTrigger.fromJson(json['trigger'] as Map<String, dynamic>)
            : const RoutineTrigger(),
        steps: (json['steps'] as List?)
                ?.map((s) => RoutineStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        status: json['status'] != null
            ? RoutineStatus.fromJson(json['status'] as Map<String, dynamic>)
            : const RoutineStatus(),
        recurrence: json['recurrence'] != null
            ? RoutineRecurrence.fromJson(
                json['recurrence'] as Map<String, dynamic>)
            : const RoutineRecurrence(),
        participants: (json['participants'] as List?)
                ?.map((p) =>
                    RoutineParticipant.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        aiProfile: json['ai_profile'] != null
            ? RoutineAIProfile.fromJson(
                json['ai_profile'] as Map<String, dynamic>)
            : const RoutineAIProfile(),
        isTemplate: json['is_template'] as bool? ?? false,
        templateId: json['template_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        version: json['version'] as int? ?? 1,
      );
}

// ── ROUTINE STATUS ─────────────────────────────────────────────────────

class RoutineStatus {
  final RoutineState state;
  final double progress;
  final int currentStep;
  final DateTime? startedAt;
  final DateTime? estimatedEnd;
  final DateTime? actualEnd;

  const RoutineStatus({
    this.state = RoutineState.scheduled,
    this.progress = 0,
    this.currentStep = 0,
    this.startedAt,
    this.estimatedEnd,
    this.actualEnd,
  });

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'progress': progress,
        'current_step': currentStep,
        'started_at': startedAt?.toIso8601String(),
        'estimated_end': estimatedEnd?.toIso8601String(),
        'actual_end': actualEnd?.toIso8601String(),
      };

  RoutineStatus copyWith({
    RoutineState? state,
    double? progress,
    int? currentStep,
    DateTime? startedAt,
    DateTime? estimatedEnd,
    DateTime? actualEnd,
  }) =>
      RoutineStatus(
        state: state ?? this.state,
        progress: progress ?? this.progress,
        currentStep: currentStep ?? this.currentStep,
        startedAt: startedAt ?? this.startedAt,
        estimatedEnd: estimatedEnd ?? this.estimatedEnd,
        actualEnd: actualEnd ?? this.actualEnd,
      );

  factory RoutineStatus.fromJson(Map<String, dynamic> json) => RoutineStatus(
        state: RoutineState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => RoutineState.scheduled,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        currentStep: json['current_step'] as int? ?? 0,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        estimatedEnd: json['estimated_end'] != null
            ? DateTime.tryParse(json['estimated_end'] as String)
            : null,
        actualEnd: json['actual_end'] != null
            ? DateTime.tryParse(json['actual_end'] as String)
            : null,
      );
}
