import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../domain/models/user_model.dart';
import 'fcm_service.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();
  static const _sessionKey = 'supabase_session';

  static SupabaseClient? get safeClient => SupabaseConfig.safeClient;

  static SupabaseClient? get client => SupabaseConfig.safeClient;

  static const _googleWebClientId =
      '631270363894-2c8m0ea0ub83u01ne379cpvc5mp6221d.apps.googleusercontent.com';

  static bool get isGoogleSignInConfigured => true;

  static User? get currentUser => client?.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState>? get authStateChanges =>
      client?.auth.onAuthStateChange;

  static bool _authListenerInitialized = false;
  static StreamSubscription<AuthState>? _authSub;

  static Future<void> initAuthListener() async {
    if (_authListenerInitialized) return;
    _authListenerInitialized = true;
    _authSub = client?.auth.onAuthStateChange.listen((event) async {
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
    });
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
      throw AppAuthException('Geçerli bir e-posta adresi girin');
    }
    if (password.length < 8) {
      throw AppAuthException('Şifre en az 8 karakter olmalı');
    }
    if (name.trim().length < 2) {
      throw AppAuthException('İsim en az 2 karakter olmalı');
    }

    final supabase = client;
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim(), 'family_name': familyName?.trim()},
    );

    if (response.user == null) {
      throw AppAuthException('Kayıt başarısız oldu');
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
      throw AppAuthException('Profil oluşturulamadı: $e');
    }

    // Create family if familyName provided
    String? familyId;
    if (familyName != null && familyName.trim().isNotEmpty) {
      try {
        final familyResponse = await supabase
            .from('families')
            .insert({
              'name': familyName.trim(),
              'created_by': userId,
            })
            .select('id')
            .single();
        familyId = familyResponse['id'] as String?;
      } catch (e) {
        throw AppAuthException('Aile oluşturulamadı: $e');
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
        await supabase.from('profiles').update({
          'family_id': familyId,
        }).eq('id', userId);
      } catch (e) {
        throw AppAuthException('Aile üyeliği oluşturulamadı: $e');
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
      final familyName =
          (name != null && name.isNotEmpty) ? '$name Ailesi' : 'Ailem';

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
        'display_name': name ?? 'Ben',
      });
      await supabase
          .from('profiles')
          .update({'family_id': familyId}).eq('id', userId);
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
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

    final response = await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session == null) {
      throw AppAuthException('E-posta veya şifre hatalı');
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
      throw AppAuthException('Giriş yapmalısınız');
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
      throw AppAuthException('Geçersiz davet kodu');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException('Aileye katılma başarısız: $e');
    }
  }

  static Future<void> signOut() async {
    await _authSub?.cancel();
    _authSub = null;
    _authListenerInitialized = false;
    // Sign out from all auth providers
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
    try {
      await client?.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
    await _secureStorage.delete(key: _sessionKey);
    SupabaseConfig.disposeListener();
  }

  static Future<AuthResponse> signInWithGoogle() async {
    if (!isGoogleSignInConfigured) {
      throw AppAuthException(
        'Google Sign-In şu an yapılandırılmamış. '
        'Lütfen e-posta ve şifre ile giriş yapın.',
      );
    }
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: _googleWebClientId,
    );
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw AppAuthException('Google girişi iptal edildi');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw AppAuthException('Google kimlik doğrulama başarısız');
    }

    final supabase = client;
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    if (response.user == null) {
      throw AppAuthException('Giriş başarısız oldu');
    }

    await syncUserPostLogin(response);
    return response;
  }

  /// Synchronizes user profile, local cache, and FCM token after any login.
  static Future<UserModel> syncUserPostLogin(AuthResponse response) async {
    final supabase = client;
    final user = response.user;
    if (supabase == null || user == null) {
      throw AppAuthException('Oturum bulunamadı');
    }

    final userId = user.id;
    final email = user.email ?? '';
    final displayName = user.userMetadata?['display_name'] as String? ??
        email.split('@').first;
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
      debugPrint('User identities: ${identities.map((i) => i.provider).toList()}');
    } catch (e) {
      debugPrint('Identity check error: $e');
    }

    // 3. Persist session locally
    await _persistSession(response.session);

    // 4. Update FCM token if available
    try {
      final fcmToken = FcmService.token;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await supabase.from('profiles').update({
          'fcm_token': fcmToken,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
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
      throw AppAuthException('Giriş yapmalısınız');
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
    if (chronicConditions != null) updates['chronic_conditions'] = chronicConditions;
    if (emergencyContact != null) updates['emergency_contact'] = emergencyContact;
    if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;
    if (themePreference != null) updates['theme_preference'] = themePreference;
    if (accentColor != null) updates['accent_color'] = accentColor;

    try {
      await supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw AppAuthException('Profil güncellenemedi: $e');
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

  static Future<void> updatePassword(String currentPassword, String newPassword) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) {
      throw AppAuthException('Giriş yapmalısınız');
    }

    // Re-authenticate with current password (Supabase requires recent login for password change)
    try {
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } catch (_) {
      throw AppAuthException('Mevcut şifre hatalı');
    }

    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AppAuthException('Şifre güncellenemedi: $e');
    }
  }

  static Future<void> resetPassword(String email) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  // ── Security Questions ───────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSecurityQuestionsByEmail(String email) async {
    final supabase = client;
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

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
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

    try {
      final result = await supabase.rpc('verify_security_answers', params: {
        'p_email': email.trim(),
        'p_answer1': answer1.trim(),
        'p_answer2': answer2.trim(),
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMySecurityQuestions() async {
    final supabase = client;
    final userId = currentUserId;
    if (supabase == null || userId == null) {
      throw AppAuthException('Giriş yapmalısınız');
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
      throw AppAuthException('Giriş yapmalısınız');
    }

    try {
      await supabase.rpc('update_security_questions', params: {
        'p_user_id': userId,
        'p_question1': question1.trim(),
        'p_answer1': answer1.trim(),
        'p_question2': question2.trim(),
        'p_answer2': answer2.trim(),
      });
    } catch (e) {
      throw AppAuthException('Güvenlik soruları kaydedilemedi: $e');
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
    if (supabase == null) throw AppAuthException('Sunucu bağlantısı kurulmadı');

    // Edge Function is the only way to change a password without a session.
    // If it is not deployed, we fall back to the standard reset-email flow.
    try {
      final response = await supabase.functions.invoke(
        'reset-password-secure',
        body: {
          'email': email.trim(),
          'newPassword': newPassword,
        },
      );
      if (response.status != 200) {
        throw AppAuthException(
          // ignore: avoid_dynamic_calls
          response.data?['error']?.toString() ?? 'Şifre değiştirilemedi',
        );
      }
    } on FunctionException catch (_) {
      // Edge Function not deployed → fallback to email link
      await supabase.auth.resetPasswordForEmail(email.trim());
      throw AppAuthException(
        'Uygulama içi şifre değiştirme için Edge Function deploy edilmesi gerekiyor. '
        'Şifre sıfırlama bağlantısı e-postanıza gönderildi.',
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
    throw AppAuthException(
      'Premium aktifleştirme için ödeme yapmalısınız. '
      'Lütfen ödeme ekranından devam edin.',
    );
  }

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
