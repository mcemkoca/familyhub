// lib/repositories/crash_event_repository.dart

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';

import '../domain/models/crash_event.dart';

class CrashEventRepository with RepositoryErrorHandler {
  static final CrashEventRepository _instance =
      CrashEventRepository._internal();
  factory CrashEventRepository() => _instance;
  CrashEventRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  String get _table => 'crash_events';

  Future<List<CrashEvent>> getFamilyEvents(
    String familyId, {
    int limit = 50,
  }) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from(_table)
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => CrashEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getFamilyEvents');
  }

  Future<List<CrashEvent>> getMemberEvents(
    String memberId, {
    int limit = 50,
  }) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from(_table)
          .select()
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => CrashEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getMemberEvents');
  }

  Future<CrashEvent?> getEventById(String eventId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from(_table)
          .select()
          .eq('id', eventId)
          .maybeSingle();
      if (res == null) return null;
      return CrashEvent.fromJson(res);
    }, 'getEventById');
  }

  Future<String> createEvent(CrashEvent event) async {
    return handleRepositoryCall(() async {
      final data = event.toJson()..remove('eventId');
      final res = await _client.from(_table).insert(data).select('id').single();
      return res['id'] as String;
    }, 'createEvent');
  }

  Future<void> updateEvent(CrashEvent event) async {
    return handleRepositoryCall(() async {
      if (event.eventId == null) return;
      await _client
          .from(_table)
          .update(event.toJson())
          .eq('id', event.eventId!);
    }, 'updateEvent');
  }

  Future<void> markFalsePositive(String eventId) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({'is_false_positive': true, 'response_status': 'false_alarm'})
          .eq('id', eventId);
    }, 'markFalsePositive');
  }

  Future<void> resolveEvent(String eventId) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({
            'response_status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId);
    }, 'resolveEvent');
  }

  Stream<List<CrashEvent>> watchFamilyEvents(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .map((data) => data.map((e) => CrashEvent.fromJson(e)).toList());
    } catch (e) {
      return Stream.error(RepositoryException('Beklenmeyen hata [watchFamilyEvents]: $e'));
    }
  }
}
