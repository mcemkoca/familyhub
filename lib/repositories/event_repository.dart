import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class EventRepository with RepositoryErrorHandler {
  static final EventRepository _instance = EventRepository._internal();
  factory EventRepository() => _instance;
  EventRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  final String _table = 'events';

  Future<List<CalendarEvent>> getEvents(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('start_time', ascending: true);
      return (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    }, 'getEvents');
  }

  Future<CalendarEvent> createEvent(
    CalendarEvent event,
    String familyId,
  ) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final response = await _client
          .from(_table)
          .insert({
            'family_id': familyId,
            'title': event.title,
            'start_time': event.start.toIso8601String(),
            'end_time': event.end.toIso8601String(),
            'location': event.location,
            'description': event.description,
            'category': event.category.name,
            'is_all_day': event.isAllDay,
            'reminders': event.reminders,
            'created_by': userId,
          })
          .select()
          .single();

      return _fromJson(response);
    }, 'createEvent');
  }

  Future<void> updateEvent(CalendarEvent event) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({
            'title': event.title,
            'start_time': event.start.toIso8601String(),
            'end_time': event.end.toIso8601String(),
            'location': event.location,
            'description': event.description,
            'category': event.category.name,
            'is_all_day': event.isAllDay,
            'reminders': event.reminders,
          })
          .eq('id', event.id);
    }, 'updateEvent');
  }

  Future<void> deleteEvent(String id) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).delete().eq('id', id);
    }, 'deleteEvent');
  }

  Stream<List<CalendarEvent>> watchEvents(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('start_time')
          .map((data) => data.map((e) => _fromJson(e)).toList());
    } catch (e) {
      return Stream.error(RepositoryException('Beklenmeyen hata [watchEvents]: $e'));
    }
  }

  CalendarEvent _fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      start: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      end: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : DateTime.now(),
      location: json['location']?.toString(),
      description: json['description']?.toString(),
      category: _parseCategory(json['category']),
      color: const Color(0xFF3B82F6),
      isAllDay: (json['is_all_day'] as bool?) ?? false,
      reminders: List<int>.from((json['reminders'] as List<dynamic>?) ?? []),
    );
  }

  EventCategory _parseCategory(dynamic value) {
    final str = value?.toString() ?? 'other';
    return EventCategory.values.firstWhere(
      (e) => e.name == str,
      orElse: () => EventCategory.other,
    );
  }
}
