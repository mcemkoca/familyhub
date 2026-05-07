import 'dart:async';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/models/calendar_sync.dart';

/// Harici Takvim Senkronizasyon Servisi
/// device_calendar paketi ile telefonun yerel takvimlerine erişim
class CalendarSyncService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  // ── İZİN YÖNETİMİ ───────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.data ?? false;
  }

  static Future<bool> hasPermission() async {
    final result = await _plugin.hasPermissions();
    return result.data ?? false;
  }

  static Future<void> openCalendarSettings() async {
    await openAppSettings();
  }

  // ── TAKVİM LİSTESİ ──────────────────────────────────────────────────────

  static Future<List<ExternalCalendar>> listCalendars() async {
    final granted = await requestPermission();
    if (!granted) return [];

    final result = await _plugin.retrieveCalendars();
    final calendars = result.data ?? [];

    return calendars
        .map(
          (c) => ExternalCalendar(
            id: c.id ?? 'unknown',
            name: c.name ?? 'İsimsiz Takvim',
            description: c.accountName,
            isPrimary: c.isDefault ?? false,
            color: c.color?.toRadixString(16),
            timeZone: c.accountType,
          ),
        )
        .toList();
  }

  // ── ETKİNLİKLERİ ÇEK ────────────────────────────────────────────────────

  static Future<List<ExternalEvent>> fetchEvents({
    required String calendarId,
    required DateTime start,
    required DateTime end,
  }) async {
    final granted = await requestPermission();
    if (!granted) return [];

    final result = await _plugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(startDate: start, endDate: end),
    );

    final events = result.data ?? [];
    return events.map((e) => _convertToExternalEvent(e, calendarId)).toList();
  }

  // ── ETKİNLİK EKLE/GÜNCELLE ──────────────────────────────────────────────

  static Future<String?> addOrUpdateEvent({
    required String calendarId,
    required ExternalEvent event,
  }) async {
    final granted = await requestPermission();
    if (!granted) return null;

    final calendarResult = await _plugin.retrieveCalendars();
    final calendars = calendarResult.data ?? [];
    final calendarExists = calendars.any((c) => c.id == calendarId);
    if (!calendarExists) return null;

    final ev = Event(
      calendarId,
      eventId: event.externalId,
      title: event.title,
      description: event.description,
      start: tz.TZDateTime.from(event.start, tz.local),
      end: tz.TZDateTime.from(event.end, tz.local),
      allDay: event.isAllDay,
    );

    if (event.location != null) {
      ev.location = event.location;
    }

    if (event.reminders.isNotEmpty) {
      ev.reminders = event.reminders.map((m) => Reminder(minutes: m)).toList();
    }

    if (event.recurrenceRule != null) {
      ev.recurrenceRule = _parseRecurrenceRule(event.recurrenceRule!);
    }

    final result = await _plugin.createOrUpdateEvent(ev);
    return result?.data;
  }

  // ── ETKİNLİK SİL ────────────────────────────────────────────────────────

  static Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    final result = await _plugin.deleteEvent(calendarId, eventId);
    return result.data ?? false;
  }

  // ── SENKRONİZASYON ──────────────────────────────────────────────────────

  static Future<SyncResult> syncCalendar({
    required CalendarConnection connection,
    required List<ExternalEvent> localEvents,
    DateTime? since,
  }) async {
    final timestamp = DateTime.now();
    var added = 0;
    var updated = 0;
    var deleted = 0;

    try {
      final start = since ?? DateTime.now().subtract(const Duration(days: 30));
      final end = DateTime.now().add(const Duration(days: 365));

      for (final calendarId in connection.selectedCalendarIds) {
        // Harici takvimden etkinlikleri çek
        final externalEvents = await fetchEvents(
          calendarId: calendarId,
          start: start,
          end: end,
        );

        // Çift yönlü senkronizasyon
        if (connection.syncDirection == SyncDirection.fromExternal ||
            connection.syncDirection == SyncDirection.bidirectional) {
          for (final ext in externalEvents) {
            final local = localEvents.firstWhere(
              (l) => l.externalId == ext.externalId || l.id == ext.id,
              orElse: () => ExternalEvent(
                id: '',
                title: '',
                start: DateTime.now(),
                end: DateTime.now(),
              ),
            );

            if (local.id.isEmpty) {
              // Yeni etkinlik
              added++;
            } else if (_hasConflict(local, ext)) {
              // Çakışma var - çözüm uygula
              final resolved = _resolveConflict(
                local: local,
                remote: ext,
                strategy: connection.conflictStrategy,
              );
              if (resolved != null) updated++;
            } else {
              // Güncelle
              updated++;
            }
          }
        }

        // FamilyHub'dan hariciye (sadece bidirectional)
        if (connection.syncDirection == SyncDirection.bidirectional) {
          for (final local in localEvents) {
            if (local.externalId == null) {
              // Yerel etkinlik hariciye yok, ekle
              final newId = await addOrUpdateEvent(
                calendarId: calendarId,
                event: local,
              );
              if (newId != null) added++;
            }
          }
        }
      }

      return SyncResult(
        added: added,
        updated: updated,
        deleted: deleted,
        timestamp: timestamp,
      );
    } catch (e) {
      return SyncResult(error: e.toString(), timestamp: timestamp);
    }
  }

  // ── YARDIMCI ────────────────────────────────────────────────────────────

  static ExternalEvent _convertToExternalEvent(Event e, String calendarId) {
    return ExternalEvent(
      id: e.eventId ?? 'event-${e.hashCode}',
      externalId: e.eventId,
      title: e.title ?? 'İsimsiz Etkinlik',
      description: e.description,
      start: e.start?.toLocal() ?? DateTime.now(),
      end: e.end?.toLocal() ?? DateTime.now(),
      location: e.location,
      isAllDay: e.allDay ?? false,
      recurrenceRule: e.recurrenceRule?.toString(),
      reminders: e.reminders?.map((r) => r.minutes ?? 0).toList() ?? [],
      calendarId: calendarId,
      lastModified: DateTime.now(),
    );
  }

  static bool _hasConflict(ExternalEvent local, ExternalEvent remote) {
    final localModified = local.lastModified ?? local.start;
    final remoteModified = remote.lastModified ?? remote.start;
    return localModified.difference(remoteModified).abs() >
        const Duration(minutes: 5);
  }

  static ExternalEvent? _resolveConflict({
    required ExternalEvent local,
    required ExternalEvent remote,
    required ConflictStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        final localModified = local.lastModified ?? DateTime(1970);
        final remoteModified = remote.lastModified ?? DateTime(1970);
        return localModified.isAfter(remoteModified) ? local : remote;
      case ConflictStrategy.sourcePriority:
        return local; // Yerel öncelik
      case ConflictStrategy.merge:
        return ExternalEvent(
          id: local.id,
          externalId: remote.externalId,
          title: remote.title != local.title
              ? '${local.title} / ${remote.title}'
              : local.title,
          description:
              '${local.description ?? ''}\n---\n${remote.description ?? ''}',
          start: local.start,
          end: remote.end.isAfter(local.end) ? remote.end : local.end,
          location: remote.location ?? local.location,
          lastModified: DateTime.now(),
        );
      case ConflictStrategy.manual:
        return null; // UI karar versin
    }
  }

  static RecurrenceRule? _parseRecurrenceRule(String rrule) {
    try {
      // Basit RRULE parse: FREQ=DAILY;INTERVAL=1;COUNT=5
      final freqMatch = RegExp(r'FREQ=(\w+)').firstMatch(rrule);
      if (freqMatch == null) return null;

      final freqStr = freqMatch.group(1)?.toUpperCase();
      final frequency = RecurrenceFrequency.values.firstWhere(
        (f) => f.name.toUpperCase() == freqStr,
        orElse: () => RecurrenceFrequency.Daily,
      );

      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rrule);
      final interval = intervalMatch != null
          ? int.parse(intervalMatch.group(1)!)
          : 1;

      final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rrule);
      final count = countMatch != null ? int.parse(countMatch.group(1)!) : null;

      return RecurrenceRule(
        frequency,
        interval: interval,
        totalOccurrences: count,
      );
    } catch (_) {
      return null;
    }
  }
}
