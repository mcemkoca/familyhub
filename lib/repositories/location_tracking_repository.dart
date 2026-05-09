// lib/repositories/location_tracking_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

import '../domain/models/location_tracking.dart';

class LocationTrackingRepository {
  static final LocationTrackingRepository _instance =
      LocationTrackingRepository._internal();
  factory LocationTrackingRepository() => _instance;
  LocationTrackingRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  // ── Settings ──
  Future<LocationTrackingSettings?> getSettings(String memberId) async {
    try {
      final res = await _client
          .from('location_tracking_settings')
          .select()
          .eq('member_id', memberId)
          .maybeSingle();
      if (res == null) return null;
      return LocationTrackingSettings.fromJson(res);
    } catch (e) {
      debugPrint('[LocationTrackingRepository.getSettings] error: $e');
      rethrow;
    }
  }

  Future<void> upsertSettings(LocationTrackingSettings settings) async {
    try {
      final existing = await getSettings(settings.memberId);
      if (existing == null) {
        await _client
            .from('location_tracking_settings')
            .insert(settings.toJson());
      } else {
        await _client
            .from('location_tracking_settings')
            .update(settings.toJson())
            .eq('member_id', settings.memberId);
      }
    } catch (e) {
      debugPrint('[LocationTrackingRepository.upsertSettings] error: $e');
      rethrow;
    }
  }

  // ── Location History ──
  Future<List<LocationBatch>> getMemberHistory(
    String memberId, {
    int limit = 50,
  }) async {
    try {
      final res = await _client
          .from('location_history')
          .select()
          .eq('member_id', memberId)
          .order('recorded_at', ascending: false)
          .limit(limit);
      return (res as List).map((e) => LocationBatch.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[LocationTrackingRepository.getMemberHistory] error: $e');
      rethrow;
    }
  }

  Future<void> insertBatch(LocationBatch batch) async {
    try {
      await _client.from('location_history').insert(batch.toJson());
    } catch (e) {
      debugPrint('[LocationTrackingRepository.insertBatch] error: $e');
      rethrow;
    }
  }

  // ── Battery Logs ──
  Future<void> insertBatteryLog(BatteryLog log) async {
    try {
      await _client.from('battery_logs').insert(log.toJson());
    } catch (e) {
      debugPrint('[LocationTrackingRepository.insertBatteryLog] error: $e');
      rethrow;
    }
  }

  Future<List<BatteryLog>> getBatteryLogs(
    String memberId, {
    int limit = 100,
  }) async {
    try {
      final res = await _client
          .from('battery_logs')
          .select()
          .eq('member_id', memberId)
          .order('timestamp', ascending: false)
          .limit(limit);
      return (res as List).map((e) => BatteryLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[LocationTrackingRepository.getBatteryLogs] error: $e');
      rethrow;
    }
  }

  // ── Analytics ──
  Future<TrackingAnalytics?> getAnalytics(
    String memberId,
    DateTime date,
  ) async {
    try {
      final res = await _client
          .from('tracking_analytics')
          .select()
          .eq('member_id', memberId)
          .eq('date', date.toIso8601String().substring(0, 10))
          .maybeSingle();
      if (res == null) return null;
      return TrackingAnalytics.fromJson(res);
    } catch (e) {
      debugPrint('[LocationTrackingRepository.getAnalytics] error: $e');
      rethrow;
    }
  }

  Future<void> upsertAnalytics(TrackingAnalytics analytics) async {
    try {
      final dateStr = analytics.date.toIso8601String().substring(0, 10);
      final existing = await _client
          .from('tracking_analytics')
          .select('id')
          .eq('member_id', analytics.memberId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing == null) {
        await _client.from('tracking_analytics').insert(analytics.toJson());
      } else {
        await _client
            .from('tracking_analytics')
            .update(analytics.toJson())
            .eq('id', existing['id']);
      }
    } catch (e) {
      debugPrint('[LocationTrackingRepository.upsertAnalytics] error: $e');
      rethrow;
    }
  }
}
