/// Ekran ayarları için kullanıcı-izole kalıcı depo.
///
/// DENETİM BULGUSU: birden çok ekranda `_save()` hiçbir şey kaydetmeden
/// "kaydedildi" mesajı gösteriyordu (kaza tespiti, SOS şablonu, konum takibi,
/// profil düzenleyici). Kullanıcı ayarlarının geçerli olduğunu sanıyordu ama
/// ekran her açılışta varsayılana dönüyordu.
///
/// Ayrıca anahtarlar kullanıcı kimliği taşımadığında, aynı cihazda hesap
/// değişince ÖNCEKİ kullanıcının ayarları yenisine uygulanıyordu.
library;

import 'dart:convert';

import '../services/auth_service.dart';
import '../services/hive_service.dart';
import 'app_logger.dart';

class SettingsStore {
  const SettingsStore._();

  /// Kullanıcıya özel anahtar üretir (`<name>_<uid>`).
  /// Oturum yoksa `_anon` — gerçek kullanıcıya ait ayarlar görünmez.
  static String scopedKey(String name) {
    final uid = AuthService.currentUserId;
    return (uid == null || uid.isEmpty) ? '${name}_anon' : '${name}_$uid';
  }

  /// Ayar haritasını kaydeder. Başarılıysa `true`.
  ///
  /// UI, dönen değeri kontrol ETMEDEN "kaydedildi" göstermemelidir.
  static Future<bool> save(String name, Map<String, dynamic> values) async {
    try {
      await HiveService.setSetting(scopedKey(name), jsonEncode(values));
      return true;
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'settings', operation: 'save:$name', stackTrace: st);
      return false;
    }
  }

  /// Kayıtlı ayarları okur; yoksa/bozuksa boş harita (varsayılanlar korunur).
  static Map<String, dynamic> load(String name) {
    try {
      final raw = HiveService.getSetting(scopedKey(name));
      if (raw == null || raw.isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return const {};
    } catch (e) {
      AppLogger.logBestEffort(e,
          module: 'settings', operation: 'load:$name');
      return const {};
    }
  }

  /// Kullanıcının bir ayar grubunu siler (logout/hesap silme temizliği).
  static Future<void> clear(String name) async {
    try {
      await HiveService.setSetting(scopedKey(name), '');
    } catch (e) {
      AppLogger.logBestEffort(e,
          module: 'settings', operation: 'clear:$name');
    }
  }
}
