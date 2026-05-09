import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;
import '../domain/models/today_summary.dart';
import '../domain/models/hub_event.dart';
import '../domain/models/hub_task.dart';
import '../domain/models/family_mood.dart';

class HubRepository {
  static final HubRepository _instance = HubRepository._internal();
  factory HubRepository() => _instance;
  HubRepository._internal();
  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;

  String? get _userId => _safeClient?.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw app_errors.AppAuthException('Giriş yapmalısınız');
    }
  }

  // ==================== TODAY SUMMARY ====================

  Future<TodaySummary> getTodaySummary(String familyId) async {
    _checkAuth();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    int eventCount = 0;
    int taskCount = 0;
    int messageCount = 0;
    List<dynamic> members = [];

    try {
      final eventRes = await _safeClient!
          .from('events')
          .select()
          .eq('family_id', familyId)
          .gte('start_time', todayStart)
          .lte('start_time', todayEnd)
          .eq('status', 'active')
          .count(CountOption.exact);
      eventCount = eventRes.count;
    } catch (e) {
      debugPrint('HubRepository: events count error: $e');
    }

    try {
      final taskRes = await _safeClient!
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .eq('status', 'pending')
          .count(CountOption.exact);
      taskCount = taskRes.count;
    } catch (e) {
      debugPrint('HubRepository: tasks count error: $e');
    }

    try {
      final msgRes = await _safeClient!
          .from('messages')
          .select()
          .eq('family_id', familyId)
          .count(CountOption.exact);
      messageCount = msgRes.count;
    } catch (e) {
      debugPrint('HubRepository: messages count error: $e');
    }

    try {
      members =
          await _safeClient!
                  .from('family_members')
                  .select('user_id, last_active_at')
                  .eq('family_id', familyId)
                  .eq('is_active', true)
              as List<dynamic>;
    } catch (e) {
      debugPrint('HubRepository: family_members select error: $e');
    }

    final onlineCount = members.where((m) {
      final lastActive = DateTime.tryParse(m['last_active_at'] ?? '');
      if (lastActive == null) return false;
      return DateTime.now().difference(lastActive).inMinutes < 5;
    }).length;

    return TodaySummary(
      eventCount: eventCount,
      taskCount: taskCount,
      unreadMessages: messageCount,
      onlineMembers: onlineCount,
      totalMembers: members.length,
    );
  }

  // ==================== UPCOMING EVENTS ====================

  Future<List<HubEvent>> getUpcomingEvents(
    String familyId, {
    int limit = 3,
  }) async {
    _checkAuth();
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _safeClient!
          .from('events')
          .select('*')
          .eq('family_id', familyId)
          .gte('start_time', now)
          .eq('status', 'active')
          .order('start_time', ascending: true)
          .limit(limit);

      return (response as List).map((e) => HubEvent.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HubRepository: getUpcomingEvents error: $e');
      return [];
    }
  }

  Stream<List<HubEvent>> watchUpcomingEvents(String familyId) {
    try {
      return _safeClient!
          .from('events')
          .stream(primaryKey: ['id'])
          .order('start_time')
          .limit(20)
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => HubEvent.fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('HubRepository.watchUpcomingEvents error: $e');
      return Stream.error(
        app_errors.AppDatabaseException('Veritabanı hatası: $e'),
      );
    }
  }

  // ==================== MY TASKS ====================

  Future<List<HubTask>> getMyTasks(String familyId) async {
    _checkAuth();
    try {
      final response = await _safeClient!
          .from('tasks')
          .select('*')
          .eq('family_id', familyId)
          .eq('assigned_to', _userId!)
          .eq('status', 'pending')
          .order('due_date', ascending: true)
          .limit(5);

      return (response as List).map((e) => HubTask.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HubRepository: getMyTasks error: $e');
      return [];
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      _checkAuth();
      await _safeClient!
          .from('tasks')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'completed_by': _userId,
          })
          .eq('id', taskId);
    } catch (e) {
      debugPrint('HubRepository.completeTask error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      _checkAuth();
      await _safeClient!
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId);
    } catch (e) {
      debugPrint('HubRepository.updateTaskStatus error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  // ==================== FAMILY MOOD ====================

  Future<void> shareMood({
    required String familyId,
    required String emoji,
    String? note,
    int? energyLevel,
  }) async {
    try {
      _checkAuth();
      await _safeClient!.from('family_moods').insert({
        'family_id': familyId,
        'user_id': _userId,
        'mood_emoji': emoji,
        'mood_note': note,
        'energy_level': energyLevel,
      });
    } catch (e) {
      debugPrint('HubRepository.shareMood error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<List<FamilyMood>> getRecentMoods(
    String familyId, {
    int limit = 5,
  }) async {
    _checkAuth();
    try {
      final response = await _safeClient!
          .from('family_moods')
          .select('*')
          .eq('family_id', familyId)
          .eq('is_shared', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => FamilyMood.fromJson(e)).toList();
    } catch (e) {
      debugPrint('HubRepository: getRecentMoods error: $e');
      return [];
    }
  }

  Stream<List<FamilyMood>> watchFamilyMoods(String familyId) {
    try {
      return _safeClient!
          .from('family_moods')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(20)
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => FamilyMood.fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('HubRepository.watchFamilyMoods error: $e');
      return Stream.error(
        app_errors.AppDatabaseException('Veritabanı hatası: $e'),
      );
    }
  }

  // ==================== REALTIME SUBSCRIPTION ====================

  RealtimeChannel subscribeToHub(
    String familyId, {
    required Function onEventChange,
    required Function onTaskChange,
    required Function onMoodChange,
  }) {
    try {
      return _safeClient!
          .channel('hub:$familyId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'family_id',
              value: familyId,
            ),
            callback: (payload) => onEventChange(payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'family_id',
              value: familyId,
            ),
            callback: (payload) => onTaskChange(payload),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'family_moods',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'family_id',
              value: familyId,
            ),
            callback: (payload) => onMoodChange(payload),
          )
          .subscribe();
    } catch (e) {
      debugPrint('HubRepository.subscribeToHub error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  // ==================== AI SUGGESTIONS ====================

  Future<List<Map<String, dynamic>>> getPersonalizedSuggestions(
    String familyId, {
    int limit = 5,
  }) async {
    _checkAuth();
    try {
      // Get family context for personalization
      final members = await _safeClient!
          .from('family_members')
          .select('role')
          .eq('family_id', familyId)
          .eq('is_active', true);

      final hasChildren = members.any(
        (m) =>
            m['role'] == 'child' || m['role'] == 'teen' || m['role'] == 'baby',
      );

      final suggestions = <Map<String, dynamic>>[];

      // Family activity suggestions
      if (hasChildren) {
        suggestions.addAll([
          {
            'title': 'Aile Oyun Gecesi',
            'description': 'Bu akşam birlikte bir oyun oynayın',
            'category': 'activity',
            'priority': 'high',
          },
          {
            'title': 'Çocuklarla Yemek Hazırlama',
            'description': 'Çocukları mutfağa davet edin',
            'category': 'cooking',
            'priority': 'medium',
          },
        ]);
      }

      // General suggestions
      suggestions.addAll([
        {
          'title': 'Haftalık Toplantı',
          'description': 'Aile toplantısı planlayın',
          'category': 'meeting',
          'priority': 'high',
        },
        {
          'title': 'Fotoğraf Albümü',
          'description': 'Aile fotoğraflarını düzenleyin',
          'category': 'memory',
          'priority': 'low',
        },
      ]);

      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('HubRepository: getPersonalizedSuggestions error: $e');
      return [];
    }
  }

  Future<void> cacheSuggestions(
    String familyId,
    List<Map<String, dynamic>> suggestions, {
    required String provider,
  }) async {
    try {
      await _safeClient!.from('ai_suggestions_cache').upsert({
        'family_id': familyId,
        'suggestions': suggestions,
        'provider': provider,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Cache failure is non-critical
    }
  }
}
