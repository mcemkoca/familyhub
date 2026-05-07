// ── ENUMS ───────────────────────────────────────────────────────────────

enum ReminderAction { dismissed, completed, snoozed, ignored, clicked }

// ── FEEDBACK ────────────────────────────────────────────────────────────

class ReminderFeedback {
  final bool? wasHelpful;
  final bool? wasTimely;
  final bool? wasRelevant;

  const ReminderFeedback({
    this.wasHelpful,
    this.wasTimely,
    this.wasRelevant,
  });

  Map<String, dynamic> toJson() => {
        'was_helpful': wasHelpful,
        'was_timely': wasTimely,
        'was_relevant': wasRelevant,
      };

  factory ReminderFeedback.fromJson(Map<String, dynamic> json) =>
      ReminderFeedback(
        wasHelpful: json['was_helpful'] as bool?,
        wasTimely: json['was_timely'] as bool?,
        wasRelevant: json['was_relevant'] as bool?,
      );
}

// ── INTERACTION CONTEXT ────────────────────────────────────────────────

class InteractionContext {
  final double? latitude;
  final double? longitude;
  final DateTime? time;
  final String? activity;

  const InteractionContext({
    this.latitude,
    this.longitude,
    this.time,
    this.activity,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'time': time?.toIso8601String(),
        'activity': activity,
      };

  factory InteractionContext.fromJson(Map<String, dynamic> json) =>
      InteractionContext(
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        time: json['time'] != null
            ? DateTime.tryParse(json['time'] as String)
            : null,
        activity: json['activity'] as String?,
      );
}

// ── MAIN INTERACTION MODEL ─────────────────────────────────────────────

class ReminderInteraction {
  final String id;
  final String reminderId;
  final String memberId;
  final DateTime timestamp;
  final ReminderAction action;
  final int? snoozeDuration;
  final ReminderFeedback? feedback;
  final InteractionContext? context;

  const ReminderInteraction({
    required this.id,
    required this.reminderId,
    required this.memberId,
    required this.timestamp,
    this.action = ReminderAction.dismissed,
    this.snoozeDuration,
    this.feedback,
    this.context,
  });

  ReminderInteraction copyWith({
    String? id,
    String? reminderId,
    String? memberId,
    DateTime? timestamp,
    ReminderAction? action,
    int? snoozeDuration,
    ReminderFeedback? feedback,
    InteractionContext? context,
  }) =>
      ReminderInteraction(
        id: id ?? this.id,
        reminderId: reminderId ?? this.reminderId,
        memberId: memberId ?? this.memberId,
        timestamp: timestamp ?? this.timestamp,
        action: action ?? this.action,
        snoozeDuration: snoozeDuration ?? this.snoozeDuration,
        feedback: feedback ?? this.feedback,
        context: context ?? this.context,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminder_id': reminderId,
        'member_id': memberId,
        'timestamp': timestamp.toIso8601String(),
        'action': action.name,
        'snooze_duration': snoozeDuration,
        'feedback': feedback?.toJson(),
        'context': context?.toJson(),
      };

  factory ReminderInteraction.fromJson(Map<String, dynamic> json) =>
      ReminderInteraction(
        id: json['id'] as String? ?? '',
        reminderId: json['reminder_id'] as String? ?? '',
        memberId: json['member_id'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        action: ReminderAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => ReminderAction.dismissed,
        ),
        snoozeDuration: json['snooze_duration'] as int?,
        feedback: json['feedback'] != null
            ? ReminderFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
            : null,
        context: json['context'] != null
            ? InteractionContext.fromJson(
                json['context'] as Map<String, dynamic>)
            : null,
      );
}
