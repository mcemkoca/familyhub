class ChildHomework {
  final String id;
  final String familyId;
  final String childId;
  final String subject;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final HomeworkStatus status;
  final String priority;
  final int? estimatedMinutes;
  final DateTime? completedAt;
  final DateTime createdAt;

  const ChildHomework({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.subject,
    required this.title,
    this.description,
    this.dueDate,
    this.status = HomeworkStatus.pending,
    this.priority = 'medium',
    this.estimatedMinutes,
    this.completedAt,
    required this.createdAt,
  });

  factory ChildHomework.fromJson(Map<String, dynamic> json) {
    return ChildHomework(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      childId: json['child_id']?.toString() ?? '',
      subject: (json['subject'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: _parseStatus(json['status']),
      priority: (json['priority'] as String?) ?? 'medium',
      estimatedMinutes: json['estimated_minutes'] as int?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'child_id': childId,
        'subject': subject,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'status': status.name,
        'priority': priority,
        'estimated_minutes': estimatedMinutes,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  ChildHomework copyWith({
    HomeworkStatus? status,
    DateTime? completedAt,
  }) {
    return ChildHomework(
      id: id,
      familyId: familyId,
      childId: childId,
      subject: subject,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status ?? this.status,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }

  static HomeworkStatus _parseStatus(dynamic value) {
    final str = value?.toString() ?? 'pending';
    return HomeworkStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => HomeworkStatus.pending,
    );
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == HomeworkStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  String get displayStatus {
    switch (status) {
      case HomeworkStatus.pending:
        return 'Bekliyor';
      case HomeworkStatus.inProgress:
        return 'Devam Ediyor';
      case HomeworkStatus.completed:
        return 'Tamamlandı';
      case HomeworkStatus.late:
        return 'Gecikti';
    }
  }
}

enum HomeworkStatus { pending, inProgress, completed, late }
