import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/reminder_interaction.dart';
import '../services/auth_service.dart';

class ReminderInteractionRepository with RepositoryErrorHandler {
  static final ReminderInteractionRepository _instance =
      ReminderInteractionRepository._internal();
  factory ReminderInteractionRepository() => _instance;
  ReminderInteractionRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  String get _table => 'reminder_interactions';

  Future<List<ReminderInteraction>> getInteractionsForReminder(
    String reminderId, {
    int limit = 100,
  }) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('reminder_id', reminderId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ReminderInteraction.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getInteractionsForReminder');
  }

  Future<List<ReminderInteraction>> getRecentInteractions(
    String reminderId, {
    int days = 30,
  }) async {
    return handleRepositoryCall(() async {
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();
      final response = await _client
          .from(_table)
          .select('*')
          .eq('reminder_id', reminderId)
          .gte('created_at', since)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => ReminderInteraction.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getRecentInteractions');
  }

  Future<ReminderInteraction> logInteraction(
    ReminderInteraction interaction,
  ) async {
    return handleRepositoryCall(() async {
      final data = interaction.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return ReminderInteraction.fromJson(response);
    }, 'logInteraction');
  }

  Future<Map<String, dynamic>> getAnalytics(String reminderId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .rpc('get_reminder_analytics', params: {'p_reminder_id': reminderId})
          .maybeSingle();
      return response ?? {};
    }, 'getAnalytics');
  }
}
