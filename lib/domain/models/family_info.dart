import 'package:flutter/material.dart';

class FamilyInfo {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final DateTime? foundedDate;
  final String? createdBy;
  final int memberCount;
  final DateTime createdAt;

  FamilyInfo({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.foundedDate,
    this.createdBy,
    this.memberCount = 0,
    required this.createdAt,
  });

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      foundedDate: json['founded_date'] != null
          ? DateTime.tryParse(json['founded_date'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      memberCount: (json['member_count'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'photo_url': photoUrl,
        'founded_date': foundedDate?.toIso8601String(),
        'created_by': createdBy,
        'member_count': memberCount,
        'created_at': createdAt.toIso8601String(),
      };
}

class FamilyHistory {
  final String id;
  final String familyId;
  final String title;
  final String? content;
  final DateTime? eventDate;
  final String type;
  final String? createdBy;
  final DateTime createdAt;

  FamilyHistory({
    required this.id,
    required this.familyId,
    required this.title,
    this.content,
    this.eventDate,
    this.type = 'memory',
    this.createdBy,
    required this.createdAt,
  });

  factory FamilyHistory.fromJson(Map<String, dynamic> json) {
    return FamilyHistory(
      id: (json['id'] as String?) ?? '',
      familyId: (json['family_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: json['content'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
      type: (json['type'] as String?) ?? 'memory',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'title': title,
        'content': content,
        'event_date': eventDate?.toIso8601String(),
        'type': type,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  Color get typeColor {
    switch (type.toLowerCase()) {
      case 'birthday':
      case 'dogum_gunu':
        return const Color(0xFFf59e0b);
      case 'anniversary':
      case 'yildonumu':
        return const Color(0xFFef4444);
      case 'trip':
      case 'seyahat':
        return const Color(0xFF3b82f6);
      case 'achievement':
      case 'basari':
        return const Color(0xFF10b981);
      case 'memory':
      case 'ani':
      default:
        return const Color(0xFF8b5cf6);
    }
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'birthday':
      case 'dogum_gunu':
        return 'Doğum Günü';
      case 'anniversary':
      case 'yildonumu':
        return 'Yıldönümü';
      case 'trip':
      case 'seyahat':
        return 'Seyahat';
      case 'achievement':
      case 'basari':
        return 'Başarı';
      case 'memory':
      case 'ani':
      default:
        return 'Anı';
    }
  }
}
