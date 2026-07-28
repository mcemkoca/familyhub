import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../domain/privacy_preferences.dart';

/// Gizlilik tercihleri kalıcılığı — kullanıcı-izole. Hive'a karşı defensive.
class PrivacyRepository {
  PrivacyRepository._();
  static final instance = PrivacyRepository._();

  String get _key => 'privacy_prefs_${AuthService.currentUserId ?? 'anon'}';

  PrivacyPreferences load() {
    try {
      final raw = HiveService.getSetting(_key);
      if (raw == null || raw.isEmpty) return const PrivacyPreferences();
      return PrivacyPreferences.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const PrivacyPreferences();
    }
  }

  Future<void> save(PrivacyPreferences prefs) async {
    try {
      await HiveService.setSetting(_key, jsonEncode(prefs.toJson()));
    } catch (_) {
      // Hazır değilse sessizce atla — tercih yerelde kaybolmaz (sonra kaydedilir).
    }
  }

  /// AI bu modülün verisini kullanabilir mi? (context builder çağırır)
  bool aiAllows(PrivacyModule m) => load().aiAllows(m);
}
