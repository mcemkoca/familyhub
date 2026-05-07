// lib/repositories/crash_settings_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

import '../domain/models/crash_settings.dart';

class CrashSettingsRepository {
  static final CrashSettingsRepository _instance = CrashSettingsRepository._internal();
  factory CrashSettingsRepository() => _instance;
  CrashSettingsRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  String get _table => 'crash_detection_settings';

  Future<CrashDetectionSettings?> getSettings(String memberId) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('member_id', memberId)
          .maybeSingle();
      if (res == null) return null;
      return CrashDetectionSettings.fromJson(res);
    } catch (e, st) {
      debugPrint('[CrashSettingsRepository.getSettings] error: $e');
      rethrow;
    }
  }

  Future<void> createSettings(CrashDetectionSettings settings) async {
    try {
      await _client.from(_table).insert(settings.toJson());
    } catch (e, st) {
      debugPrint('[CrashSettingsRepository.createSettings] error: $e');
      rethrow;
    }
  }

  Future<void> updateSettings(CrashDetectionSettings settings) async {
    try {
      await _client
          .from(_table)
          .update(settings.toJson())
          .eq('member_id', settings.memberId);
    } catch (e, st) {
      debugPrint('[CrashSettingsRepository.updateSettings] error: $e');
      rethrow;
    }
  }

  Future<void> upsertSettings(CrashDetectionSettings settings) async {
    try {
      final existing = await getSettings(settings.memberId);
      if (existing == null) {
        await createSettings(settings);
      } else {
        await updateSettings(settings);
      }
    } catch (e, st) {
      debugPrint('[CrashSettingsRepository.upsertSettings] error: $e');
      rethrow;
    }
  }
}
