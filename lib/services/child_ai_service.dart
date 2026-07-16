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
import 'localization/locale_service.dart';

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

  String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

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
          title: _text(const {
            'tr': 'Okuldan gelince su iç',
            'en': 'Drink water when you get home from school',
            'nl': 'Drink water als je thuiskomt van school',
            'fr': "Bois de l’eau en rentrant de l’école",
          }),
          description: _text({
            'tr': '$_childName okuldan her gün $schoolExitPattern civarı geliyor. Su içmeyi unutma!',
            'en': '$_childName gets home from school around $schoolExitPattern every day. Don’t forget to drink water!',
            'nl': '$_childName komt elke dag rond $schoolExitPattern thuis van school. Vergeet niet om water te drinken!',
            'fr': '$_childName rentre de l’école vers $schoolExitPattern chaque jour. N’oublie pas de boire de l’eau !',
          }),
          type: 'location',
          reason: _text(const {
            'tr': 'Okul çıkışı düzeni', 'en': 'After-school pattern',
            'nl': 'Patroon na school', 'fr': 'Routine après l’école',
          }),
          icon: Icons.water_drop,
          color: const Color(0xFF3B82F6),
          actionLabel: _addTaskLabel,
          actionPayload: {
            'title': _text(const {
              'tr': 'Okuldan gelince su iç',
              'en': 'Drink water after school',
              'nl': 'Drink water na school',
              'fr': "Boire de l’eau après l’école",
            }),
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
          title: _text(const {
            'tr': 'Akşam yemeğinden 1 saat önce hazırlan',
            'en': 'Get ready 1 hour before dinner',
            'nl': 'Begin 1 uur voor het avondeten',
            'fr': 'Prépare-toi 1 heure avant le dîner',
          }),
          description: _text({
            'tr': 'Yemek görevleri genelde $eveningTaskPattern civarı tamamlanıyor. Erken başla!',
            'en': 'Dinner tasks are usually completed around $eveningTaskPattern. Start early!',
            'nl': 'Taken voor het avondeten zijn meestal rond $eveningTaskPattern klaar. Begin op tijd!',
            'fr': 'Les tâches du dîner sont généralement terminées vers $eveningTaskPattern. Commence tôt !',
          }),
          type: 'time',
          reason: _text(const {
            'tr': 'Akşam rutini', 'en': 'Evening routine',
            'nl': 'Avondroutine', 'fr': 'Routine du soir',
          }),
          icon: Icons.restaurant,
          color: const Color(0xFFF59E0B),
          actionLabel: _addTaskLabel,
          actionPayload: {
            'title': _text(const {
              'tr': 'Akşam yemeği hazırlığı', 'en': 'Dinner preparation',
              'nl': 'Avondeten voorbereiden', 'fr': 'Préparation du dîner',
            }),
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
          title: _text(const {
            'tr': 'Ödevlerini erken bitir', 'en': 'Finish your homework early',
            'nl': 'Maak je huiswerk vroeg af', 'fr': 'Termine tes devoirs tôt',
          }),
          description: _text(const {
            'tr': 'Ödevlerini gece geç saatlerde yapıyorsun. Daha erken başlarsan daha dinç olursun!',
            'en': 'You do your homework late at night. You’ll feel more energetic if you start earlier!',
            'nl': 'Je maakt je huiswerk laat op de avond. Als je eerder begint, heb je meer energie!',
            'fr': 'Tu fais tes devoirs tard le soir. En commençant plus tôt, tu auras plus d’énergie !',
          }),
          type: 'habit',
          reason: _text(const {
            'tr': 'Geç ödev düzeni', 'en': 'Late-homework pattern',
            'nl': 'Laat huiswerkpatroon', 'fr': 'Habitude de devoirs tardifs',
          }),
          icon: Icons.menu_book,
          color: const Color(0xFF8B5CF6),
          actionLabel: _addTaskLabel,
          actionPayload: {
            'title': _text(const {
              'tr': 'Ödev zamanı', 'en': 'Homework time',
              'nl': 'Huiswerktijd', 'fr': 'L’heure des devoirs',
            }),
            'assignedTo': _childId,
          },
        ),
      );
    }

    // ── 4. Streak önerisi ──
    final streakDays = _calculateStreak(tasks);
    if (streakDays >= 2) {
      suggestions.add(
        AiSuggestion(
          id: 'streak_keep',
          title: _streakTitle(streakDays),
          description: _streakDescription(streakDays),
          type: 'habit',
          reason: _text(const {
            'tr': 'Seri düzeni', 'en': 'Streak pattern',
            'nl': 'Reekspatroon', 'fr': 'Série en cours',
          }),
          icon: Icons.local_fire_department,
          color: const Color(0xFFF97316),
          actionLabel: _completeLabel,
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
          title: _text(const {
            'tr': 'Yarın için hazırlan', 'en': 'Get ready for tomorrow',
            'nl': 'Bereid je voor op morgen', 'fr': 'Prépare-toi pour demain',
          }),
          description: _tomorrowDescription(firstClass),
          type: 'schedule',
          reason: _text(const {
            'tr': 'Yarının ders programı', 'en': "Tomorrow’s class schedule",
            'nl': 'Lesrooster van morgen', 'fr': 'Emploi du temps de demain',
          }),
          icon: Icons.backpack,
          color: const Color(0xFF10B981),
          actionLabel: _addTaskLabel,
          actionPayload: {
            'title': _classMaterialsTitle(firstClass.subject),
            'assignedTo': _childId,
          },
        ),
      );
    }

    // ── 6. Su içme önerisi (genel sağlık) ──
    suggestions.add(
      AiSuggestion(
        id: 'drink_water',
        title: _text(const {
          'tr': 'Her saat başı su iç 💧', 'en': 'Drink water every hour 💧',
          'nl': 'Drink elk uur water 💧', 'fr': 'Bois de l’eau chaque heure 💧',
        }),
        description: _text(const {
          'tr': 'Sağlıklı kalmak için günde 8 bardak su içmelisin. Şimdi su molası ver!',
          'en': 'Drink 8 glasses of water a day to stay healthy. Take a water break now!',
          'nl': 'Drink 8 glazen water per dag om gezond te blijven. Neem nu een waterpauze!',
          'fr': 'Bois 8 verres d’eau par jour pour rester en bonne santé. Fais une pause eau maintenant !',
        }),
        type: 'habit',
        reason: _text(const {
          'tr': 'Genel sağlık', 'en': 'General health',
          'nl': 'Algemene gezondheid', 'fr': 'Santé générale',
        }),
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF06B6D4),
        actionLabel: _doneLabel,
      ),
    );

    // ── 7. Eksik ödev önerisi ──
    final overdueHomeworks = homeworks.where((h) => h.isOverdue).toList();
    if (overdueHomeworks.isNotEmpty) {
      suggestions.add(
        AiSuggestion(
          id: 'overdue_homework',
          title: _overdueTitle(overdueHomeworks.length),
          description: _overdueDescription(overdueHomeworks.first.subject),
          type: 'task',
          reason: _text(const {
            'tr': 'Gecikmiş ödev', 'en': 'Overdue homework',
            'nl': 'Achterstallig huiswerk', 'fr': 'Devoir en retard',
          }),
          icon: Icons.warning_amber,
          color: const Color(0xFFEF4444),
          actionLabel: _text(const {
            'tr': 'Ödevlere Git', 'en': 'Go to Homework',
            'nl': 'Ga naar huiswerk', 'fr': 'Voir les devoirs',
          }),
        ),
      );
    }

    // ── 8. Haftasonu aktivite önerisi ──
    if (_isWeekendComing(schedules)) {
      suggestions.add(
        AiSuggestion(
          id: 'weekend_activity',
          title: _text(const {
            'tr': 'Hafta sonu aile aktivitesi planla 🎉',
            'en': 'Plan a family activity for the weekend 🎉',
            'nl': 'Plan een gezinsactiviteit voor het weekend 🎉',
            'fr': 'Planifie une activité en famille ce week-end 🎉',
          }),
          description: _text(const {
            'tr': 'Hafta sonu ders programın boş görünüyor. Aileyle birlikte bir şeyler yapmayı planla!',
            'en': 'Your weekend schedule looks free. Plan something to do with your family!',
            'nl': 'Je lesrooster voor het weekend lijkt leeg. Plan iets leuks met je gezin!',
            'fr': 'Ton emploi du temps semble libre ce week-end. Prévois une activité avec ta famille !',
          }),
          type: 'schedule',
          reason: _text(const {
            'tr': 'Boş hafta sonu', 'en': 'Free weekend',
            'nl': 'Vrij weekend', 'fr': 'Week-end libre',
          }),
          icon: Icons.celebration,
          color: const Color(0xFFEC4899),
          actionLabel: _doneLabel,
        ),
      );
    }

    return suggestions;
  }

  String get _addTaskLabel => _text(const {
        'tr': 'Görev Ekle', 'en': 'Add Task',
        'nl': 'Taak toevoegen', 'fr': 'Ajouter une tâche',
      });

  String get _completeLabel => _text(const {
        'tr': 'Tamamla', 'en': 'Complete', 'nl': 'Voltooien', 'fr': 'Terminer',
      });

  String get _doneLabel => _text(const {
        'tr': 'Tamam', 'en': 'Done', 'nl': 'Klaar', 'fr': 'Terminé',
      });

  String _streakTitle(int days) => _text({
        'tr': '$days günlük seri! 🔥', 'en': '$days-day streak! 🔥',
        'nl': '$days dagen op rij! 🔥', 'fr': 'Série de $days jours ! 🔥',
      });

  String _streakDescription(int days) => _text({
        'tr': 'Harika! $days gündür görevlerini düzenli tamamlıyorsun. Böyle devam et!',
        'en': 'Great! You’ve completed your tasks consistently for $days days. Keep it up!',
        'nl': 'Geweldig! Je voltooit je taken al $days dagen achter elkaar. Ga zo door!',
        'fr': 'Bravo ! Tu termines tes tâches régulièrement depuis $days jours. Continue comme ça !',
      });

  String _tomorrowDescription(ChildSchedule firstClass) => _text({
        'tr': 'Yarın ilk dersin ${firstClass.subject} (${firstClass.startTime}). Malzemelerini hazırladın mı?',
        'en': 'Your first class tomorrow is ${firstClass.subject} (${firstClass.startTime}). Have you prepared your materials?',
        'nl': 'Je eerste les morgen is ${firstClass.subject} (${firstClass.startTime}). Heb je je spullen klaargelegd?',
        'fr': 'Ton premier cours demain est ${firstClass.subject} (${firstClass.startTime}). As-tu préparé tes affaires ?',
      });

  String _classMaterialsTitle(String subject) => _text({
        'tr': '$subject malzemelerini hazırla',
        'en': 'Prepare your $subject materials',
        'nl': 'Leg je spullen voor $subject klaar',
        'fr': 'Préparer les affaires pour $subject',
      });

  String _overdueTitle(int count) => _text({
        'tr': '$count ödev gecikti! ⚠️', 'en': '$count overdue homework assignment${count == 1 ? '' : 's'}! ⚠️',
        'nl': '$count huiswerkopdracht${count == 1 ? '' : 'en'} te laat! ⚠️',
        'fr': '$count devoir${count == 1 ? '' : 's'} en retard ! ⚠️',
      });

  String _overdueDescription(String subject) => _text({
        'tr': '$subject ödevi teslim tarihini geçti. Hemen tamamla!',
        'en': 'Your $subject homework is past its due date. Complete it now!',
        'nl': 'Je huiswerk voor $subject is te laat. Maak het nu af!',
        'fr': 'Ton devoir de $subject a dépassé la date limite. Termine-le maintenant !',
      });

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
