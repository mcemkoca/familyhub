import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../domain/models/household_task.dart';

class HouseholdTaskRepository {
  Future<List<HouseholdTask>> getAllTasks() async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('household_tasks')
          .select()
          .eq('is_active', true)
          .order('category');
      return (response as List).map((e) => HouseholdTask.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[HouseholdTaskRepository.getAllTasks] error: $e');
      rethrow;
    }
  }

  Future<List<HouseholdTask>> getTasksByCategory(String category) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('household_tasks')
          .select()
          .eq('category', category)
          .eq('is_active', true);
      return (response as List).map((e) => HouseholdTask.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[HouseholdTaskRepository.getTasksByCategory] error: $e');
      rethrow;
    }
  }

  Future<List<TaskSchedule>> getFamilySchedules(String familyId) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return [];
      final response = await client
          .from('task_schedules')
          .select()
          .eq('family_id', familyId)
          .order('priority', ascending: false);
      return (response as List).map((e) => TaskSchedule.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[HouseholdTaskRepository.getFamilySchedules] error: $e');
      rethrow;
    }
  }

  Future<TaskSchedule> createSchedule(TaskSchedule schedule) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) throw Exception('Supabase client not initialized');
      final response = await client
          .from('task_schedules')
          .insert(schedule.toJson())
          .select()
          .single();
      return TaskSchedule.fromJson(response);
    } catch (e, st) {
      debugPrint('[HouseholdTaskRepository.createSchedule] error: $e');
      rethrow;
    }
  }

  Future<void> markCompleted(String scheduleId) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;
      await client.from('task_schedules').update({
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', scheduleId);
    } catch (e, st) {
      debugPrint('[HouseholdTaskRepository.markCompleted] error: $e');
      rethrow;
    }
  }
}
