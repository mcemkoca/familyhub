import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/child_schedule.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';

class ChildScheduleRepository with RepositoryErrorHandler {
  static final ChildScheduleRepository _instance =
      ChildScheduleRepository._internal();
  factory ChildScheduleRepository() => _instance;
  ChildScheduleRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  Future<List<ChildSchedule>> getMySchedule({int? dayOfWeek}) async {
    _checkSession();
    try {
      var query = _client
          .from('child_schedules')
          .select('*')
          .eq('child_id', _childId!)
          .eq('is_active', true);

      if (dayOfWeek != null) {
        query = query.eq('day_of_week', dayOfWeek);
      }

      final response = await query.order('start_time', ascending: true);
      final list = (response as List)
          .map((e) => ChildSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
      await HiveService.saveChildSchedules(list);
      return list;
    } catch (_) {
      final cached = HiveService.getChildSchedules();
      if (dayOfWeek != null) {
        return cached.where((s) => s.dayOfWeek == dayOfWeek).toList();
      }
      return cached;
    }
  }

  Future<List<ChildSchedule>> getTodaySchedule() async {
    final now = DateTime.now();
    // Monday=1 in DB
    final dayOfWeek = now.weekday;
    return getMySchedule(dayOfWeek: dayOfWeek);
  }

  Future<List<ChildSchedule>> getWeeklySchedule() async {
    return getMySchedule();
  }

  Stream<List<ChildSchedule>> watchMySchedule() {
    try {
      final childId = _childId;
      if (childId == null) return Stream.value([]);
      return _client
          .from('child_schedules')
          .stream(primaryKey: ['id'])
          .map(
            (data) => data
                .where(
                  (e) => e['child_id'] == childId && e['is_active'] == true,
                )
                .map((e) => ChildSchedule.fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('ChildScheduleRepository.watchMySchedule error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchMySchedule]: $e'));
    }
  }

  // ── Parent methods ──
  Future<ChildSchedule> createSchedule({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    String? location,
    String? teacher,
    String color = '#3B82F6',
  }) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('child_schedules')
          .insert({
            'family_id': _familyId!,
            'child_id': _childId!,
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
            'subject': subject,
            'location': location,
            'teacher': teacher,
            'color': color,
            'is_active': true,
          })
          .select()
          .single();
      return ChildSchedule.fromJson(response);
    }, 'createSchedule');
  }

  Future<void> deleteSchedule(String id) async {
    return handleRepositoryCall(() async {
      _checkSession();
      await _client.from('child_schedules').delete().eq('id', id);
    }, 'deleteSchedule');
  }
}
