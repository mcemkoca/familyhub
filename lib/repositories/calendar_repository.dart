import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class CalendarRepository {
  static final CalendarRepository _instance = CalendarRepository._internal();
  factory CalendarRepository() => _instance;
  CalendarRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final profile = await _client.from('profiles').select('family_id').eq('id', user.id).maybeSingle();
      return profile?['family_id'] as String?;
    } catch (e, st) {
      debugPrint('CalendarRepository._getFamilyId error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<CalendarEvent>> getEvents() async {
    // 1. Try Hive cache first
    final cached = HiveService.getCalendarEvents();
    if (cached.isNotEmpty) return cached;

    // 2. Fall back to Supabase
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('events')
          .select('*')
          .eq('family_id', familyId)
          .eq('status', 'active')
          .order('start_time', ascending: true);

      final events = (response as List).map((e) => _fromJson(e)).toList();
      await HiveService.saveCalendarEvents(events);
      return events;
    } catch (e, st) {
      debugPrint('CalendarRepository.getEvents error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final familyId = await _getFamilyId();
      final userId = AuthService.currentUserId;
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      final response = await _client.from('events').insert({
        'family_id': familyId,
        'created_by': userId,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'category': _categoryToString(event.category),
        'start_time': event.start.toIso8601String(),
        'end_time': event.end.toIso8601String(),
        'is_all_day': event.isAllDay,
        'recurrence_rule': event.recurrenceRule,
        'reminders': event.reminders,
      }).select().single();

      final created = _fromJson(response);
      final all = await getEvents();
      await HiveService.saveCalendarEvents([...all, created]);
      return created;
    } catch (e, st) {
      debugPrint('CalendarRepository.createEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _client.from('events').update({
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'category': _categoryToString(event.category),
        'start_time': event.start.toIso8601String(),
        'end_time': event.end.toIso8601String(),
        'is_all_day': event.isAllDay,
        'recurrence_rule': event.recurrenceRule,
        'reminders': event.reminders,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', event.id);

      final all = await getEvents();
      final updated = all.map((e) => e.id == event.id ? event : e).toList();
      await HiveService.saveCalendarEvents(updated);
    } catch (e, st) {
      debugPrint('CalendarRepository.updateEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _client.from('events').delete().eq('id', id);
      final all = await getEvents();
      await HiveService.saveCalendarEvents(all.where((e) => e.id != id).toList());
    } catch (e, st) {
      debugPrint('CalendarRepository.deleteEvent error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Stream<List<CalendarEvent>> watchEvents() async* {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) {
        yield [];
        return;
      }
      yield* _client
          .from('events')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map(
            (data) => data.where((e) => e['status'] == 'active').map((e) => _fromJson(e)).toList(),
          );
    } catch (e, st) {
      debugPrint('CalendarRepository.watchEvents error: $e');
      yield [];
    }
  }

  CalendarEvent _fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start_time'] as String),
      end: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      description: json['description'] as String?,
      category: _categoryFromString(json['category'] as String?),
      recurrenceRule: json['recurrence_rule'] as String?,
      isAllDay: json['is_all_day'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>?)?.cast<int>() ?? const [],
    );
  }

  static EventCategory _categoryFromString(String? val) {
    return switch (val) {
      'appointment' => EventCategory.appointment,
      'birthday' => EventCategory.birthday,
      'school' => EventCategory.school,
      'activity' => EventCategory.activity,
      'work' => EventCategory.work,
      'travel' => EventCategory.travel,
      _ => EventCategory.family,
    };
  }

  static String _categoryToString(EventCategory cat) {
    return switch (cat) {
      EventCategory.appointment => 'appointment',
      EventCategory.birthday => 'birthday',
      EventCategory.school => 'school',
      EventCategory.activity => 'activity',
      EventCategory.work => 'work',
      EventCategory.travel => 'travel',
      EventCategory.family => 'family',
      EventCategory.other => 'other',
    };
  }
}
