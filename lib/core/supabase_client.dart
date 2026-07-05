import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SupabaseConfig {
  static SupabaseClient? _client;
  static StreamSubscription<AuthState>? _authSub;

  static SupabaseClient? get safeClient {
    try {
      _client ??= Supabase.instance.client;
      return _client;
    } catch (_) {
      return null;
    }
  }

  static SupabaseClient get client {
    final safe = safeClient;
    if (safe != null) return safe;
    throw StateError('Supabase not initialized — call Supabase.initialize() first');
  }

  static GoTrueClient get auth => client.auth;
  static RealtimeClient get realtime => client.realtime;

  static bool get isAuthenticated => client.auth.currentSession != null;
  static User? get currentUser => client.auth.currentUser;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> persistSession(String sessionString) async {
    await _storage.write(key: 'supabase_session', value: sessionString);
  }

  static Future<String?> getSession() async {
    return await _storage.read(key: 'supabase_session');
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: 'supabase_session');
  }

  /// Initializes auth state listener to clear cached client on sign-out.
  static void initializeListener() {
    _authSub?.cancel();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _client = null;
      }
    });
  }

  /// Disposes the auth listener. Call during app shutdown or tests.
  static void disposeListener() {
    _authSub?.cancel();
    _authSub = null;
  }
}
