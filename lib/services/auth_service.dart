import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../domain/models/user_model.dart';
import 'auth/auth_error_mapper.dart';
import 'fcm_service.dart';
import 'hive_service.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();
  static const _sessionKey = 'supabase_session';

  static SupabaseClient? get safeClient => SupabaseConfig.safeClient;

  static SupabaseClient? get client => SupabaseConfig.safeClient;

  static String get _languageCode {
    final savedLanguage = HiveService.getSetting('language');
    final useDevice = HiveService.getBoolSetting(
      'useDeviceLanguage',
      defaultValue: false,
    );
    if (useDevice || savedLanguage == null || savedLanguage.isEmpty) {
      for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
        if (const {'tr', 'en', 'nl', 'fr'}.contains(locale.languageCode)) {
          return locale.languageCode;
        }
      }
    }
    return switch (savedLanguage) {
      'English' => 'en',
      'Nederlands' => 'nl',
      'Français' => 'fr',
      _ => 'tr',
    };
  }

  static String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

  static String _withDetail(Map<String, String> values, Object detail) =>
      '${_text(values)}: $detail';

  // Google native sign-in için Supabase'e verilecek WEB (server) Client ID.
  // Bu değer, google-services.json ile AYNI Google Cloud projesine ait olmalı.
  // Derleme sırasında override edilebilir:
  //   --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
  // Boş/uyumsuz bırakılırsa native Google girişi DEVELOPER_ERROR verir.
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '631270363894-2c8m0ea0ub83u01ne379cpvc5mp6221d.apps.googleusercontent.com',
  );

  static bool get isGoogleSignInConfigured => _googleWebClientId.isNotEmpty;

  // Tek GoogleSignIn örneği — birden fazla initialize etmek native tarafta
  // tutarsız duruma yol açar.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _googleWebClientId,
  );

  static User? get currentUser => client?.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState>? get authStateChanges =>
      client?.auth.onAuthStateChange;

  static bool _authListenerInitialized = false;
  static StreamSubscription<AuthState>? _authSub;

  static Future<void> initAuthListener() async {
    if (_authListenerInitialized) return;
    _authListenerInitialized = true;
    _authSub = client?.auth.onAuthStateChange.listen(
      (event) async {
        switch (event.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
            await _persistSession(event.session);
            break;
          case AuthChangeEvent.signedOut:
            await _secureStorage.delete(key: _sessionKey);
            break;
          default:
            break;
        }
      },
      // Geçici ağ/refresh hatası uygulamayı crash ETTİRMEMELİ ve kullanıcıyı
      // OTOMATİK LOGOUT ETMEMELİ. Yalnızca kesin süresi dolmuş/geçersiz
      // token durumunda yerel oturum temizlenir; onu SDK signedOut event'i
      // üzerinden zaten ele alıyoruz. Burada sadece güvenli logluyoruz.
      onError: (Object error, StackTrace stackTrace) {
        logAuthError(
          operation: 'onAuthStateChange',
          error: error,
          stackTrace: stackTrace,
        );
      },
      cancelOnError: false,
    );
  }

  static Future<void> restoreSession() async {
    final supabase = client;
    if (supabase == null) return;

    // If Supabase already has a session (auto-restored), sync to secure storage
    final existingSession = supabase.auth.currentSession;
    if (existingSession != null) {
      await _persistSession(existingSession);
      return;
    }

    // Fallback: restore from secure storage
    final refreshToken = await _secureStorage.read(key: _sessionKey);
    if (refreshToken != null) {
      try {
        await supabase.auth.setSession(refreshToken);
        // After successful restore, sync the new session back
        final newSession = supabase.auth.currentSession;
        if (newSession != null) {
          await _persistSession(newSession);
        }
      } catch (_) {
        await _secureStorage.delete(key: _sessionKey);
      }
    }
  }

  static Future<({AuthResponse response, String? familyId})> signUp({
    required String email,
    required String password,
    required String name,
    String? familyName,
  }) async {
    if (!email.contains('@')) {
      throw AppAuthException(_text(const {
        'tr': 'Geçerli bir e-posta adresi girin',
        'en': 'Enter a valid email address',
        'nl': 'Voer een geldig e-mailadres in',
        'fr': 'Saisissez une adresse e-mail valide',
      }));
    }
    if (password.length < 8) {
      throw AppAuthException(_text(const {
        'tr': 'Şifre en az 8 karakter olmalı',
        'en': 'The password must be at least 8 characters',
        'nl': 'Het wachtwoord moet minstens 8 tekens bevatten',
        'fr': 'Le mot de passe doit comporter au moins 8 caractères',
      }));
    }
    if (name.trim().length < 2) {
      throw AppAuthException(_text(const {
        'tr': 'İsim en az 2 karakter olmalı',
        'en': 'The name must be at least 2 characters',
        'nl': 'De naam moet minstens 2 tekens bevatten',
        'fr': 'Le nom doit comporter au moins 2 caractères',
      }));
    }

    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);

    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim(), 'family_name': familyName?.trim()},
    );

    if (response.user == null) {
      throw AppAuthException(_text(const {
        'tr': 'Kayıt başarısız oldu', 'en': 'Registration failed',
        'nl': 'Registratie mislukt', 'fr': 'L’inscription a échoué',
      }));
    }

    final userId = response.user!.id;

    // Create profile
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'display_name': name.trim(),
        'email': email.trim(),
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      throw AppAuthException(_withDetail(const {
        'tr': 'Profil oluşturulamadı', 'en': 'Could not create the profile',
        'nl': 'Het profiel kon niet worden aangemaakt',
        'fr': 'Le profil n’a pas pu être créé',
      }, e));
    }

    // Create family if familyName provided
    String? familyId;
    if (familyName != null && familyName.trim().isNotEmpty) {
      try {
        final familyResponse = await supabase
            .from('families')
            .insert({'name': familyName.trim(), 'created_by': userId})
            .select('id')
            .single();
        familyId = familyResponse['id'] as String?;
      } catch (e) {
        throw AppAuthException(_withDetail(const {
          'tr': 'Aile oluşturulamadı', 'en': 'Could not create the family',
          'nl': 'Het gezin kon niet worden aangemaakt',
          'fr': 'La famille n’a pas pu être créée',
        }, e));
      }
    }

    // Add creator as admin to family + update profile family_id
    if (familyId != null) {
      try {
        await supabase.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'admin',
          'display_name': name.trim(),
        });
        await supabase
            .from('profiles')
            .update({'family_id': familyId})
            .eq('id', userId);
      } catch (e) {
        throw AppAuthException(_withDetail(const {
          'tr': 'Aile üyeliği oluşturulamadı',
          'en': 'Could not create the family membership',
          'nl': 'Het gezinslidmaatschap kon niet worden aangemaakt',
          'fr': 'L’adhésion à la famille n’a pas pu être créée',
        }, e));
      }
    }

    await _persistSession(response.session);
    return (response: response, familyId: familyId);
  }

  /// Giriş yapan kullanıcının MUTLAKA bir ailesi olmasını garanti eder.
  /// family_id yoksa otomatik bir aile oluşturup kullanıcıyı admin yapar.
  /// Böylece migration sonrası tüm bulut aile özellikleri (çocuk hesabı,
  /// davet, izinler) her kullanıcı için çalışır. family_id döndürür.
  static Future<String?> ensureFamily() async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return null;
    try {
      final profile = await supabase
          .from('profiles')
          .select('family_id, display_name')
          .eq('id', userId)
          .maybeSingle();
      final existing = profile?['family_id'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;

      final name = (profile?['display_name'] as String?)?.trim();
      final familyName = (name != null && name.isNotEmpty)
          ? _familyName(name)
          : _myFamily;

      final fam = await supabase
          .from('families')
          .insert({'name': familyName, 'created_by': userId})
          .select('id')
          .single();
      final familyId = fam['id'] as String;

      await supabase.from('family_members').insert({
        'family_id': familyId,
        'user_id': userId,
        'role': 'admin',
        'display_name': name ?? _me,
      });
      await supabase
          .from('profiles')
          .update({'family_id': familyId})
          .eq('id', userId);
      return familyId;
    } catch (e) {
      return null;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw AuthFailure(
        AuthFailureKind.invalidCredentials,
        _text(const {
          'tr': 'E-posta ve parola boş bırakılamaz.',
          'en': 'Email and password cannot be empty.',
          'nl': 'E-mailadres en wachtwoord mogen niet leeg zijn.',
          'fr': 'L’adresse e-mail et le mot de passe sont obligatoires.',
        }),
        code: 'empty_input',
      );
    }

    // Yalnızca geçici ağ/TLS/timeout/5xx durumlarında en fazla 2 kontrollü
    // retry. Yanlış parola / rate-limit / doğrulanmamış e-posta retry EDİLMEZ.
    final response = await retryAuth(
      () => supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      ),
      operation: 'signInWithPassword',
    );

    if (response.session == null) {
      throw AuthFailure(
        AuthFailureKind.invalidCredentials,
        _invalidCredentials,
        code: 'no_session',
      );
    }

    await _persistSession(response.session);
    return response;
  }

  /// Join an existing family by invite code.
  /// Returns the family_id if successful, throws on failure.
  static Future<String?> joinFamilyByCode(String code) async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) {
      throw AppAuthException(_signInRequired);
    }

    try {
      final result = await supabase.rpc(
        'join_family_by_code',
        params: {'p_code': code.trim()},
      );
      if (result == true || result != null) {
        // Try to get the family_id from family_members
        try {
          final fm = await supabase
              .from('family_members')
              .select('family_id')
              .eq('user_id', userId)
              .maybeSingle();
          final familyId = fm?['family_id'] as String?;
          if (familyId != null) {
            await supabase
                .from('profiles')
                .update({'family_id': familyId})
                .eq('id', userId);
            return familyId;
          }
        } catch (e) {
          debugPrint('joinFamilyByCode family_members lookup error: $e');
        }
        return result.toString();
      }
      throw AppAuthException(_text(const {
        'tr': 'Geçersiz davet kodu', 'en': 'Invalid invite code',
        'nl': 'Ongeldige uitnodigingscode', 'fr': 'Code d’invitation invalide',
      }));
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException(_withDetail(const {
        'tr': 'Aileye katılma başarısız', 'en': 'Could not join the family',
        'nl': 'Deelname aan het gezin is mislukt',
        'fr': 'Impossible de rejoindre la famille',
      }, e));
    }
  }

  static Future<void> signOut() async {
    await _authSub?.cancel();
    _authSub = null;
    _authListenerInitialized = false;
    // Sign out from all auth providers
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
    try {
      await client?.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
    await _secureStorage.delete(key: _sessionKey);
    // Hesaba özel yerel önbellekleri temizle — sonraki kullanıcı önceki
    // kullanıcının verisini görmesin. Buluttaki veri korunur.
    try {
      await HiveService.clearShoppingItems();
    } catch (e) {
      debugPrint('signOut cache clear error: $e');
    }
    SupabaseConfig.disposeListener();
  }

  /// Uygulamaya dönüşteki OAuth redirect şeması. AndroidManifest'teki
  /// intent-filter ve Supabase Dashboard → Auth → URL Configuration →
  /// Redirect URLs ile BİREBİR aynı olmalıdır.
  static const googleRedirectScheme = 'com.miro.familyhub://login-callback';

  /// Google ile giriş — **tarayıcı tabanlı Supabase OAuth** akışı.
  ///
  /// Native `google_sign_in`'in aksine SHA-1/Android OAuth Client KAYDI
  /// GEREKTİRMEZ; yalnızca Supabase Dashboard'da Google provider'ın etkin
  /// olması ve redirect URL'in tanımlı olması yeterlidir. Böylece
  /// `google-services.json`'daki boş `oauth_client` / DEVELOPER_ERROR sorunu
  /// tamamen atlanır.
  ///
  /// Akış asenkrondur: tarayıcı açılır, kullanıcı onaylar, deep-link ile
  /// uygulamaya döner ve session `onAuthStateChange` (signedIn) üzerinden
  /// tamamlanır. Bu yüzden burada AuthResponse döndürülmez; navigasyonu
  /// login ekranındaki auth dinleyicisi üstlenir.
  ///
  /// Dönüş: tarayıcı başarıyla açıldıysa `true`. Kullanıcı tarayıcıyı iptal
  /// ederse session hiç oluşmaz (sessizce login ekranında kalınır).
  static Future<bool> signInWithGoogle() async {
    final supabase = client;
    if (supabase == null) {
      throw AuthFailure(
        AuthFailureKind.configurationError,
        _text(const {
          'tr': 'Sunucu bağlantısı kurulmadı. Lütfen tekrar deneyin.',
          'en': 'Could not connect to the server. Please try again.',
          'nl': 'Kan geen verbinding maken met de server. Probeer het opnieuw.',
          'fr': 'Impossible de se connecter au serveur. Veuillez réessayer.',
        }),
        code: 'no_client',
      );
    }

    try {
      // Harici tarayıcı, redirect'in uygulamaya geri dönmesi için en güvenilir
      // moddur (in-app WebView bazı cihazlarda deep-link'i yakalayamaz).
      return await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: googleRedirectScheme,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      throw classifyAuthError(e);
    }
  }

  /// Synchronizes user profile, local cache, and FCM token after any login.
  static Future<UserModel> syncUserPostLogin(AuthResponse response) async {
    final supabase = client;
    final user = response.user;
    if (supabase == null || user == null) {
      throw AppAuthException(_text(const {
        'tr': 'Oturum bulunamadı', 'en': 'Session not found',
        'nl': 'Sessie niet gevonden', 'fr': 'Session introuvable',
      }));
    }

    final userId = user.id;
    final email = user.email ?? '';
    final displayName =
        user.userMetadata?['display_name'] as String? ?? email.split('@').first;
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;

    // 1. Upsert profile in Supabase (canonical source of truth)
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'display_name': displayName,
        'email': email,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('syncUserPostLogin profile upsert error: $e');
    }

    // 2. Check for existing identities (account linking hint)
    try {
      final user = supabase.auth.currentUser;
      final identities = user?.identities ?? [];
      debugPrint(
        'User identities: ${identities.map((i) => i.provider).toList()}',
      );
    } catch (e) {
      debugPrint('Identity check error: $e');
    }

    // 3. Persist session locally
    await _persistSession(response.session);

    // 4. Update FCM token if available
    try {
      final fcmToken = FcmService.token;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await supabase
            .from('profiles')
            .update({
              'fcm_token': fcmToken,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('FCM token sync error: $e');
    }

    return UserModel(
      id: userId,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  static Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? dateOfBirth,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    Map<String, dynamic>? emergencyContact,
    String? preferredLanguage,
    String? themePreference,
    String? accentColor,
  }) async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) {
      throw AppAuthException(_signInRequired);
    }

    final updates = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
    if (bloodType != null) updates['blood_type'] = bloodType;
    if (allergies != null) updates['allergies'] = allergies;
    if (chronicConditions != null) {
      updates['chronic_conditions'] = chronicConditions;
    }
    if (emergencyContact != null) {
      updates['emergency_contact'] = emergencyContact;
    }
    if (preferredLanguage != null) {
      updates['preferred_language'] = preferredLanguage;
    }
    if (themePreference != null) updates['theme_preference'] = themePreference;
    if (accentColor != null) updates['accent_color'] = accentColor;

    try {
      await supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AppAuthException(_withDetail(const {
        'tr': 'Profil güncellenemedi', 'en': 'Could not update the profile',
        'nl': 'Het profiel kon niet worden bijgewerkt',
        'fr': 'Le profil n’a pas pu être mis à jour',
      }, e));
    }

    // Auth kullanıcı metadata'sını da güncelle — uygulamanın çoğu yeri avatarı/
    // ismi currentUser.userMetadata'dan okuyor; yoksa kendi fotoğrafın/adın
    // güncellenmiş görünmez (senkron sorunu).
    try {
      final meta = <String, dynamic>{};
      if (displayName != null) meta['display_name'] = displayName;
      if (avatarUrl != null) meta['avatar_url'] = avatarUrl;
      if (phone != null) meta['phone'] = phone;
      if (meta.isNotEmpty) {
        await supabase.auth.updateUser(UserAttributes(data: meta));
      }
    } catch (e) {
      // Metadata güncellenemese de profiles yazıldı — kritik değil.
    }
  }

  /// Kullanıcının backend'deki dil tercihi kodu (tr/en/nl/fr) — yoksa null.
  /// Best-effort: giriş yoksa veya hata olursa null döner.
  static Future<String?> fetchPreferredLanguage() async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return null;
    try {
      final row = await supabase
          .from('profiles')
          .select('preferred_language')
          .eq('id', userId)
          .maybeSingle();
      final v = row?['preferred_language'];
      return (v is String && v.isNotEmpty) ? v : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw AppAuthException(_signInRequired);
    }

    // Re-authenticate with current password (Supabase requires recent login for password change)
    try {
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } catch (_) {
      throw AppAuthException(_text(const {
        'tr': 'Mevcut şifre hatalı', 'en': 'The current password is incorrect',
        'nl': 'Het huidige wachtwoord is onjuist',
        'fr': 'Le mot de passe actuel est incorrect',
      }));
    }

    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AppAuthException(_withDetail(const {
        'tr': 'Şifre güncellenemedi', 'en': 'Could not update the password',
        'nl': 'Het wachtwoord kon niet worden bijgewerkt',
        'fr': 'Le mot de passe n’a pas pu être mis à jour',
      }, e));
    }
  }

  static Future<void> resetPassword(String email) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  // ── Security Questions ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSecurityQuestionsByEmail(
    String email,
  ) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);

    final response = await supabase
        .from('profiles')
        .select('security_question_1, security_question_2')
        .eq('email', email.trim())
        .maybeSingle();

    return response;
  }

  static Future<bool> verifySecurityAnswers(
    String email,
    String answer1,
    String answer2,
  ) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);

    try {
      final result = await supabase.rpc(
        'verify_security_answers',
        params: {
          'p_email': email.trim(),
          'p_answer1': answer1.trim(),
          'p_answer2': answer2.trim(),
        },
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMySecurityQuestions() async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) {
      throw AppAuthException(_signInRequired);
    }

    return await supabase
        .from('profiles')
        .select('security_question_1, security_question_2')
        .eq('id', userId)
        .maybeSingle();
  }

  static Future<void> updateSecurityQuestions({
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) {
      throw AppAuthException(_signInRequired);
    }

    try {
      await supabase.rpc(
        'update_security_questions',
        params: {
          'p_user_id': userId,
          'p_question1': question1.trim(),
          'p_answer1': answer1.trim(),
          'p_question2': question2.trim(),
          'p_answer2': answer2.trim(),
        },
      );
    } catch (e) {
      throw AppAuthException(_withDetail(const {
        'tr': 'Güvenlik soruları kaydedilemedi',
        'en': 'Could not save the security questions',
        'nl': 'De beveiligingsvragen konden niet worden opgeslagen',
        'fr': 'Les questions de sécurité n’ont pas pu être enregistrées',
      }, e));
    }
  }

  /// Attempts to reset password after security-question verification.
  /// Because Supabase Auth requires a logged-in session to update a password,
  /// this first tries an Edge Function (if deployed); otherwise it falls back
  /// to sending a reset-email link.
  static Future<void> resetPasswordForEmailWithVerification(
    String email,
    String newPassword,
  ) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException(_serverUnavailable);

    // Edge Function is the only way to change a password without a session.
    // If it is not deployed, we fall back to the standard reset-email flow.
    try {
      final response = await supabase.functions.invoke(
        'reset-password-secure',
        body: {'email': email.trim(), 'newPassword': newPassword},
      );
      if (response.status != 200) {
        throw AppAuthException(
          // ignore: avoid_dynamic_calls
          response.data?['error']?.toString() ??
              _text(const {
                'tr': 'Şifre değiştirilemedi',
                'en': 'The password could not be changed',
                'nl': 'Het wachtwoord kon niet worden gewijzigd',
                'fr': 'Le mot de passe n’a pas pu être modifié',
              }),
        );
      }
    } on FunctionException catch (_) {
      // Edge Function not deployed → fallback to email link
      await supabase.auth.resetPasswordForEmail(email.trim());
      throw AppAuthException(
        _text(const {
          'tr': 'Uygulama içi şifre değiştirme için Edge Function kurulması gerekiyor. Şifre sıfırlama bağlantısı e-postanıza gönderildi.',
          'en': 'The Edge Function must be deployed to change passwords in the app. A password reset link was sent to your email.',
          'nl': 'De Edge Function moet worden geïmplementeerd om wachtwoorden in de app te wijzigen. Er is een resetlink naar je e-mailadres gestuurd.',
          'fr': 'La fonction Edge doit être déployée pour modifier le mot de passe dans l’application. Un lien de réinitialisation a été envoyé à votre adresse e-mail.',
        }),
      );
    }
  }

  static Future<bool> isPremium() async {
    // Admin bypass
    if (await isAdmin()) return true;

    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return false;

    try {
      final response = await supabase
          .from('profiles')
          .select('is_premium, subscription_tier, subscription_expires_at')
          .eq('id', userId)
          .maybeSingle();

      // Check subscription tier first
      final tier = response?['subscription_tier']?.toString();
      if (tier == 'premium' || tier == 'family') {
        // Check expiry
        final expiresAt = response?['subscription_expires_at'];
        if (expiresAt != null) {
          final expiry = DateTime.tryParse(expiresAt.toString());
          if (expiry != null && expiry.isBefore(DateTime.now())) {
            return false; // Subscription expired
          }
        }
        return true;
      }

      // Fallback to legacy is_premium flag
      return response?['is_premium'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final supabase = client;
    if (supabase == null) return false;

    try {
      final response = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();
      return response?['is_admin'] == true;
    } catch (e) {
      debugPrint('isAdmin check error: $e');
      return false;
    }
  }

  /// DEPRECATED: Use PaymentService.presentPaymentSheet() or
  /// SubscriptionService.purchasePackage() instead.
  /// This method no longer allows free premium upgrades.
  static Future<void> upgradeToPremium() async {
    throw AppAuthException(_text(const {
      'tr': 'Premium’u etkinleştirmek için ödeme yapmalısınız. Lütfen ödeme ekranından devam edin.',
      'en': 'You must complete payment to activate Premium. Please continue from the payment screen.',
      'nl': 'Je moet betalen om Premium te activeren. Ga verder via het betaalscherm.',
      'fr': 'Vous devez effectuer le paiement pour activer Premium. Veuillez continuer depuis l’écran de paiement.',
    }));
  }

  static String get _serverUnavailable => _text(const {
        'tr': 'Sunucu bağlantısı kurulmadı',
        'en': 'Could not connect to the server',
        'nl': 'Kan geen verbinding maken met de server',
        'fr': 'Impossible de se connecter au serveur',
      });

  static String get _signInRequired => _text(const {
        'tr': 'Giriş yapmalısınız', 'en': 'You must sign in',
        'nl': 'Je moet inloggen', 'fr': 'Vous devez vous connecter',
      });

  static String get _invalidCredentials => _text(const {
        'tr': 'E-posta adresi veya parola hatalı.',
        'en': 'The email address or password is incorrect.',
        'nl': 'Het e-mailadres of wachtwoord is onjuist.',
        'fr': 'L’adresse e-mail ou le mot de passe est incorrect.',
      });

  static String get _myFamily => _text(const {
        'tr': 'Ailem', 'en': 'My Family', 'nl': 'Mijn gezin', 'fr': 'Ma famille',
      });

  static String get _me => _text(const {
        'tr': 'Ben', 'en': 'Me', 'nl': 'Ik', 'fr': 'Moi',
      });

  static String _familyName(String name) => _text({
        'tr': '$name Ailesi',
        'en': '$name Family',
        'nl': 'Gezin $name',
        'fr': 'Famille $name',
      });

  static Future<void> _persistSession(Session? session) async {
    if (session != null) {
      await _secureStorage.write(key: _sessionKey, value: session.refreshToken);
    }
  }

  static void dispose() {
    _authSub?.cancel();
    _authSub = null;
    _authListenerInitialized = false;
  }
}

// Riverpod provider for auth state
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.authStateChanges ?? const Stream.empty();
});

final authUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session != null,
    loading: () => false,
    error: (_, _) => false,
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return AuthService.currentUser;
});

final isPremiumProvider = FutureProvider<bool>((ref) async {
  return AuthService.isPremium();
});
