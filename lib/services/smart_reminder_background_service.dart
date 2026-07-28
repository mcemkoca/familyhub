import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:ui' show PlatformDispatcher;

import '../core/supabase_client.dart';
import '../repositories/smart_reminder_repository.dart';
import '../services/auth_service.dart';
import 'localization/locale_service.dart';

const String _smartReminderTask = 'familyhub.smart_reminder';
const String _reminderIdKey = 'reminder_id';
const String _reminderTitleKey = 'reminder_title';
const String _reminderBodyKey = 'reminder_body';

String _deviceText(Map<String, String> values) {
  final lang = PlatformDispatcher.instance.locale.languageCode;
  return values[lang] ?? values['tr']!;
}

/// Background callback dispatcher for Workmanager.
/// Must be a top-level or static function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _smartReminderTask) {
      final reminderId = inputData?[_reminderIdKey] as String?;
      final title = inputData?[_reminderTitleKey] as String? ?? 'FamilyHub';
      final body = inputData?[_reminderBodyKey] as String? ?? _deviceText(const {'tr': 'Hatırlatma zamanı!', 'en': 'Time for your reminder!', 'nl': 'Tijd voor je herinnering!', 'fr': 'C’est l’heure de votre rappel !'});

      if (reminderId != null) {
        await _showBackgroundNotification(title: title, body: body);

        // Update reminder status in Supabase
        try {
          await SupabaseConfig.safeClient
              ?.from('smart_reminders')
              .update({
                'status': {
                  'state': 'triggered',
                  'last_triggered': DateTime.now().toIso8601String(),
                },
              })
              .eq('id', reminderId);
        } catch (_) {
          // Ignore Supabase errors in background
        }
      }
    }
    return Future.value(true);
  });
}

/// Shows a local notification from a background isolate.
/// Initializes its own plugin instance since the main one may not be available.
Future<void> _showBackgroundNotification({
  required String title,
  required String body,
}) async {
  final notifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notifications.initialize(initSettings);

  final androidDetails = AndroidNotificationDetails(
    'familyhub_channel',
    _deviceText(const {'tr': 'FamilyHub Bildirimleri', 'en': 'FamilyHub Notifications', 'nl': 'FamilyHub-meldingen', 'fr': 'Notifications FamilyHub'}),
    channelDescription: _deviceText(const {'tr': 'Aile etkinlikleri, görevler ve acil durum bildirimleri', 'en': 'Family activities, tasks, and emergency notifications', 'nl': 'Gezinsactiviteiten, taken en noodmeldingen', 'fr': 'Activités familiales, tâches et notifications d’urgence'}),
    importance: Importance.high,
    priority: Priority.high,
  );
  final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

  await notifications.show(
    DateTime.now().millisecond,
    title,
    body,
    details,
  );
}

class SmartReminderBackgroundService {
  static bool _initialized = false;

  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }

  /// Initializes Workmanager and syncs active reminders from Supabase.
  static Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(_callbackDispatcher);
    _initialized = true;
    await syncRemindersFromSupabase();
  }

  /// Schedules a one-off background task for a reminder.
  static Future<void> scheduleReminder({
    required String id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    var delay = when.difference(now);
    if (delay.isNegative) delay = Duration.zero;

    await Workmanager().registerOneOffTask(
      'smart_reminder_$id',
      _smartReminderTask,
      initialDelay: delay,
      inputData: {
        _reminderIdKey: id,
        _reminderTitleKey: title,
        _reminderBodyKey: body,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
      // Zaman-kritik hatırlatma: yalnızca yerel bildirim gösterir, ağ GEREKMEZ.
      // NetworkType.connected olsaydı cihaz çevrimdışıyken hatırlatma
      // gecikir/ateşlenmezdi (spec §8 güvenilirlik). notRequired → tam zamanında.
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  /// Cancels a scheduled reminder by its ID.
  static Future<void> cancelReminder(String id) async {
    await Workmanager().cancelByUniqueName('smart_reminder_$id');
  }

  /// Cancels all scheduled reminder tasks.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Fetches active reminders from Supabase and schedules them.
  static Future<void> syncRemindersFromSupabase() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      final familyId = profile?['family_id'] as String?;
      if (familyId == null) return;

      final reminders = await SmartReminderRepository().getActiveReminders(familyId);

      // Cancel existing tasks and reschedule fresh
      await cancelAll();

      for (final reminder in reminders) {
        DateTime? triggerTime;

        // Prefer explicit nextScheduled time
        triggerTime = reminder.status.nextScheduled;

        // Fallback to time trigger absolute time
        if (triggerTime == null && reminder.triggers.time.enabled) {
          triggerTime = reminder.triggers.time.absoluteTime;
        }

        if (triggerTime != null && triggerTime.isAfter(DateTime.now())) {
          await scheduleReminder(
            id: reminder.id,
            when: triggerTime,
            title: reminder.title,
            body: reminder.description ?? _text(const {'tr': 'Hatırlatma zamanı!', 'en': 'Time for your reminder!', 'nl': 'Tijd voor je herinnering!', 'fr': 'C’est l’heure de votre rappel !'}),
          );
        }
      }
    } catch (e) {
      debugPrint('SmartReminderBackgroundService.syncRemindersFromSupabase error: $e');
    }
  }
}
