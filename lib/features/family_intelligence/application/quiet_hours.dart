import '../../../services/hive_service.dart';

/// Sessiz saatler — bu aralıkta bildirim gönderilmez (kullanıcı tercihine saygı).
/// Gece yarısını geçen aralıkları (ör. 22:00–08:00) doğru ele alır. Saf/test edilebilir.
class QuietHours {
  final int startHour; // dahil
  final int endHour; // hariç

  const QuietHours({this.startHour = 22, this.endHour = 8});

  /// Hive ayarlarından yükler (varsayılan 22:00–08:00).
  factory QuietHours.fromSettings() {
    final s = HiveService.getSetting('quiet_hours_start');
    final e = HiveService.getSetting('quiet_hours_end');
    return QuietHours(
      startHour: int.tryParse(s ?? '') ?? 22,
      endHour: int.tryParse(e ?? '') ?? 8,
    );
  }

  /// Sessiz saatler etkin mi? (kapatılabilir)
  static bool get enabled =>
      HiveService.getBoolSetting('quiet_hours_enabled', defaultValue: true);

  /// Verilen saat (0-23) sessiz aralıkta mı?
  bool isQuietHour(int hour) {
    if (startHour == endHour) return false; // aralık yok
    if (startHour < endHour) {
      // Aynı gün içi: [start, end)
      return hour >= startHour && hour < endHour;
    }
    // Gece yarısını geçen: [start, 24) ∪ [0, end)
    return hour >= startHour || hour < endHour;
  }

  bool isQuietNow([DateTime? now]) =>
      isQuietHour((now ?? DateTime.now()).hour);
}
