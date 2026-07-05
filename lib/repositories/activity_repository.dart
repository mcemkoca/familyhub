import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class ActivityRepository with RepositoryErrorHandler {
  static final ActivityRepository _instance = ActivityRepository._internal();
  factory ActivityRepository() => _instance;
  ActivityRepository._internal();

  SupabaseClient? get _client => SupabaseConfig.safeClient;

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await _client
        ?.from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  Future<List<Activity>> getRecentActivities({int limit = 20}) async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      if (familyId == null || _client == null) return [];

      final response = await _client!
          .from('activity_log')
          .select('id, actor_name, actor_color, action, target, created_at')
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getRecentActivities');
  }

  Future<void> logActivity({
    required String action,
    required String target,
    String? actorName,
  }) async {
    return handleRepositoryCall(() async {
      final client = _client;
      final userId = AuthService.currentUserId;
      if (client == null || userId == null) return;

      final familyId = await _getFamilyId();
      if (familyId == null) return;

      final profile = await client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final name = actorName ?? (profile?['display_name'] as String?) ?? 'Bilinmiyor';

      await client.from('activity_log').insert({
        'family_id': familyId,
        'user_id': userId,
        'actor_name': name,
        'actor_color': '#6366F1',
        'action': action,
        'target': target,
        'created_at': DateTime.now().toIso8601String(),
      });
    }, 'logActivity');
  }

  Activity _fromJson(Map<String, dynamic> json) {
    final colorHex = (json['actor_color'] as String?) ?? '#6366F1';
    final color = _hexToColor(colorHex);
    return Activity(
      id: json['id']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      actorColor: color,
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}
