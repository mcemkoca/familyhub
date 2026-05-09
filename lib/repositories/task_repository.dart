import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/gamification_service.dart';

class TaskRepository with RepositoryErrorHandler {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  String get _table => 'tasks';

  Future<List<Task>> getTasks(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('due_date', ascending: true);
      return (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    }, 'getTasks');
  }

  Future<Task> createTask(Task task, String familyId) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final response = await _client
          .from(_table)
          .insert({
            'family_id': familyId,
            'title': task.title,
            'description': task.description,
            'assigned_to': task.assignedTo,
            'created_by': userId,
            'due_date': task.dueDate?.toIso8601String(),
            'priority': task.priority,
            'status': task.status.name,
            'completed_at': task.completedAt?.toIso8601String(),
          })
          .select()
          .single();

      return _fromJson(response);
    }, 'createTask');
  }

  Future<void> updateTask(Task task) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({
            'title': task.title,
            'description': task.description,
            'assigned_to': task.assignedTo,
            'due_date': task.dueDate?.toIso8601String(),
            'priority': task.priority,
            'status': task.status.name,
            'completed_at': task.completedAt?.toIso8601String(),
          })
          .eq('id', task.id);
    }, 'updateTask');
  }

  Future<void> deleteTask(String id) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).delete().eq('id', id);
    }, 'deleteTask');
  }

  Future<void> completeTask(String id) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      await GamificationService.addXp(10);
    }, 'completeTask');
  }

  Stream<List<Task>> watchTasks(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => _fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('TaskRepository.watchTasks error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchTasks]: $e'));
    }
  }

  Task _fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      assignedTo: json['assigned_to']?.toString() ?? '',
      status: _parseStatus(json['status']),
      priority: (json['priority'] as String?) ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      tags: List<String>.from((json['tags'] as List<dynamic>?) ?? []),
      streakCount: (json['streak_count'] as int?) ?? 0,
    );
  }

  TaskStatus _parseStatus(dynamic value) {
    final str = value?.toString() ?? 'pending';
    return TaskStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => TaskStatus.pending,
    );
  }
}
