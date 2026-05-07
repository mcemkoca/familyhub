class RoutineHistory {
  final String id;
  final String routineId;
  final String familyId;
  final DateTime date;
  final ExecutionInfo execution;
  final List<HistoryStep> steps;
  final RoutineFeedback? feedback;
  final ExecutionContext? context;

  const RoutineHistory({
    required this.id,
    required this.routineId,
    required this.familyId,
    required this.date,
    this.execution = const ExecutionInfo(),
    this.steps = const [],
    this.feedback,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'routine_id': routineId,
        'family_id': familyId,
        'date': date.toIso8601String(),
        'execution': execution.toJson(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'feedback': feedback?.toJson(),
        'context': context?.toJson(),
      };

  factory RoutineHistory.fromJson(Map<String, dynamic> json) => RoutineHistory(
        id: json['id'] as String? ?? '',
        routineId: json['routine_id'] as String? ?? '',
        familyId: json['family_id'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        execution: json['execution'] != null
            ? ExecutionInfo.fromJson(json['execution'] as Map<String, dynamic>)
            : const ExecutionInfo(),
        steps: (json['steps'] as List?)
                ?.map((s) => HistoryStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        feedback: json['feedback'] != null
            ? RoutineFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
            : null,
        context: json['context'] != null
            ? ExecutionContext.fromJson(json['context'] as Map<String, dynamic>)
            : null,
      );
}

class ExecutionInfo {
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double totalDuration;
  final bool wasOnTime;

  const ExecutionInfo({
    this.startedAt,
    this.completedAt,
    this.totalDuration = 0,
    this.wasOnTime = true,
  });

  Map<String, dynamic> toJson() => {
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'total_duration': totalDuration,
        'was_on_time': wasOnTime,
      };

  factory ExecutionInfo.fromJson(Map<String, dynamic> json) => ExecutionInfo(
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        totalDuration: (json['total_duration'] as num?)?.toDouble() ?? 0,
        wasOnTime: json['was_on_time'] as bool? ?? true,
      );
}

class HistoryStep {
  final String stepId;
  final String status;
  final double duration;
  final String? completedBy;

  const HistoryStep({
    required this.stepId,
    this.status = 'completed',
    this.duration = 0,
    this.completedBy,
  });

  Map<String, dynamic> toJson() => {
        'step_id': stepId,
        'status': status,
        'duration': duration,
        'completed_by': completedBy,
      };

  factory HistoryStep.fromJson(Map<String, dynamic> json) => HistoryStep(
        stepId: json['step_id'] as String? ?? '',
        status: json['status'] as String? ?? 'completed',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        completedBy: json['completed_by'] as String?,
      );
}

class RoutineFeedback {
  final String? difficulty;
  final double? energyLevel;
  final bool? wouldRepeat;
  final String? notes;

  const RoutineFeedback({
    this.difficulty,
    this.energyLevel,
    this.wouldRepeat,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'energy_level': energyLevel,
        'would_repeat': wouldRepeat,
        'notes': notes,
      };

  factory RoutineFeedback.fromJson(Map<String, dynamic> json) =>
      RoutineFeedback(
        difficulty: json['difficulty'] as String?,
        energyLevel: (json['energy_level'] as num?)?.toDouble(),
        wouldRepeat: json['would_repeat'] as bool?,
        notes: json['notes'] as String?,
      );
}

class ExecutionContext {
  final String? dayOfWeek;
  final String? weather;
  final String? familyMood;
  final int? interruptions;

  const ExecutionContext({
    this.dayOfWeek,
    this.weather,
    this.familyMood,
    this.interruptions,
  });

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'weather': weather,
        'family_mood': familyMood,
        'interruptions': interruptions,
      };

  factory ExecutionContext.fromJson(Map<String, dynamic> json) =>
      ExecutionContext(
        dayOfWeek: json['day_of_week'] as String?,
        weather: json['weather'] as String?,
        familyMood: json['family_mood'] as String?,
        interruptions: json['interruptions'] as int?,
      );
}
