import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../core/sentry_config.dart';

/// Global error handling, logging, and crash reporting.
class ErrorService {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      SentryConfig.captureException(details.exception, stackTrace: details.stack);
      FlutterError.presentError(details);
    };

    // Catch async zone errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      SentryConfig.captureException(error, stackTrace: stack);
      return true;
    };
  }

  static void log(String message, {Map<String, dynamic>? extras}) {
    // Non-fatal log to Crashlytics
    FirebaseCrashlytics.instance.log(message);
    if (extras != null) {
      for (final entry in extras.entries) {
        FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
      }
    }
  }

  static Future<void> recordError(dynamic exception, StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
    await SentryConfig.captureException(exception, stackTrace: stack);
  }
}
