import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry/sentry.dart';

/// Sentry DSN should be provided via dart-define or .env in production.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

class SentryConfig {
  static bool get isEnabled => _sentryDsn.isNotEmpty && kReleaseMode;

  static Future<void> init(FutureOr<void> Function() appRunner) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }

    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      // Ignore if package_info fails
    }

    await Sentry.init(
      (options) {
        options.dsn = _sentryDsn;
        options.environment = const String.fromEnvironment(
          'ENV',
          defaultValue: 'production',
        );
        options.release = packageInfo != null
            ? '${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}'
            : null;
        options.dist = packageInfo?.buildNumber;

        // Performance
        options.tracesSampleRate = 0.2;
        options.attachStacktrace = true;
        options.diagnosticLevel = SentryLevel.warning;

        // PII scrubbing
        options.beforeSend = (event, hint) {
          event.breadcrumbs?.forEach((crumb) {
            if (crumb.message != null) {
              crumb.message = crumb.message!.replaceAll(
                RegExp(r'[\w.-]+@[\w.-]+\.\w+'),
                '[EMAIL]',
              );
            }
          });

          (event.contexts['secrets'] as Map<String, dynamic>?)?.clear();
          final tags = event.tags ?? {};
          tags.remove('password');
          tags.remove('token');
          tags.remove('phone');

          return event;
        };
      },
      appRunner: appRunner,
    );
  }

  static void setUserContext(String userId, String? email) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email != null ? _hashEmail(email) : null,
      ));
    });
  }

  static String _hashEmail(String email) {
    final bytes = utf8.encode(email);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
    );
  }

  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureMessage(message, level: level);
  }
}
