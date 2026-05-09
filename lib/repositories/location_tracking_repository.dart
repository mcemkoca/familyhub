// lib/repositories/location_tracking_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';

import '../domain/models/location_tracking.dart';

class LocationTrackingRepository with RepositoryErrorHandler {
  static final LocationTrackingRepository _instance =
      LocationTrackingRepository._internal();
  factory LocationTrackingRepository() => _instance;
  LocationTrackingRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  // ── Settings ──
  Future<LocationTrackingSettings?> getSettings(String memberId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('location_tracking_settings')
          .select()
          .eq('member_id', memberId)
          .maybeSingle();
      if (res == null) return null;
      return LocationTrackingSettings.fromJson(res);
    }, 'getSettings');
  }

  Future<void> upsertSettings(LocationTrackingSettings settings) async {
    return handleRepositoryCall(() async {
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
    }, 'upsertSettings');
  }

  // ── Location History ──
  Future<List<LocationBatch>> getMemberHistory(
    String memberId, {
    int limit = 50,
  }) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('location_history')
          .select()
          .eq('member_id', memberId)
          .order('recorded_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => LocationBatch.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getMemberHistory');
  }

  Future<void> insertBatch(LocationBatch batch) async {
    return handleRepositoryCall(() async {
      await _client.from('location_history').insert(batch.toJson());
    }, 'insertBatch');
  }

  // ── Battery Logs ──
  Future<void> insertBatteryLog(BatteryLog log) async {
    return handleRepositoryCall(() async {
      await _client.from('battery_logs').insert(log.toJson());
    }, 'insertBatteryLog');
  }

  Future<List<BatteryLog>> getBatteryLogs(
    String memberId, {
    int limit = 100,
  }) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('battery_logs')
          .select()
          .eq('member_id', memberId)
          .order('timestamp', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => BatteryLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getBatteryLogs');
  }

  // ── Analytics ──
  Future<TrackingAnalytics?> getAnalytics(
    String memberId,
    DateTime date,
  ) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('tracking_analytics')
          .select()
          .eq('member_id', memberId)
          .eq('date', date.toIso8601String().substring(0, 10))
          .maybeSingle();
      if (res == null) return null;
      return TrackingAnalytics.fromJson(res);
    }, 'getAnalytics');
  }

  Future<void> upsertAnalytics(TrackingAnalytics analytics) async {
    return handleRepositoryCall(() async {
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
            .eq('id', existing['id'] as Object);
      }
    }, 'upsertAnalytics');
  }
}
