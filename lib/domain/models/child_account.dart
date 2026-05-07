import 'package:flutter/material.dart';

enum ChildRole { child, teen, baby }

class ChildAccount {
  final String id;
  final String familyId;
  final String name;
  final String? avatarUrl;
  final ChildRole role;
  final Color color;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final DateTime? lastActiveAt;
  final int dailyScreenTimeMinutes;
  final bool canApproveTasks;
  final bool canSendMessages;
  final bool canViewBudget;
  final bool remoteLockEnabled;
  final DateTime? remoteLockUntil;
  final String? remoteLockReason;
  final int? age;

  const ChildAccount({
    required this.id,
    required this.familyId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.color,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.lastActiveAt,
    this.dailyScreenTimeMinutes = 120,
    this.canApproveTasks = false,
    this.canSendMessages = true,
    this.canViewBudget = false,
    this.remoteLockEnabled = false,
    this.remoteLockUntil,
    this.remoteLockReason,
    this.age,
  });

  factory ChildAccount.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return Colors.blue;
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return Colors.blue;
      }
    }

    ChildRole parseRole(String? role) {
      switch (role) {
        case 'teen':
          return ChildRole.teen;
        case 'baby':
          return ChildRole.baby;
        case 'child':
        default:
          return ChildRole.child;
      }
    }

    return ChildAccount(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: parseRole(json['role'] as String?),
      color: parseColor(json['color'] as String?),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      dailyScreenTimeMinutes:
          json['daily_screen_time_minutes'] as int? ?? 120,
      canApproveTasks: json['can_approve_tasks'] as bool? ?? false,
      canSendMessages: json['can_send_messages'] as bool? ?? true,
      canViewBudget: json['can_view_budget'] as bool? ?? false,
      remoteLockEnabled: json['remote_lock_enabled'] as bool? ?? false,
      remoteLockUntil: json['remote_lock_until'] != null
          ? DateTime.tryParse(json['remote_lock_until'] as String)
          : null,
      remoteLockReason: json['remote_lock_reason'] as String?,
      age: json['age'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    String colorToHex(Color c) {
      return '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
    }

    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role.name,
      'color': colorToHex(color),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'daily_screen_time_minutes': dailyScreenTimeMinutes,
      'can_approve_tasks': canApproveTasks,
      'can_send_messages': canSendMessages,
      'can_view_budget': canViewBudget,
      'age': age,
    };
  }

  ChildAccount copyWith({
    String? id,
    String? familyId,
    String? name,
    String? avatarUrl,
    ChildRole? role,
    Color? color,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? lastActiveAt,
    int? dailyScreenTimeMinutes,
    bool? canApproveTasks,
    bool? canSendMessages,
    bool? canViewBudget,
    bool? remoteLockEnabled,
    DateTime? remoteLockUntil,
    String? remoteLockReason,
    int? age,
  }) {
    return ChildAccount(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      dailyScreenTimeMinutes:
          dailyScreenTimeMinutes ?? this.dailyScreenTimeMinutes,
      canApproveTasks: canApproveTasks ?? this.canApproveTasks,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      canViewBudget: canViewBudget ?? this.canViewBudget,
      remoteLockEnabled: remoteLockEnabled ?? this.remoteLockEnabled,
      remoteLockUntil: remoteLockUntil ?? this.remoteLockUntil,
      remoteLockReason: remoteLockReason ?? this.remoteLockReason,
      age: age ?? this.age,
    );
  }

  String get displayRole {
    switch (role) {
      case ChildRole.teen:
        return 'Genç';
      case ChildRole.baby:
        return 'Bebek';
      case ChildRole.child:
        return 'Çocuk';
    }
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
