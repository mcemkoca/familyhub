import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../domain/entities.dart';
import '../domain/models/ai_suggestion.dart';
import '../domain/models/child_homework.dart';
import '../domain/models/child_schedule.dart';
import '../repositories/child_homework_repository.dart';
import '../repositories/child_schedule_repository.dart';
import '../repositories/child_task_repository.dart';
import 'child_auth_service.dart';

/// AI Öneri Motoru
/// Çocuğun aktivite pattern'lerini analiz edip kişiselleştirilmiş öneriler üretir.
class ChildAiService {
  final _client = SupabaseConfig.safeClient!;
  final _taskRepo = ChildTaskRepository();
  final _scheduleRepo = ChildScheduleRepository();
  final _homeworkRepo = ChildHomeworkRepository();

  String? get _childId => ChildAuthService.currentChildId;
  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childName => ChildAuthService.currentSession?.childName;

  /// Çocuğun son aktivitelerine dayalı AI önerileri üret
  Future<List<AiSuggestion>> generateSuggestions() async {
    if (_childId == null || _familyId == null) return [];

    final suggestions = <AiSuggestion>[];

    // Paralel veri çekme
    final results = await Future.wait([
      _taskRepo.getMyTasks(),
      _scheduleRepo.getWeeklySchedule(),
      _homeworkRepo.getMyHomeworks(),
      _getRecentActivityLogs(),
    ]);

    final tasks = results[0] as List<Task>;
    final schedules = results[1] as List<ChildSchedule>;
    final homeworks = results[2] as List<ChildHomework>;
    final logs = results[3] as List<Map<String, dynamic>>;

    // ── 1. Okul çıkışı önerisi ──
    final schoolExitPattern = _analyzeSchoolExitPattern(logs);
    if (schoolExitPattern != null) {
      suggestions.add(
        AiSuggestion(
          id: 'school_exit_water',
          title: 'Okuldan gelince su iç',
          description:
              '$_childName okuldan her gün $schoolExitPattern civarı geliyor. Su içmeyi unutma!',
          type: 'location',
          reason: 'Okul çıkışı pattern',
          icon: Icons.water_drop,
          color: const Color(0xFF3B82F6),
          actionLabel: 'Görev Ekle',
          actionPayload: {
            'title': 'Okuldan gelince su iç',
            'assignedTo': _childId,
          },
        ),
      );
    }

    // ── 2. Akşam yemeği hazırlığı ──
    final eveningTaskPattern = _analyzeEveningTaskPattern(tasks);
    if (eveningTaskPattern != null) {
      suggestions.add(
        AiSuggestion(
          id: 'evening_prep',
          title: 'Akşam yemeğinden önce 1 saat hazırlık',
          description:
              'Yemek görevleri genelde $eveningTaskPattern civarı tamamlanıyor. Erken başla!',
          type: 'time',
          reason: 'Akşam rutin pattern',
          icon: Icons.restaurant,
          color: const Color(0xFFF59E0B),
          actionLabel: 'Görev Ekle',
          actionPayload: {
            'title': 'Akşam yemeği hazırlığı',
            'assignedTo': _childId,
          },
        ),
      );
    }

    // ── 3. Ödev zamanı önerisi ──
    final lateHomeworkPattern = _analyzeLateHomeworkPattern(homeworks);
    if (lateHomeworkPattern) {
      suggestions.add(
        AiSuggestion(
          id: 'early_homework',
          title: 'Ödevlerini erken bitir',
          description:
              'Ödevlerini gece geç saatlerde yapıyorsun. Daha erken başlarsan daha dinç olursun!',
          type: 'habit',
          reason: 'Geç ödev pattern',
          icon: Icons.menu_book,
          color: const Color(0xFF8B5CF6),
          actionLabel: 'Görev Ekle',
          actionPayload: {'title': 'Ödev zamanı', 'assignedTo': _childId},
        ),
      );
    }

    // ── 4. Streak önerisi ──
    final streakDays = _calculateStreak(tasks);
    if (streakDays >= 2) {
      suggestions.add(
        AiSuggestion(
          id: 'streak_keep',
          title: '$streakDays gün streak! 🔥',
          description:
              'Harika! $streakDays gündür görevlerini düzenli tamamlıyorsun. Böyle devam et!',
          type: 'habit',
          reason: 'Streak pattern',
          icon: Icons.local_fire_department,
          color: const Color(0xFFF97316),
          actionLabel: 'Tamamla',
        ),
      );
    }

    // ── 5. Ders programı önerisi ──
    final tomorrowSchedule = _getTomorrowSchedule(schedules);
    if (tomorrowSchedule.isNotEmpty) {
      final firstClass = tomorrowSchedule.first;
      suggestions.add(
        AiSuggestion(
          id: 'tomorrow_ready',
          title: 'Yarın için hazırlan',
          description:
              'Yarın ilk dersin ${firstClass.subject} (${firstClass.startTime}). Malzemelerini hazırladın mı?',
          type: 'schedule',
          reason: 'Yarın ders programı',
          icon: Icons.backpack,
          color: const Color(0xFF10B981),
          actionLabel: 'Görev Ekle',
          actionPayload: {
            'title': '${firstClass.subject} malzemelerini hazırla',
            'assignedTo': _childId,
          },
        ),
      );
    }

    // ── 6. Su içme önerisi (genel sağlık) ──
    suggestions.add(
      AiSuggestion(
        id: 'drink_water',
        title: 'Her saat başı su iç 💧',
        description:
            'Sağlıklı kalmak için günde 8 bardak su içmelisin. Şimdi su molası ver!',
        type: 'habit',
        reason: 'Genel sağlık',
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF06B6D4),
        actionLabel: 'Tamam',
      ),
    );

    // ── 7. Eksik ödev önerisi ──
    final overdueHomeworks = homeworks.where((h) => h.isOverdue).toList();
    if (overdueHomeworks.isNotEmpty) {
      suggestions.add(
        AiSuggestion(
          id: 'overdue_homework',
          title: '${overdueHomeworks.length} ödev gecikti! ⚠️',
          description:
              '${overdueHomeworks.first.subject} ödevi teslim tarihini geçti. Hemen tamamla!',
          type: 'task',
          reason: 'Gecikmiş ödev',
          icon: Icons.warning_amber,
          color: const Color(0xFFEF4444),
          actionLabel: 'Ödevlere Git',
        ),
      );
    }

    // ── 8. Haftasonu aktivite önerisi ──
    if (_isWeekendComing(schedules)) {
      suggestions.add(
        AiSuggestion(
          id: 'weekend_activity',
          title: 'Haftasonu aile aktivitesi planla 🎉',
          description:
              'Haftasonu ders programın boş görünüyor. Aileyle birlikte bir şeyler yapmayı planla!',
          type: 'schedule',
          reason: 'Boş haftasonu',
          icon: Icons.celebration,
          color: const Color(0xFFEC4899),
          actionLabel: 'Tamam',
        ),
      );
    }

    return suggestions;
  }

  // ── Pattern Analiz Metodları ──

  Future<List<Map<String, dynamic>>> _getRecentActivityLogs() async {
    try {
      final response = await _client
          .from('child_activity_logs')
          .select('*')
          .eq('child_id', _childId!)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          )
          .order('created_at', ascending: true);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  String? _analyzeSchoolExitPattern(List<Map<String, dynamic>> logs) {
    // Hafta içi 15:00-16:00 arası login pattern'ini bul
    final schoolLogs = logs.where((l) {
      if (l['activity_type'] != 'login') return false;
      final time = DateTime.parse(l['created_at'] as String);
      final hour = time.hour;
      return time.weekday <= 5 && hour >= 15 && hour <= 16;
    }).toList();

    if (schoolLogs.length >= 3) {
      // Ortalama saati hesapla
      final avgHour =
          schoolLogs
              .map((l) => DateTime.parse(l['created_at'] as String).hour)
              .reduce((a, b) => a + b) /
          schoolLogs.length;
      return '${avgHour.toInt()}:00';
    }
    return null;
  }

  String? _analyzeEveningTaskPattern(List<Task> tasks) {
    final eveningTasks = tasks.where((t) {
      if (t.completedAt == null) return false;
      final hour = t.completedAt!.hour;
      return hour >= 17 && hour <= 20;
    }).toList();

    if (eveningTasks.length >= 2) {
      final avgHour =
          eveningTasks.map((t) => t.completedAt!.hour).reduce((a, b) => a + b) /
          eveningTasks.length;
      return '${avgHour.toInt()}:00';
    }
    return null;
  }

  bool _analyzeLateHomeworkPattern(List<ChildHomework> homeworks) {
    // Gece 21:00'den sonra tamamlanan ödev pattern'i
    final lateHomeworks = homeworks.where((h) {
      if (h.completedAt == null) return false;
      return h.completedAt!.hour >= 21;
    }).toList();

    return lateHomeworks.length >= 2;
  }

  int _calculateStreak(List<Task> tasks) {
    // Son tamamlanan görevlerin ardışık gün sayısını hesapla
    final completedDates = tasks
        .where((t) => t.status == TaskStatus.completed && t.completedAt != null)
        .map(
          (t) => DateTime(
            t.completedAt!.year,
            t.completedAt!.month,
            t.completedAt!.day,
          ),
        )
        .toSet()
        .toList();

    if (completedDates.isEmpty) return 0;

    completedDates.sort((a, b) => b.compareTo(a)); // En yeni önce

    int streak = 1;
    for (int i = 1; i < completedDates.length; i++) {
      final diff = completedDates[i - 1].difference(completedDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    // Bugün tamamlanan var mı kontrol et
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final hasToday = completedDates.any((d) => d == todayDate);

    return hasToday ? streak : 0;
  }

  List<ChildSchedule> _getTomorrowSchedule(List<ChildSchedule> schedules) {
    final tomorrowWeekday = DateTime.now().weekday + 1;
    final targetDay = tomorrowWeekday > 7 ? 1 : tomorrowWeekday;
    return schedules.where((s) => s.dayOfWeek == targetDay).toList();
  }

  bool _isWeekendComing(List<ChildSchedule> schedules) {
    final today = DateTime.now().weekday;
    // Cuma veya haftasonu
    if (today >= 5) return true;

    // Cumartesi/Pazar ders programı boş mu?
    final saturday = schedules.where((s) => s.dayOfWeek == 6).toList();
    final sunday = schedules.where((s) => s.dayOfWeek == 7).toList();
    return saturday.isEmpty && sunday.isEmpty;
  }
}
