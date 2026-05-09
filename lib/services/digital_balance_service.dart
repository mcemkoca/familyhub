import 'dart:io';
import 'package:flutter/services.dart';

/// Tracks device app usage for digital wellbeing (Android only).
/// Requires PACKAGE_USAGE_STATS permission and Android UsageStats API.
class DigitalBalanceService {
  static const _channel = MethodChannel('com.familyhub/digital_balance');

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod('requestPermission') as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getTodayUsage() async {
    if (!Platform.isAndroid) return {};
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>('getTodayUsage');
      return result ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Duration> getTotalScreenTime() async {
    final usage = await getTodayUsage();
    final totalMs = usage['totalMs'] as int? ?? 0;
    return Duration(milliseconds: totalMs);
  }

  static Future<List<Map<String, dynamic>>> getTopApps({int limit = 5}) async {
    final usage = await getTodayUsage();
    final apps = (usage['apps'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    apps.sort((a, b) => (b['usageMs'] as int? ?? 0).compareTo(a['usageMs'] as int? ?? 0));
    return apps.take(limit).toList();
  }
}
