import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kullanıcıya gösterilecek net auth durumları. Login ekranı bu türe göre
/// mesaj/renk seçer; teknik exception metni ASLA doğrudan gösterilmez.
enum AuthFailureKind {
  offline,
  serverUnavailable,
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  cancelled,
  configurationError,
  sessionMissing,
  unknown,
}

/// Sınıflandırılmış, kullanıcı-dostu auth hatası. Ham exception'ı sarmalar;
/// `userMessage` UI'da gösterilir, `debugDetail` yalnızca debug logunda kalır.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.userMessage, {this.code, this.debugDetail});

  final AuthFailureKind kind;
  final String userMessage;

  /// Ham hata kodu/statusCode (varsa) — yalnızca teşhis içindir.
  final String? code;

  /// Debug logu için ek teknik ayrıntı (token/secret İÇERMEZ).
  final String? debugDetail;

  /// Kullanıcının akışı bilinçli iptal etmesi — kırmızı hata olarak gösterilmez.
  bool get isCancellation => kind == AuthFailureKind.cancelled;

  @override
  String toString() => userMessage;
}

/// Yeniden denenmesi güvenli olan durumlar: geçici ağ, TLS handshake, timeout
/// ve geçici 5xx. Yanlış parola, iptal, yapılandırma hatası retry EDİLMEZ.
bool isRetryableKind(AuthFailureKind kind) =>
    kind == AuthFailureKind.offline ||
    kind == AuthFailureKind.serverUnavailable;

/// Ham hatayı [AuthFailure]'a dönüştürür. Saf fonksiyon — test edilebilir,
/// yan etkisi yoktur.
AuthFailure classifyAuthError(Object error) {
  // Zaten sınıflandırılmışsa aynen döndür.
  if (error is AuthFailure) return error;

  // ── Supabase / GoTrue ────────────────────────────────────────────────
  // Geçici fetch hatası (ağ/5xx) — retry edilebilir.
  if (error is AuthRetryableFetchException) {
    return const AuthFailure(
      AuthFailureKind.serverUnavailable,
      'Giriş servisine şu anda ulaşılamıyor. Lütfen tekrar deneyin.',
      code: 'auth_retryable_fetch',
    );
  }

  if (error is AuthApiException) {
    final status = error.statusCode;
    final code = error.code;
    final msg = error.message.toLowerCase();

    if (msg.contains('email not confirmed') || code == 'email_not_confirmed') {
      return AuthFailure(
        AuthFailureKind.emailNotConfirmed,
        'Devam etmek için e-posta adresinizi doğrulayın.',
        code: code ?? status,
      );
    }
    if (status == '429' ||
        code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit' ||
        msg.contains('rate limit')) {
      return AuthFailure(
        AuthFailureKind.rateLimited,
        'Çok fazla giriş denemesi yapıldı. Bir süre sonra tekrar deneyin.',
        code: code ?? status,
      );
    }
    // 400/401 → geçersiz kimlik bilgileri (retry edilmez).
    if (status == '400' ||
        status == '401' ||
        code == 'invalid_credentials' ||
        msg.contains('invalid login')) {
      return AuthFailure(
        AuthFailureKind.invalidCredentials,
        'E-posta adresi veya parola hatalı.',
        code: code ?? status,
      );
    }
    // 5xx → geçici sunucu hatası (retry edilebilir).
    final statusNum = int.tryParse(status ?? '');
    if (statusNum != null && statusNum >= 500) {
      return AuthFailure(
        AuthFailureKind.serverUnavailable,
        'Giriş servisine şu anda ulaşılamıyor. Lütfen tekrar deneyin.',
        code: status,
      );
    }
    return AuthFailure(
      AuthFailureKind.unknown,
      'E-posta adresi veya parola hatalı.',
      code: code ?? status,
    );
  }

  if (error is AuthSessionMissingException) {
    return const AuthFailure(
      AuthFailureKind.sessionMissing,
      'Oturumunuz bulunamadı. Lütfen tekrar giriş yapın.',
      code: 'session_missing',
    );
  }

  // ── Ağ / TLS / timeout ───────────────────────────────────────────────
  if (error is SocketException) {
    return const AuthFailure(
      AuthFailureKind.offline,
      'İnternet bağlantısı bulunamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      code: 'socket',
    );
  }
  if (error is HandshakeException) {
    return const AuthFailure(
      AuthFailureKind.serverUnavailable,
      'Giriş servisine güvenli bağlantı kurulamadı. Lütfen tekrar deneyin.',
      code: 'tls_handshake',
    );
  }
  if (error is TimeoutException) {
    return const AuthFailure(
      AuthFailureKind.serverUnavailable,
      'Giriş servisine şu anda ulaşılamıyor. Lütfen tekrar deneyin.',
      code: 'timeout',
    );
  }

  // ── Google Sign-In (native PlatformException) ────────────────────────
  if (error is PlatformException) {
    return _classifyPlatformException(error);
  }

  // ── Son çare: mesajdan çıkarım ───────────────────────────────────────
  final text = error.toString().toLowerCase();
  if (text.contains('iptal') || text.contains('cancel')) {
    return const AuthFailure(AuthFailureKind.cancelled, '', code: 'cancelled');
  }
  if (text.contains('socket') ||
      text.contains('failed host lookup') ||
      text.contains('network') ||
      text.contains('connection')) {
    return const AuthFailure(
      AuthFailureKind.offline,
      'İnternet bağlantısı bulunamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      code: 'network',
    );
  }
  return const AuthFailure(
    AuthFailureKind.unknown,
    'Giriş yapılamadı. Lütfen tekrar deneyin.',
    code: 'unknown',
  );
}

AuthFailure _classifyPlatformException(PlatformException e) {
  final code = e.code.toLowerCase();
  final msg = (e.message ?? '').toLowerCase();

  // Kullanıcı hesap seçimini/izni iptal etti — sessizce normal duruma dön.
  if (code.contains('cancel') ||
      code == '12501' ||
      msg.contains('cancel') ||
      msg.contains('12501')) {
    return const AuthFailure(
      AuthFailureKind.cancelled,
      '',
      code: 'sign_in_canceled',
    );
  }
  // Google Play Services / ağ hatası — geçici, retry edilebilir.
  if (code == '7' || code == 'network_error' || msg.contains('network')) {
    return const AuthFailure(
      AuthFailureKind.offline,
      'İnternet bağlantısı bulunamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      code: 'network_error',
    );
  }
  // DEVELOPER_ERROR (code 10) veya sign_in_failed → yapılandırma hatası.
  // SHA/Client ID/paket adı uyuşmazlığı. RETRY İLE GİZLENMEZ.
  if (code == '10' ||
      code == 'developer_error' ||
      code == 'sign_in_failed' ||
      msg.contains('developer_error')) {
    return AuthFailure(
      AuthFailureKind.configurationError,
      'Google ile giriş şu anda yapılandırılamadı. Lütfen e-posta ile giriş yapın.',
      code: 'developer_error(${e.code})',
    );
  }
  return AuthFailure(
    AuthFailureKind.configurationError,
    'Google ile giriş tamamlanamadı. Lütfen tekrar deneyin veya e-posta ile girin.',
    code: e.code,
  );
}

/// Auth hatasını GÜVENLİ biçimde loglar. Parola, token, key ASLA loglanmaz;
/// yalnızca hata tipi/kodu/işlem/retry/ağ durumu.
void logAuthError({
  required String operation,
  required Object error,
  int retryCount = 0,
  bool? online,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;
  final f = classifyAuthError(error);
  debugPrint(
    '[auth] op=$operation kind=${f.kind.name} code=${f.code ?? '-'} '
    'retry=$retryCount online=${online ?? '?'} type=${error.runtimeType}',
  );
  if (stackTrace != null) debugPrint(stackTrace.toString());
}

/// Yalnızca retry edilebilir (geçici ağ/TLS/timeout/5xx) hatalarda en fazla
/// [maxRetries] kez, kontrollü backoff ile [action]'ı tekrar dener.
/// Sonsuz retry veya recursive login YAPMAZ. İlk retryable-olmayan hatada
/// hemen [AuthFailure] fırlatır.
Future<T> retryAuth<T>(
  Future<T> Function() action, {
  String operation = 'auth',
  int maxRetries = 2,
  List<Duration> delays = const [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
  ],
  Future<void> Function(Duration) sleep = _defaultSleep,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (error, st) {
      final failure = classifyAuthError(error);
      final canRetry = isRetryableKind(failure.kind) && attempt < maxRetries;
      logAuthError(
        operation: operation,
        error: error,
        retryCount: attempt,
        stackTrace: canRetry ? null : st,
      );
      if (!canRetry) throw failure;
      final delay = attempt < delays.length ? delays[attempt] : delays.last;
      attempt++;
      await sleep(delay);
    }
  }
}

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);
