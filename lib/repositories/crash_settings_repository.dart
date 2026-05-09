// lib/repositories/crash_settings_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';

import '../domain/models/crash_settings.dart';

class CrashSettingsRepository with RepositoryErrorHandler {
  static final CrashSettingsRepository _instance =
      CrashSettingsRepository._internal();
  factory CrashSettingsRepository() => _instance;
  CrashSettingsRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  String get _table => 'crash_detection_settings';

  Future<CrashDetectionSettings?> getSettings(String memberId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from(_table)
          .select()
          .eq('member_id', memberId)
          .maybeSingle();
      if (res == null) return null;
      return CrashDetectionSettings.fromJson(res);
    }, 'getSettings');
  }

  Future<void> createSettings(CrashDetectionSettings settings) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).insert(settings.toJson());
    }, 'createSettings');
  }

  Future<void> updateSettings(CrashDetectionSettings settings) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update(settings.toJson())
          .eq('member_id', settings.memberId);
    }, 'updateSettings');
  }

  Future<void> upsertSettings(CrashDetectionSettings settings) async {
    return handleRepositoryCall(() async {
      final existing = await getSettings(settings.memberId);
      if (existing == null) {
        await createSettings(settings);
      } else {
        await updateSettings(settings);
      }
    }, 'upsertSettings');
  }
}
