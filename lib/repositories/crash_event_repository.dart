// lib/repositories/crash_event_repository.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

import '../domain/models/crash_event.dart';

class CrashEventRepository {
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
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => CrashEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CrashEventRepository.getFamilyEvents error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<CrashEvent>> getMemberEvents(
    String memberId, {
    int limit = 50,
  }) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => CrashEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CrashEventRepository.getMemberEvents error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<CrashEvent?> getEventById(String eventId) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('id', eventId)
          .maybeSingle();
      if (res == null) return null;
      return CrashEvent.fromJson(res);
    } catch (e) {
      debugPrint('CrashEventRepository.getEventById error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<String> createEvent(CrashEvent event) async {
    try {
      final data = event.toJson()..remove('eventId');
      final res = await _client.from(_table).insert(data).select('id').single();
      return res['id'] as String;
    } catch (e) {
      debugPrint('CrashEventRepository.createEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateEvent(CrashEvent event) async {
    try {
      if (event.eventId == null) return;
      await _client
          .from(_table)
          .update(event.toJson())
          .eq('id', event.eventId!);
    } catch (e) {
      debugPrint('CrashEventRepository.updateEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> markFalsePositive(String eventId) async {
    try {
      await _client
          .from(_table)
          .update({'is_false_positive': true, 'response_status': 'false_alarm'})
          .eq('id', eventId);
    } catch (e) {
      debugPrint('CrashEventRepository.markFalsePositive error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> resolveEvent(String eventId) async {
    try {
      await _client
          .from(_table)
          .update({
            'response_status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId);
    } catch (e) {
      debugPrint('CrashEventRepository.resolveEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
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
      debugPrint('CrashEventRepository.watchFamilyEvents error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }
}
