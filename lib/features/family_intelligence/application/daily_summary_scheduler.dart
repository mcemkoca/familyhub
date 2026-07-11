import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';

/// Aile Zekası günlük özet bildirimi — her gün belirlenen saatte tekrarlar.
/// Ayarlar Hive'da kalıcı; bildirim metni (lokalize) çağrı anında verilir.
class DailySummaryScheduler {
  DailySummaryScheduler._();
  static final instance = DailySummaryScheduler._();

  static const _notificationId = 918273; // stabil, çakışmayan id
  static const _enabledKey = 'fi_daily_summary_enabled';
  static const _hourKey = 'fi_daily_summary_hour';

  bool get isEnabled {
    try {
      return HiveService.getBoolSetting(_enabledKey, defaultValue: false);
    } catch (_) {
      return false; // Hive hazır değil (test/erken init) → güvenli varsayılan.
    }
  }

  int get hour {
    try {
      final raw = HiveService.getSetting(_hourKey);
      return raw != null ? int.tryParse(raw) ?? 8 : 8;
    } catch (_) {
      return 8;
    }
  }

  /// Günlük özeti [hour]:00'da planlar ve tercihi kaydeder.
  Future<void> enable({
    required int hour,
    required String title,
    required String body,
  }) async {
    await HiveService.setBoolSetting(_enabledKey, true);
    await HiveService.setSetting(_hourKey, hour.toString());
    await NotificationService.scheduleDaily(
      id: _notificationId,
      title: title,
      body: body,
      hour: hour,
      payload: 'fi_daily_summary',
    );
  }

  Future<void> disable() async {
    await HiveService.setBoolSetting(_enabledKey, false);
    await NotificationService.cancelNotification(_notificationId);
  }
}
