import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/child_homework.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ChildHomeworkRepository with RepositoryErrorHandler {
  static final ChildHomeworkRepository _instance =
      ChildHomeworkRepository._internal();
  factory ChildHomeworkRepository() => _instance;
  ChildHomeworkRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  Future<List<ChildHomework>> getMyHomeworks() async {
    _checkSession();
    try {
      final response = await _client
          .from('child_homeworks')
          .select('*')
          .eq('child_id', _childId!)
          .order('due_date', ascending: true);
      final list = (response as List)
          .map((e) => ChildHomework.fromJson(e as Map<String, dynamic>))
          .toList();
      await HiveService.saveChildHomeworks(list);
      return list;
    } catch (_) {
      return HiveService.getChildHomeworks();
    }
  }

  Future<List<ChildHomework>> getHomeworksByStatus(
    HomeworkStatus status,
  ) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('child_homeworks')
          .select('*')
          .eq('child_id', _childId!)
          .eq('status', status.name)
          .order('due_date', ascending: true);
      return (response as List)
          .map((e) => ChildHomework.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getHomeworksByStatus');
  }

  Future<void> completeHomework(String homeworkId) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client
          .from('child_homeworks')
          .update({
            'status': HomeworkStatus.completed.name,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', homeworkId)
          .eq('child_id', _childId!);
      await NotificationService.showInstantNotification(
        title: '📚 Ödev tamamlandı!',
        body: 'Bir ödevi başarıyla bitirdin.',
      );
    }, 'completeHomework');
  }

  Future<void> updateStatus(String homeworkId, HomeworkStatus status) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client
          .from('child_homeworks')
          .update({
            'status': status.name,
            'completed_at': status == HomeworkStatus.completed
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', homeworkId)
          .eq('child_id', _childId!);
    }, 'updateStatus');
  }

  Stream<List<ChildHomework>> watchMyHomeworks() {
    try {
      final childId = _childId;
      if (childId == null) return Stream.value([]);
      return _client
          .from('child_homeworks')
          .stream(primaryKey: ['id'])
          .eq('child_id', childId)
          .order('due_date')
          .map((data) => data.map((e) => ChildHomework.fromJson(e)).toList());
    } catch (e) {
      debugPrint('ChildHomeworkRepository.watchMyHomeworks error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchMyHomeworks]: $e'));
    }
  }

  // ── Parent methods (require authenticated user) ──
  Future<ChildHomework> createHomework({
    required String subject,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    int? estimatedMinutes,
  }) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('child_homeworks')
          .insert({
            'family_id': _familyId!,
            'child_id': _childId!,
            'subject': subject,
            'title': title,
            'description': description,
            'due_date': dueDate?.toIso8601String(),
            'status': HomeworkStatus.pending.name,
            'priority': priority,
            'estimated_minutes': estimatedMinutes,
          })
          .select()
          .single();
      return ChildHomework.fromJson(response);
    }, 'createHomework');
  }

  Future<void> deleteHomework(String id) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client.from('child_homeworks').delete().eq('id', id);
    }, 'deleteHomework');
  }
}
