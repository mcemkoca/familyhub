import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ChildTaskRepository with RepositoryErrorHandler {
  static final ChildTaskRepository _instance = ChildTaskRepository._internal();
  factory ChildTaskRepository() => _instance;
  ChildTaskRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  Future<List<Task>> getMyTasks() async {
    _checkSession();
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('family_id', _familyId!)
          .eq('assigned_to', _childId!)
          .order('due_date', ascending: true);
      final tasks = (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
      await HiveService.saveTasks(tasks);
      return tasks;
    } catch (_) {
      // Offline fallback
      return HiveService.getTasks()
          .where((t) => t.assignedTo == _childId)
          .toList();
    }
  }

  Future<Task> getTaskById(String id) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('id', id)
          .eq('assigned_to', _childId!)
          .single();
      return _fromJson(response);
    }, 'getTaskById');
  }

  Future<void> completeTask(String taskId) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client
          .from('tasks')
          .update({
            'status': TaskStatus.completed.name,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId)
          .eq('assigned_to', _childId!);

      await ChildAuthService.logActivity(
        'task_completed',
        details: {'task_id': taskId},
      );

      // Bildirim gönder
      await NotificationService.showInstantNotification(
        title: '🎉 Görev tamamlandı!',
        body: 'Bir görevi başarıyla tamamladın.',
      );
    }, 'completeTask');
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client
          .from('tasks')
          .update({
            'status': status.name,
            'completed_at': status == TaskStatus.completed
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', taskId)
          .eq('assigned_to', _childId!);
    }, 'updateTaskStatus');
  }

  Stream<List<Task>> watchMyTasks() {
    try {
      final familyId = _familyId;
      final childId = _childId;
      if (familyId == null || childId == null) {
        return Stream.value([]);
      }
      return _client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .map(
            (data) => data
                .where(
                  (e) =>
                      e['family_id'] == familyId && e['assigned_to'] == childId,
                )
                .map((e) => _fromJson(e))
                .toList(),
          );
    } catch (e) {
      return Stream.error(RepositoryException('Beklenmeyen hata [watchMyTasks]: $e'));
    }
  }

  Task _fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
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
