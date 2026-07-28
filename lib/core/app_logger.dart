import 'package:flutter/foundation.dart';
import 'package:sentry/sentry.dart';

/// Merkezi, HASSAS VERİ SIZDIRMAYAN hata logger'ı (FH-03).
///
/// Neden: kod tabanında "sessiz yutulan" (`catch (_) {}`) hatalar vardı —
/// başarısız işlem teşhis edilemiyor ve kullanıcıya yanlış başarı izlenimi
/// doğuruyordu. Bu logger mevcut Sentry (GlobalErrorHandler) altyapısını
/// GENİŞLETİR; ikinci bir paralel mimari kurmaz.
///
/// Log'a ASLA girmez: token, şifre, tam sağlık kaydı, kesin GPS koordinatı,
/// AI'ya giden aile metni, dosya içeriği. Yalnızca güvenli metadata gider.
class AppLogger {
  AppLogger._();

  /// Log'dan temizlenecek anahtarlar (değer maskelenir).
  static const _sensitiveKeys = {
    'token', 'access_token', 'refresh_token', 'jwt', 'password', 'pin',
    'apikey', 'api_key', 'secret', 'authorization', 'lat', 'lng', 'latitude',
    'longitude', 'coordinates', 'content', 'body', 'note', 'description',
    'diagnosis', 'medication', 'prompt', 'message',
  };

  /// Serbest metinden olası sırları maskeler (savunma amaçlı, son çare).
  /// Güvenlik-kritik: test edilebilir olması için görünür.
  @visibleForTesting
  static String sanitize(String input) => _sanitize(input);

  /// Güvenli metadata haritası (test edilebilir).
  @visibleForTesting
  static Map<String, String> safeContext(Map<String, Object?>? ctx) =>
      _safeContext(ctx);

  static String _sanitize(String input) {
    var s = input;
    // Bearer/JWT benzeri uzun token'lar
    s = s.replaceAll(RegExp(r'(eyJ|sk-|AIza)[A-Za-z0-9._\-]{10,}'), '<redacted>');
    // key=value biçiminde hassas alanlar
    for (final k in _sensitiveKeys) {
      s = s.replaceAll(
        RegExp('($k\\s*[:=]\\s*)([^,\\s}\\)]+)', caseSensitive: false),
        r'$1<redacted>',
      );
    }
    return s;
  }

  /// Güvenli metadata haritası üretir (hassas anahtarlar maskelenir).
  static Map<String, String> _safeContext(Map<String, Object?>? ctx) {
    if (ctx == null) return const {};
    final out = <String, String>{};
    ctx.forEach((k, v) {
      final lower = k.toLowerCase();
      final sensitive = _sensitiveKeys.any((s) => lower.contains(s));
      out[k] = sensitive ? '<redacted>' : _sanitize(v.toString());
    });
    return out;
  }

  /// Yutulmuş/beklenen bir hatayı kaydeder — kullanıcı akışını kesmez ama
  /// hata artık görünmezleşmez.
  ///
  /// [module] ör. 'health', [operation] ör. 'createRecord'.
  static void logError(
    Object error, {
    required String module,
    required String operation,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
    bool report = true,
  }) {
    final safeMsg = _sanitize(error.toString());
    final safeCtx = _safeContext(context);

    if (kDebugMode) {
      debugPrint('[$module/$operation] $safeMsg'
          '${safeCtx.isEmpty ? '' : ' ctx=$safeCtx'}');
    }

    if (report && Sentry.isEnabled) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('module', module);
          scope.setTag('operation', operation);
          for (final e in safeCtx.entries) {
            scope.setContexts(e.key, e.value);
          }
        },
      );
    }
  }

  /// En iyi-çaba (best-effort) işlemler için: hata beklenebilir ve kullanıcı
  /// akışını etkilemez, ama yine de iz bırakır. Sentry'ye GÖNDERMEZ.
  ///
  /// Kullanım: opsiyonel cache okuma, temizlik, telemetri gibi yollar.
  static void logBestEffort(
    Object error, {
    required String module,
    required String operation,
  }) {
    if (kDebugMode) {
      debugPrint('[$module/$operation] best-effort: ${_sanitize(error.toString())}');
    }
  }
}
