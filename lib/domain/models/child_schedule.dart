import 'package:flutter/material.dart';

class ChildSchedule {
  final String id;
  final String familyId;
  final String childId;
  final int dayOfWeek; // 1=Mon, 7=Sun
  final String startTime; // "08:30"
  final String endTime;   // "09:15"
  final String subject;
  final String? location;
  final String? teacher;
  final Color color;
  final bool isActive;
  final DateTime createdAt;

  const ChildSchedule({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.location,
    this.teacher,
    required this.color,
    this.isActive = true,
    required this.createdAt,
  });

  factory ChildSchedule.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return Colors.blue;
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return Colors.blue;
      }
    }

    return ChildSchedule(
      id: json['id']?.toString() ?? '',
      familyId: json['family_id']?.toString() ?? '',
      childId: json['child_id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      startTime: json['start_time']?.toString() ?? '08:00',
      endTime: json['end_time']?.toString() ?? '09:00',
      subject: (json['subject'] as String?) ?? '',
      location: json['location'] as String?,
      teacher: json['teacher'] as String?,
      color: parseColor(json['color'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'child_id': childId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'subject': subject,
        'location': location,
        'teacher': teacher,
        'color': '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  String get dayName {
    switch (dayOfWeek) {
      case 1: return 'Pazartesi';
      case 2: return 'Salı';
      case 3: return 'Çarşamba';
      case 4: return 'Perşembe';
      case 5: return 'Cuma';
      case 6: return 'Cumartesi';
      case 7: return 'Pazar';
      default: return '';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 1: return 'Pzt';
      case 2: return 'Sal';
      case 3: return 'Çar';
      case 4: return 'Per';
      case 5: return 'Cum';
      case 6: return 'Cmt';
      case 7: return 'Paz';
      default: return '';
    }
  }
}
