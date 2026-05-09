import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class CalendarRepository with RepositoryErrorHandler {
  static final CalendarRepository _instance = CalendarRepository._internal();
  factory CalendarRepository() => _instance;
  CalendarRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    return handleRepositoryCall(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle();
      return profile?['family_id'] as String?;
    }, '_getFamilyId');
  }

  Future<List<CalendarEvent>> getEvents() async {
    return handleRepositoryCall(() async {
      // 1. Try Hive cache first
      final cached = HiveService.getCalendarEvents();
      if (cached.isNotEmpty) return cached;

      // 2. Fall back to Supabase
      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('events')
          .select('*')
          .eq('family_id', familyId)
          .eq('status', 'active')
          .order('start_time', ascending: true);

      final events = (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
      await HiveService.saveCalendarEvents(events);
      return events;
    }, 'getEvents');
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      final userId = AuthService.currentUserId;
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      final response = await _client
          .from('events')
          .insert({
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
          })
          .select()
          .single();

      final created = _fromJson(response);
      final all = await getEvents();
      await HiveService.saveCalendarEvents([...all, created]);
      return created;
    }, 'createEvent');
  }

  Future<void> updateEvent(CalendarEvent event) async {
    return handleRepositoryCall(() async {
      await _client
          .from('events')
          .update({
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
          })
          .eq('id', event.id);

      final all = await getEvents();
      final updated = all.map((e) => e.id == event.id ? event : e).toList();
      await HiveService.saveCalendarEvents(updated);
    }, 'updateEvent');
  }

  Future<void> deleteEvent(String id) async {
    return handleRepositoryCall(() async {
      await _client.from('events').delete().eq('id', id);
      final all = await getEvents();
      await HiveService.saveCalendarEvents(
        all.where((e) => e.id != id).toList(),
      );
    }, 'deleteEvent');
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
            (data) => data
                .where((e) => e['status'] == 'active')
                .map((e) => _fromJson(e))
                .toList(),
          );
    } catch (e) {
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
