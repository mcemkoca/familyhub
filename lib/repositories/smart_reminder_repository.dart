import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/smart_reminder.dart';
import '../services/auth_service.dart';

class SmartReminderRepository with RepositoryErrorHandler {
  static final SmartReminderRepository _instance =
      SmartReminderRepository._internal();
  factory SmartReminderRepository() => _instance;
  SmartReminderRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  String get _table => 'smart_reminders';

  Future<List<SmartReminder>> getReminders(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => SmartReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getReminders');
  }

  Future<List<SmartReminder>> getActiveReminders(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      final all = (response as List)
          .map((e) => SmartReminder.fromJson(e as Map<String, dynamic>))
          .toList();
      return all.where((r) => r.status.state == ReminderState.active).toList();
    }, 'getActiveReminders');
  }

  Future<SmartReminder> getById(String id) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('id', id)
          .single();
      return SmartReminder.fromJson(response);
    }, 'getById');
  }

  Future<SmartReminder> create(SmartReminder reminder) async {
    return handleRepositoryCall(() async {
      final data = reminder.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return SmartReminder.fromJson(response);
    }, 'create');
  }

  Future<SmartReminder> update(SmartReminder reminder) async {
    return handleRepositoryCall(() async {
      final data = reminder.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('created_by')
        ..remove('family_id');
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', reminder.id)
          .select()
          .single();
      return SmartReminder.fromJson(response);
    }, 'update');
  }

  Future<void> delete(String id) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).delete().eq('id', id);
    }, 'delete');
  }

  Stream<List<SmartReminder>> watchReminders(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) => data.map((e) => SmartReminder.fromJson(e)).toList());
    } catch (e) {
      debugPrint('SmartReminderRepository.watchReminders error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchReminders]: $e'));
    }
  }

  Future<void> updateStatus(String id, ReminderStatus status) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({'status': status.toJson()})
          .eq('id', id);
    }, 'updateStatus');
  }
}
