import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/entities.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ChildTaskRepository {
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
      final tasks = (response as List).map((e) => _fromJson(e)).toList();
      await HiveService.saveTasks(tasks);
      return tasks;
    } catch (_) {
      // Offline fallback
      return HiveService.getTasks().where((t) => t.assignedTo == _childId).toList();
    }
  }

  Future<Task> getTaskById(String id) async {
    try {
      _checkSession();
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('id', id)
          .eq('assigned_to', _childId!)
          .single();
      return _fromJson(response);
    } catch (e, st) {
      debugPrint('ChildTaskRepository.getTaskById error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      _checkSession();
      await _client.from('tasks').update({
        'status': TaskStatus.completed.name,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId).eq('assigned_to', _childId!);

      await ChildAuthService.logActivity(
        'task_completed',
        details: {'task_id': taskId},
      );

      // Bildirim gönder
      await NotificationService.showInstantNotification(
        title: '🎉 Görev tamamlandı!',
        body: 'Bir görevi başarıyla tamamladın.',
      );
    } catch (e, st) {
      debugPrint('ChildTaskRepository.completeTask error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      _checkSession();
      await _client.from('tasks').update({
        'status': status.name,
        'completed_at': status == TaskStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
      }).eq('id', taskId).eq('assigned_to', _childId!);
    } catch (e, st) {
      debugPrint('ChildTaskRepository.updateTaskStatus error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
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
          .map((data) => data
              .where((e) => e['family_id'] == familyId && e['assigned_to'] == childId)
              .map((e) => _fromJson(e))
              .toList());
    } catch (e, st) {
      debugPrint('ChildTaskRepository.watchMyTasks error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  Task _fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      assignedTo: json['assigned_to']?.toString() ?? '',
      status: _parseStatus(json['status']),
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      streakCount: json['streak_count'] ?? 0,
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
