import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class EventRepository {
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
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('start_time', ascending: true);
      return (response as List).map((e) => _fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[EventRepository.getEvents] error: $e');
      rethrow;
    }
  }

  Future<CalendarEvent> createEvent(CalendarEvent event, String familyId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final response = await _client.from(_table).insert({
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
      }).select().single();

      return _fromJson(response);
    } catch (e, st) {
      debugPrint('[EventRepository.createEvent] error: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _client.from(_table).update({
        'title': event.title,
        'start_time': event.start.toIso8601String(),
        'end_time': event.end.toIso8601String(),
        'location': event.location,
        'description': event.description,
        'category': event.category.name,
        'is_all_day': event.isAllDay,
        'reminders': event.reminders,
      }).eq('id', event.id);
    } catch (e, st) {
      debugPrint('[EventRepository.updateEvent] error: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e, st) {
      debugPrint('[EventRepository.deleteEvent] error: $e');
      rethrow;
    }
  }

  Stream<List<CalendarEvent>> watchEvents(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('start_time')
          .map((data) => data.map((e) => _fromJson(e)).toList());
    } catch (e, st) {
      debugPrint('[EventRepository.watchEvents] error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  CalendarEvent _fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      start: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      end: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      location: json['location']?.toString(),
      description: json['description']?.toString(),
      category: _parseCategory(json['category']),
      color: const Color(0xFF3B82F6),
      isAllDay: json['is_all_day'] ?? false,
      reminders: List<int>.from(json['reminders'] ?? []),
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
