class HouseholdTask {
  final String id;
  final String category;
  final String taskName;
  final String? description;
  final int? estimatedDurationMinutes;
  final int difficultyLevel;
  final String? room;
  final String season;
  final List<String> tips;
  final bool isActive;

  HouseholdTask({
    required this.id,
    required this.category,
    required this.taskName,
    this.description,
    this.estimatedDurationMinutes,
    required this.difficultyLevel,
    this.room,
    this.season = 'tum_sezon',
    this.tips = const [],
    this.isActive = true,
  });

  factory HouseholdTask.fromJson(Map<String, dynamic> json) {
    return HouseholdTask(
      id: json['id'] as String,
      category: json['category'] as String,
      taskName: json['task_name'] as String,
      description: json['description'] as String?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      difficultyLevel: json['difficulty_level'] as int? ?? 3,
      room: json['room'] as String?,
      season: json['season'] as String? ?? 'tum_sezon',
      tips: List<String>.from(json['tips'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'task_name': taskName,
      'description': description,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty_level': difficultyLevel,
      'room': room,
      'season': season,
      'tips': tips,
      'is_active': isActive,
    };
  }
}

class TaskSchedule {
  final String id;
  final String taskId;
  final String familyId;
  final String? frequency;
  final int? dayOfWeek;
  final int? weekOfMonth;
  final int? monthOfYear;
  final int priority;
  final String? assignedTo;
  final bool isCompleted;
  final DateTime? completedAt;

  TaskSchedule({
    required this.id,
    required this.taskId,
    required this.familyId,
    this.frequency,
    this.dayOfWeek,
    this.weekOfMonth,
    this.monthOfYear,
    this.priority = 3,
    this.assignedTo,
    this.isCompleted = false,
    this.completedAt,
  });

  factory TaskSchedule.fromJson(Map<String, dynamic> json) {
    return TaskSchedule(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      familyId: json['family_id'] as String,
      frequency: json['frequency'] as String?,
      dayOfWeek: json['day_of_week'] as int?,
      weekOfMonth: json['week_of_month'] as int?,
      monthOfYear: json['month_of_year'] as int?,
      priority: json['priority'] as int? ?? 3,
      assignedTo: json['assigned_to'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'family_id': familyId,
      'frequency': frequency,
      'day_of_week': dayOfWeek,
      'week_of_month': weekOfMonth,
      'month_of_year': monthOfYear,
      'priority': priority,
      'assigned_to': assignedTo,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
