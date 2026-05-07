import 'package:flutter/material.dart';

class FamilyMemberModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role; // 'admin' | 'member' | 'child'
  final String memberType; // 'adult' | 'child'
  final DateTime? joinedAt;
  final int? age; // Sadece çocuklar için
  final Color? color;
  final bool isOnline;
  final String? relation; // e.g. 'eş', 'anne', 'baba', 'çocuk', 'kardeş', 'dost'
  final String? phone;

  FamilyMemberModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.memberType,
    this.joinedAt,
    this.age,
    this.color,
    this.isOnline = false,
    this.relation,
    this.phone,
  });

  factory FamilyMemberModel.fromAdult(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final displayName = (map['display_name'] as String?) ??
        (profile?['display_name'] as String?) ??
        'İsimsiz';
    return FamilyMemberModel(
      id: map['user_id'] ?? map['id'] ?? '',
      name: displayName,
      avatarUrl: profile?['avatar_url'] as String?,
      role: map['role'] ?? 'member',
      memberType: 'adult',
      joinedAt: map['joined_at'] != null
          ? DateTime.tryParse(map['joined_at'].toString())
          : null,
    );
  }

  factory FamilyMemberModel.fromChild(Map<String, dynamic> map) {
    return FamilyMemberModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'İsimsiz Çocuk',
      avatarUrl: map['avatar_url'] as String?,
      role: 'child',
      memberType: 'child',
      age: map['age'] as int?,
    );
  }

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'parent':
        return 'Ebeveyn';
      case 'member':
        return 'Aile Üyesi';
      case 'child':
        return 'Çocuk';
      default:
        return 'Üye';
    }
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
