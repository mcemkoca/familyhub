import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import 'localization/locale_service.dart';

class SecurityService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  final LocalAuthentication _localAuth;
  final SupabaseClient _supabase;
  final Box<dynamic> _settingsBox;

  SecurityService(this._localAuth, this._supabase, this._settingsBox);

  static Future<SecurityService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception(_text(const {'tr': 'Sunucu bağlantısı kurulamadı', 'en': 'Could not connect to the server', 'nl': 'Kan geen verbinding maken met de server', 'fr': 'Impossible de se connecter au serveur'}));
    final box = await Hive.openBox<dynamic>('settingsBox');
    return SecurityService(LocalAuthentication(), client, box);
  }

  Future<bool> isBiometricAvailable() async {
    return await _localAuth.canCheckBiometrics &&
        await _localAuth.isDeviceSupported();
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: _text(const {'tr': 'FamilyHub’a giriş yapmak için kimliğinizi doğrulayın', 'en': 'Verify your identity to sign in to FamilyHub', 'nl': 'Verifieer je identiteit om in te loggen bij FamilyHub', 'fr': 'Vérifiez votre identité pour vous connecter à FamilyHub'}),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> enableBiometricLogin(bool enabled) async {
    await _settingsBox.put('biometric_enabled', enabled);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('settings').upsert({
        'user_id': userId,
        'security': {'biometric_enabled': enabled},
      }, onConflict: 'user_id');
    }
  }

  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException(_text(const {'tr': 'Oturum açık değil', 'en': 'You are not signed in', 'nl': 'Je bent niet ingelogd', 'fr': 'Vous n’êtes pas connecté'}));

    // 1. Soft delete: profiles.is_deleted = true
    await _supabase.from('profiles').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // 2. Auth kullanıcısını sil (Supabase Admin API / Edge Function gerektirir)
    // NOT: auth.users DELETE service_role yetkisi ister.
    // Production'da Supabase Edge Function veya Admin API kullanılmalı.
    try {
      await _supabase.rpc('delete_user_account', params: {'user_id': userId});
    } catch (e) {
      // ignore: empty_catches
    }

    // 3. Local cache'i temizle
    await _settingsBox.clear();
  }
}
