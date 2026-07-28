import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'hive_service.dart';
import 'localization/locale_service.dart';

typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static NotificationTapCallback? _onTap;

  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }

  static String get _channelName => _text(const {'tr': 'FamilyHub Bildirimleri', 'en': 'FamilyHub Notifications', 'nl': 'FamilyHub-meldingen', 'fr': 'Notifications FamilyHub'});
  static String get _channelDescription => _text(const {'tr': 'Aile etkinlikleri, görevler ve acil durum bildirimleri', 'en': 'Family activities, tasks, and emergency notifications', 'nl': 'Gezinsactiviteiten, taken en noodmeldingen', 'fr': 'Activités familiales, tâches et notifications d’urgence'});

  static NotificationDetails get _notificationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          'familyhub_channel', _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

  static void setOnTapCallback(NotificationTapCallback onTap) {
    _onTap = onTap;
  }

  static Future<void> init({NotificationTapCallback? onTap}) async {
    if (_initialized) return;
    _onTap = onTap;
    tz_data.initializeTimeZones();
    // KRİTİK: tz.local varsayılan olarak UTC'dir → zonedSchedule yerel saati
    // UTC sanar ve bildirim yanlış saatte gelir. Ülke ayarına göre yerel
    // saat dilimini kur (BE/NL/TR — uygulamanın hedef pazarları).
    _setLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _onTap?.call(details.payload);
      },
    );

    // Create notification channel for Android
    final androidChannel = AndroidNotificationChannel(
      'familyhub_channel',
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Ülke ayarına göre IANA saat dilimini seçer (varsayılan Europe/Brussels).
  static void _setLocalTimezone() {
    try {
      final country = (HiveService.getSetting('country') ?? 'BE').toUpperCase();
      final name = switch (country) {
        'TR' => 'Europe/Istanbul',
        'NL' => 'Europe/Amsterdam',
        'DE' => 'Europe/Berlin',
        'FR' => 'Europe/Paris',
        _ => 'Europe/Brussels',
      };
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Konum bulunamazsa timezone paketi UTC'de kalır — yine de çalışır.
    }
  }

  /// Ülke değişince (ayarlardan) saat dilimini yeniden uygula.
  static void refreshTimezone() => _setLocalTimezone();

  static Future<bool> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      // millisecond (0-999) çakışıp bildirimleri ezerdi → benzersiz 32-bit id.
      DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      _notificationDetails,
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Verilen saat/dakikanın bir SONRAKI oluşumu (bugün geçtiyse yarın).
  static tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Her gün aynı saatte tekrarlayan bildirim (ör. günlük özet).
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    int minute = 0,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      nextInstanceOfTime(hour, minute),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // günlük tekrar
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
