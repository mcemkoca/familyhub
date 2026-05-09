import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/household_task.dart';

class HouseholdTaskRepository with RepositoryErrorHandler {
  Future<List<HouseholdTask>> getAllTasks() async {
    return handleRepositoryCall(() async {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('household_tasks')
          .select()
          .eq('is_active', true)
          .order('category');
      return (response as List)
          .map((e) => HouseholdTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getAllTasks');
  }

  Future<List<HouseholdTask>> getTasksByCategory(String category) async {
    return handleRepositoryCall(() async {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('household_tasks')
          .select()
          .eq('category', category)
          .eq('is_active', true);
      return (response as List)
          .map((e) => HouseholdTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getTasksByCategory');
  }

  Future<List<TaskSchedule>> getFamilySchedules(String familyId) async {
    return handleRepositoryCall(() async {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('task_schedules')
          .select()
          .eq('family_id', familyId)
          .order('priority', ascending: false);
      return (response as List)
          .map((e) => TaskSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getFamilySchedules');
  }

  Future<TaskSchedule> createSchedule(TaskSchedule schedule) async {
    return handleRepositoryCall(() async {
      final client = SupabaseConfig.safeClient;
      if (client == null) throw Exception('Supabase client not initialized');
      final response = await client
          .from('task_schedules')
          .insert(schedule.toJson())
          .select()
          .single();
      return TaskSchedule.fromJson(response);
    }, 'createSchedule');
  }

  Future<void> markCompleted(String scheduleId) async {
    return handleRepositoryCall(() async {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;
      await client
          .from('task_schedules')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', scheduleId);
    }, 'markCompleted');
  }
}
