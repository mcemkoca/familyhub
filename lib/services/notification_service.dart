import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'hive_service.dart';

typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static NotificationTapCallback? _onTap;

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
    const androidChannel = AndroidNotificationChannel(
      'familyhub_channel',
      'FamilyHub Bildirimleri',
      description: 'Aile etkinlikleri, görevler ve acil durum bildirimleri',
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
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'familyhub_channel',
          'FamilyHub Bildirimleri',
          channelDescription: 'Aile etkinlikleri, görevler ve acil durum bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
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
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'familyhub_channel',
          'FamilyHub Bildirimleri',
          channelDescription: 'Aile etkinlikleri, görevler ve acil durum bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
