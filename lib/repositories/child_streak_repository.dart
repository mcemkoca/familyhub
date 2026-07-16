import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../core/streak_calculator.dart';
import '../domain/entities.dart';

class ChildStreakRepository with RepositoryErrorHandler {
  static final ChildStreakRepository _instance =
      ChildStreakRepository._internal();
  factory ChildStreakRepository() => _instance;
  ChildStreakRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  /// Çocuğun streak istatistiklerini hesapla
  Future<StreakStats> getStreakStats(String childId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('assigned_to', childId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      final tasks = (response as List).map((e) => _parseTask(e as Map<String, dynamic>)).toList();

      // Tüm tamamlanma tarihlerini al (sadece gün kısmı)
      final completedDates = tasks
          .where((t) => t.completedAt != null)
          .map(
            (t) => DateTime(
              t.completedAt!.year,
              t.completedAt!.month,
              t.completedAt!.day,
            ),
          )
          .toSet()
          .toList();

      completedDates.sort((a, b) => b.compareTo(a)); // En yeni önce

      final currentStreak = _calculateCurrentStreak(completedDates);
      final bestStreak = _calculateBestStreak(completedDates);
      final weeklyView = _buildWeeklyView(completedDates);

      return StreakStats(
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        totalCompleted: tasks.length,
        weeklyView: weeklyView,
        lastCompleted: completedDates.isNotEmpty ? completedDates.first : null,
      );
    }, 'getStreakStats');
  }

  /// Realtime streak stream
  Stream<StreakStats> watchStreakStats(String childId) {
    try {
      return _client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('assigned_to', childId)
          .map((data) {
            final tasks = data
                .where((e) => e['status'] == 'completed')
                .map((e) => _parseTask(e))
                .toList();

            final completedDates = tasks
                .where((t) => t.completedAt != null)
                .map(
                  (t) => DateTime(
                    t.completedAt!.year,
                    t.completedAt!.month,
                    t.completedAt!.day,
                  ),
                )
                .toSet()
                .toList();

            completedDates.sort((a, b) => b.compareTo(a));

            return StreakStats(
              currentStreak: _calculateCurrentStreak(completedDates),
              bestStreak: _calculateBestStreak(completedDates),
              totalCompleted: tasks.length,
              weeklyView: _buildWeeklyView(completedDates),
              lastCompleted: completedDates.isNotEmpty
                  ? completedDates.first
                  : null,
            );
          });
    } catch (e) {
      debugPrint('ChildStreakRepository.watchStreakStats error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchStreakStats]: $e'));
    }
  }

  Task _parseTask(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      assignedTo: json['assigned_to']?.toString() ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (json['status']?.toString() ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
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

  // Streak hesaplama artık paylaşılan saf util'de (core/streak_calculator.dart).
  int _calculateCurrentStreak(List<DateTime> dates) =>
      calculateCurrentStreak(dates);

  int _calculateBestStreak(List<DateTime> dates) => calculateBestStreak(dates);

  Map<int, bool> _buildWeeklyView(List<DateTime> dates) =>
      buildWeeklyView(dates);
}

class StreakStats {
  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final Map<int, bool> weeklyView;
  final DateTime? lastCompleted;

  const StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompleted,
    required this.weeklyView,
    this.lastCompleted,
  });
}
