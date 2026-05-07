import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/reminder_interaction.dart';
import '../services/auth_service.dart';

class ReminderInteractionRepository {
  static final ReminderInteractionRepository _instance = ReminderInteractionRepository._internal();
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
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('reminder_id', reminderId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ReminderInteraction.fromJson(e))
          .toList();
    } catch (e, st) {
      debugPrint('[ReminderInteractionRepository.getInteractionsForReminder] error: $e');
      rethrow;
    }
  }

  Future<List<ReminderInteraction>> getRecentInteractions(
    String reminderId, {
    int days = 30,
  }) async {
    try {
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
          .map((e) => ReminderInteraction.fromJson(e))
          .toList();
    } catch (e, st) {
      debugPrint('[ReminderInteractionRepository.getRecentInteractions] error: $e');
      rethrow;
    }
  }

  Future<ReminderInteraction> logInteraction(
    ReminderInteraction interaction,
  ) async {
    try {
      final data = interaction.toJson()..remove('id');
      final response = await _client.from(_table).insert(data).select().single();
      return ReminderInteraction.fromJson(response);
    } catch (e, st) {
      debugPrint('[ReminderInteractionRepository.logInteraction] error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnalytics(String reminderId) async {
    try {
      final response = await _client
          .rpc('get_reminder_analytics', params: {'p_reminder_id': reminderId})
          .single();
      return response;
    } catch (e, st) {
      debugPrint('[ReminderInteractionRepository.getAnalytics] error: $e');
      rethrow;
    }
  }
}
