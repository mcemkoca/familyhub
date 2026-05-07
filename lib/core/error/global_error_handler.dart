import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry/sentry.dart';
import '../../core/supabase_client.dart';

/// Global error handling setup for the entire app.
/// Captures Flutter framework errors, platform errors, and async gaps.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static bool _initialized = false;

  /// Call once in `main()` before `runApp()`.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Framework errors (build, layout, paint)
    FlutterError.onError = (details) {
      // Always present the error first so the red screen / logs are visible
      FlutterError.presentError(details);
      // Only report if Sentry is actually initialized
      if (Sentry.isEnabled) {
        _reportError(details.exception, details.stack, 'flutter');
      }
    };

    // Platform / isolate errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (Sentry.isEnabled) {
        _reportError(error, stack, 'platform');
      }
      return false; // let framework show error widget / logs
    };

    // Zone error handler for async gaps
    // Note: This is handled by wrapping runApp in a Zone in main.dart
  }

  /// Wraps an operation in a Zone with error handling.
  static void runWithZone(VoidCallback body) {
    runZonedGuarded(body, (error, stack) {
      _reportError(error, stack, 'zone');
    });
  }

  /// Reports an error to Sentry and Supabase.
  static void _reportError(Object error, StackTrace? stack, String source) {
    // 1. Sentry
    Sentry.captureException(error, stackTrace: stack, withScope: (scope) {
      scope.setTag('error_source', source);
    });

    // 2. Supabase error_logs table (fire-and-forget)
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      final errorStr = _scrubPII(error.toString());
      final stackStr = stack != null ? _scrubPII(stack.toString()) : null;

      client.from('error_logs').insert({
        'error': errorStr,
        'stack': stackStr,
        'source': source,
        'user_id': userId,
        'app_version': _appVersion,
        'timestamp': DateTime.now().toIso8601String(),
      }).ignore();
    } catch (_) {
      // Logging failure should not crash the app
    }
  }

  /// Scrubs PII from error strings before logging.
  static String _scrubPII(String input) {
    // Email regex
    var result = input.replaceAllMapped(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      (match) => '[EMAIL]',
    );
    // Phone regex (Turkish +90 and local formats)
    result = result.replaceAllMapped(
      RegExp(r'\+?90[-\s]?[0-9]{3}[-\s]?[0-9]{3}[-\s]?[0-9]{2}[-\s]?[0-9]{2}|\b[0-9]{3}[-\s]?[0-9]{3}[-\s]?[0-9]{2}[-\s]?[0-9]{2}\b'),
      (match) => '[PHONE]',
    );
    return result;
  }

  static String get _appVersion {
    // Default; ideally populated from package_info_plus
    return '0.1.0+1';
  }
}

// ── Retry Wrapper ───────────────────────────────────────────────────────

/// Retries an async operation with exponential backoff.
///
/// ```dart
/// final data = await withRetry(
///   () => api.fetchData(),
///   maxRetries: 3,
/// );
/// ```
Future<T> withRetry<T>({
  required Future<T> Function() operation,
  int maxRetries = 3,
  Duration baseDelay = const Duration(seconds: 1),
  bool Function(Object error)? retryIf,
}) async {
  var attempt = 0;

  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;

      // Check if we should retry this error
      if (retryIf != null && !retryIf(e)) {
        rethrow;
      }

      if (attempt >= maxRetries) {
        rethrow;
      }

      // Exponential backoff with jitter: delay * 2^attempt + random(0-500ms)
      final delay = baseDelay * (1 << attempt);
      final jitter = Duration(milliseconds: (DateTime.now().millisecond % 500));
      await Future.delayed(delay + jitter);
    }
  }
}
