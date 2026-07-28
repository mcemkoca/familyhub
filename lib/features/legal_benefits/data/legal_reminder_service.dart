import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';

/// Yasal hak/avantaj hatırlatmaları — kullanıcı-izole planlama + kalıcılık.
/// Geçmiş tarihe planlama YAPMAZ; bildirim metni planlama anındaki dilde alınır.
class LegalReminderService {
  LegalReminderService._();
  static final instance = LegalReminderService._();

  String get _key {
    final uid = AuthService.currentUserId ?? 'anon';
    return 'legal_reminders_$uid';
  }

  /// Planlanmış hatırlatması olan benefit id'leri.
  Set<String> reminderIds() {
    final raw = HiveService.getSetting(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  bool hasReminder(String benefitId) => reminderIds().contains(benefitId);

  /// Bildirim id'si — benefit id'sinden stabil 31-bit int.
  static int notificationId(String benefitId) =>
      benefitId.hashCode & 0x7fffffff;

  /// [days] gün sonrasına hatırlatma kurar. Geçmiş/0 tarih reddedilir.
  /// [title]/[body] çağıran ekrandan (aktif dilde) gelir.
  /// Dönüş: kuruldu → true, geçersiz tarih → false.
  Future<bool> schedule({
    required String benefitId,
    required int days,
    required String title,
    required String body,
  }) async {
    if (days <= 0) return false;
    final when = DateTime.now().add(Duration(days: days));
    if (!when.isAfter(DateTime.now())) return false; // past-date guard

    await NotificationService.scheduleNotification(
      id: notificationId(benefitId),
      title: title,
      body: body,
      scheduledDate: when,
      payload: 'legal:$benefitId',
    );

    final ids = reminderIds()..add(benefitId);
    await HiveService.setSetting(_key, jsonEncode(ids.toList()));
    return true;
  }

  Future<void> cancel(String benefitId) async {
    await NotificationService.cancelNotification(notificationId(benefitId));
    final ids = reminderIds()..remove(benefitId);
    await HiveService.setSetting(_key, jsonEncode(ids.toList()));
  }
}
