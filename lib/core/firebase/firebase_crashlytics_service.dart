import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

/// Firebase Crashlytics wrapper for crash reporting and error logging.
class FirebaseCrashlyticsService {
  static final _crashlytics = FirebaseCrashlytics.instance;
  static RawReceivePort? _errorPort;

  static bool get isCrashlyticsEnabled => _crashlytics.isCrashlyticsCollectionEnabled;

  static Future<void> initialize() async {
    final originalFlutterError = FlutterError.onError;
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
      originalFlutterError?.call(errorDetails);
    };

    final originalPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return originalPlatformError?.call(error, stack) ?? false;
    };

    _errorPort?.close();
    _errorPort = RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await _crashlytics.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        fatal: true,
      );
    });
    Isolate.current.addErrorListener(_errorPort!.sendPort);
  }

  static void dispose() {
    _errorPort?.close();
    _errorPort = null;
  }

  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }
}
