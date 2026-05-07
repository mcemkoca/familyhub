import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/entities.dart';

class ChildStreakRepository {
  static final ChildStreakRepository _instance = ChildStreakRepository._internal();
  factory ChildStreakRepository() => _instance;
  ChildStreakRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  /// Çocuğun streak istatistiklerini hesapla
  Future<StreakStats> getStreakStats(String childId) async {
    try {
      final response = await _client
          .from('tasks')
          .select('*')
          .eq('assigned_to', childId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      final tasks = (response as List).map((e) => _parseTask(e)).toList();

      // Tüm tamamlanma tarihlerini al (sadece gün kısmı)
      final completedDates = tasks
          .where((t) => t.completedAt != null)
          .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
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
    } catch (e, st) {
      debugPrint('ChildStreakRepository.getStreakStats error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
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
                .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
                .toSet()
                .toList();

            completedDates.sort((a, b) => b.compareTo(a));

            return StreakStats(
              currentStreak: _calculateCurrentStreak(completedDates),
              bestStreak: _calculateBestStreak(completedDates),
              totalCompleted: tasks.length,
              weeklyView: _buildWeeklyView(completedDates),
              lastCompleted: completedDates.isNotEmpty ? completedDates.first : null,
            );
          });
    } catch (e, st) {
      debugPrint('ChildStreakRepository.watchStreakStats error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  Task _parseTask(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      assignedTo: json['assigned_to']?.toString() ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (json['status']?.toString() ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      tags: List<String>.from(json['tags'] ?? []),
      streakCount: json['streak_count'] ?? 0,
    );
  }

  int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime expectedDate = todayDate;

    for (final date in dates) {
      if (date == expectedDate || date == expectedDate.subtract(const Duration(days: 1))) {
        streak++;
        expectedDate = date.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate.subtract(const Duration(days: 1)))) {
        break;
      }
    }

    return streak;
  }

  int _calculateBestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    dates.sort((a, b) => a.compareTo(b)); // Eski → Yeni

    int best = 0;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
      } else if (diff > 1) {
        best = current > best ? current : best;
        current = 1;
      }
    }

    return current > best ? current : best;
  }

  Map<int, bool> _buildWeeklyView(List<DateTime> dates) {
    // 1=Mon, 7=Sun
    final now = DateTime.now();
    final result = <int, bool>{};

    // Bu haftanın başlangıcı (Pazartesi)
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      result[day.weekday] = dates.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
    }

    return result;
  }
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
