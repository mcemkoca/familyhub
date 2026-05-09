class ChildDevelopmentLog {
  final String id;
  final String familyId;
  final String childId;
  final DevelopmentLogType logType;
  final String value;
  final String? unit;
  final DateTime loggedAt;
  final String? notes;
  final DateTime createdAt;

  const ChildDevelopmentLog({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.logType,
    required this.value,
    this.unit,
    required this.loggedAt,
    this.notes,
    required this.createdAt,
  });

  factory ChildDevelopmentLog.fromJson(Map<String, dynamic> json) {
    return ChildDevelopmentLog(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      childId: json['child_id']?.toString() ?? '',
      logType: _parseType(json['log_type']),
      value: json['value']?.toString() ?? '',
      unit: json['unit'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'child_id': childId,
        'log_type': logType.name,
        'value': value,
        'unit': unit,
        'logged_at': loggedAt.toIso8601String().substring(0, 10),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  static DevelopmentLogType _parseType(dynamic value) {
    final str = value?.toString() ?? 'note';
    return DevelopmentLogType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => DevelopmentLogType.note,
    );
  }

  String get displayType {
    switch (logType) {
      case DevelopmentLogType.height:
        return 'Boy';
      case DevelopmentLogType.weight:
        return 'Kilo';
      case DevelopmentLogType.mood:
        return 'Ruh Hali';
      case DevelopmentLogType.milestone:
        return 'Kazanım';
      case DevelopmentLogType.note:
        return 'Not';
    }
  }

  String get displayValue {
    if (unit != null) return '$value $unit';
    return value;
  }

  double? get numericValue {
    return double.tryParse(value);
  }
}

enum DevelopmentLogType { height, weight, mood, milestone, note }
