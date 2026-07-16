import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../domain/models/child_session.dart';
import '../repositories/child_account_repository.dart';
import 'localization/locale_service.dart';

class ChildAuthService {
  static const _secureStorage = FlutterSecureStorage();
  static const _childSessionKey = 'child_session';
  static const _childModeKey = 'child_mode_active';

  static String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  static String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

  static String get _invalidPinOrAccount => _text(const {
        'tr': 'PIN hatalı veya hesap bulunamadı',
        'en': 'The PIN is incorrect or the account was not found',
        'nl': 'De pincode is onjuist of het account is niet gevonden',
        'fr': 'Le code PIN est incorrect ou le compte est introuvable',
      });

  static ChildSession? _currentSession;

  static ChildSession? get currentSession => _currentSession;

  static bool get isChildMode => _currentSession != null;

  static String? get currentChildId => _currentSession?.childId;

  static String? get currentFamilyId => _currentSession?.familyId;

  /// Hash PIN for secure local storage comparison using SHA-256.
  /// Server-side verification is performed via Supabase RPC.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in as a child using name selection + PIN
  static Future<ChildSession> signIn({
    required String childId,
    required String pin,
  }) async {
    final supabase = SupabaseConfig.safeClient;
    if (supabase == null) {
      throw AppAuthException(_text(const {
        'tr': 'Sunucu bağlantısı kurulamadı',
        'en': 'Could not connect to the server',
        'nl': 'Kan geen verbinding maken met de server',
        'fr': 'Impossible de se connecter au serveur',
      }));
    }

    // Use RPC function to verify PIN and create session
    final response = await supabase.rpc(
      'verify_child_pin',
      params: {
        'p_child_id': childId,
        'p_pin': pin, // Server validates
        'p_device_info': 'Flutter App',
      },
    );

    if (response == null || (response as List).isEmpty) {
      throw AppAuthException(_invalidPinOrAccount);
    }

    final session = ChildSession.fromJson(
      (response).first as Map<String, dynamic>,
    );
    await _persistSession(session);
    _currentSession = session;
    return session;
  }

  /// Yerel (Hive) çocuk hesabıyla oturum aç — tek cihaz, sunucusuz. PIN
  /// ChildAccountRepository.verifyLocalPin ile doğrulanır.
  static Future<ChildSession> signInLocal({
    required String childId,
    required String pin,
    required String childName,
    required String childRole,
    required String familyId,
  }) async {
    if (!ChildAccountRepository().verifyLocalPin(childId, pin)) {
      throw AppAuthException(_invalidPinOrAccount);
    }
    final session = ChildSession(
      token: 'local_$childId',
      expiresAt: DateTime.now().add(const Duration(days: 3650)),
      childName: childName,
      childRole: childRole,
      familyId: familyId,
      childId: childId,
    );
    await _persistSession(session);
    _currentSession = session;
    return session;
  }

  /// Restore child session from secure storage
  static Future<bool> restoreSession() async {
    final jsonStr = await _secureStorage.read(key: _childSessionKey);
    if (jsonStr == null) return false;

    try {
      final session = ChildSession.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      if (session.isExpired) {
        await signOut();
        return false;
      }

      // Yerel oturum (sunucusuz) → sunucu doğrulamasını atla.
      if (session.token.startsWith('local_')) {
        _currentSession = session;
        return true;
      }

      // Validate with server
      final supabase = SupabaseConfig.safeClient;
      if (supabase != null) {
        final response = await supabase.rpc(
          'validate_child_session',
          params: {'p_token': session.token},
        );

        if (response == null || (response as List).isEmpty) {
          await signOut();
          return false;
        }

        final validated = (response).first as Map<String, dynamic>;
        if (validated['is_valid'] != true) {
          await signOut();
          return false;
        }
      }

      _currentSession = session;
      return true;
    } catch (_) {
      await signOut();
      return false;
    }
  }

  /// Sign out child
  static Future<void> signOut() async {
    final session = _currentSession;
    if (session != null) {
      try {
        final supabase = SupabaseConfig.safeClient;
        if (supabase != null) {
          await supabase.rpc(
            'revoke_child_session',
            params: {'p_token': session.token},
          );
        }
      } catch (_) {
        // Ignore revoke errors
      }
    }

    _currentSession = null;
    await _secureStorage.delete(key: _childSessionKey);
    await _secureStorage.delete(key: _childModeKey);
  }

  /// Log child activity
  static Future<void> logActivity(
    String activityType, {
    Map<String, dynamic>? details,
  }) async {
    final childId = currentChildId;
    if (childId == null) return;

    try {
      final supabase = SupabaseConfig.safeClient;
      if (supabase != null) {
        await supabase.rpc(
          'log_child_activity',
          params: {
            'p_child_id': childId,
            'p_activity_type': activityType,
            'p_details': details ?? {},
          },
        );
      }
    } catch (_) {
      // Ignore logging errors
    }
  }

  static Future<void> _persistSession(ChildSession session) async {
    await _secureStorage.write(
      key: _childSessionKey,
      value: jsonEncode(session.toJson()),
    );
    await _secureStorage.write(key: _childModeKey, value: 'true');
  }
}
