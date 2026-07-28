import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import '../../widgets/calendar/event_card.dart';
import '../../widgets/calendar/event_modal.dart';
import '../../widgets/calendar_permission_prompt.dart';
import '../../../services/ocr_event_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarEvent? _editingEvent;
  bool _showModal = false;
  bool _agendaMode = false;
  Map<DateTime, List<CalendarEvent>>? _cachedMarkedDates;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // İlk kez takvim ekranına girildiğinde takvim izni promptunu göster.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CalendarPermissionPrompt.maybeShow(context);
    });
  }

  void _openModal({CalendarEvent? event, DateTime? date}) {
    setState(() {
      _editingEvent = event;
      _showModal = true;
    });
  }

  // Ajanda (timetable) görünümü — bugünden itibaren güne göre gruplu,
  // renk kodlu ve üye avatarlı etkinlik kartları (5. görsel).
  Widget _buildAgenda(List<CalendarEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = events
        .where((e) => !DateTime(e.start.year, e.start.month, e.start.day)
            .isBefore(today))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (upcoming.isEmpty) {
      return _EmptyState(onCreate: () => _openModal(date: today));
    }

    final groups = <DateTime, List<CalendarEvent>>{};
    for (final e in upcoming) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      groups.putIfAbsent(day, () => []).add(e);
    }
    final days = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 4),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final dayEvents = groups[day]!;
        final isToday = isSameDay(day, today);
        final dateStr =
            DateFormat('EEEE, d MMMM', 'tr_TR').format(day).toUpperCase();
        final label = isToday ? 'BUGÜN · $dateStr' : dateStr;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isToday
                      ? const Color(0xFF6366F1)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140),
                ),
              ),
            ),
            ...dayEvents.map((e) =>
                EventCard(event: e, onTap: () => _openModal(event: e))),
          ],
        );
      },
    );
  }

  void _closeModal() => setState(() => _showModal = false);

  void _saveEvent(CalendarEvent event) {
    if (_editingEvent != null) {
      ref.read(eventsProvider.notifier).updateEvent(event);
    } else {
      ref.read(eventsProvider.notifier).addEvent(event);
    }
    setState(() => _cachedMarkedDates = null);
    HapticFeedback.mediumImpact();
  }

  void _deleteEvent(String id) {
    ref.read(eventsProvider.notifier).deleteEvent(id);
    setState(() => _cachedMarkedDates = null);
    HapticFeedback.heavyImpact();
  }

  Future<void> _scanPhoto() async {
    HapticFeedback.mediumImpact();
    final parsed = await OcrEventService.pickAndParse();
    if (parsed == null) return;
    if (mounted) {
      _openModal(event: parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider.select((v) => v.valueOrNull ?? []));
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    ref.listen(eventsProvider, (prev, next) {
      final prevLen = prev?.valueOrNull?.length ?? 0;
      final nextLen = next.valueOrNull?.length ?? 0;
      if (prevLen != nextLen) {
        setState(() => _cachedMarkedDates = null);
      }
    });

    final selectedEvents = _selectedDay == null
        ? <CalendarEvent>[]
        : events.where((e) => isSameDay(e.start, _selectedDay!)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    // Build marked dates map (memoized)
    final markedDates = _cachedMarkedDates ??= () {
      final map = <DateTime, List<CalendarEvent>>{};
      for (final e in events) {
        final day = DateTime(e.start.year, e.start.month, e.start.day);
        map.putIfAbsent(day, () => []).add(e);
      }
      return map;
    }();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Aile Takvimi',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: 28),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            setState(() => _agendaMode = !_agendaMode),
                        icon: Icon(
                          _agendaMode
                              ? Icons.calendar_month
                              : Icons.view_agenda_outlined,
                          color: _agendaMode
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF6B7280),
                        ),
                        tooltip: _agendaMode ? 'Takvim Görünümü' : 'Ajanda',
                      ),
                      IconButton(
                        onPressed: () => context.push('/calendar-sync'),
                        icon: const Icon(
                          Icons.sync,
                          color: Color(0xFF6B7280),
                        ),
                        tooltip: 'Takvim Senkronizasyonu',
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime.now();
                            _selectedDay = DateTime.now();
                          });
                        },
                        icon: const Icon(
                          Icons.today,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Calendar (ajanda modunda gizli)
                if (!_agendaMode)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2027, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => markedDates[DateTime(day.year, day.month, day.day)] ?? [],
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _calendarFormat = format),
                    onPageChanged: (focused) => _focusedDay = focused,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Ay',
                      CalendarFormat.twoWeeks: '2 Hafta',
                      CalendarFormat.week: 'Hafta',
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: true,
                      formatButtonDecoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      titleTextStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4),
                      cellPadding: EdgeInsets.zero,
                      markersMaxCount: 3,
                      markerSize: 5,
                      // markerOffset removed for compatibility,
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle:
                          const TextStyle(color: Colors.white),
                      defaultTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      outsideTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                      ),
                      disabledTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
                      ),
                      tablePadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ),
                if (!_agendaMode) const SizedBox(height: 16),
                // Date header (ajanda modunda gizli)
                if (!_agendaMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        _selectedDay == null
                            ? 'Tüm Etkinlikler'
                            : DateFormat('d MMMM yyyy, EEEE', 'tr_TR')
                                .format(_selectedDay!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedEvents.length} etkinlik',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Events list — ajanda modunda tüm yaklaşan etkinlikler gruplu
                Expanded(
                  child: _agendaMode
                      ? _buildAgenda(events)
                      : selectedEvents.isEmpty
                          ? _EmptyState(
                              onCreate: () => _openModal(date: _selectedDay))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: selectedEvents.length,
                              itemBuilder: (context, index) {
                                return EventCard(
                                  event: selectedEvents[index],
                                  onTap: () => _openModal(
                                    event: selectedEvents[index],
                                  ),
                                );
                              },
                            ),
                ),
                SizedBox(height: safeBottom + 8),
              ],
            ),
            // Event Modal
            if (_showModal)
              EventModal(
                event: _editingEvent,
                initialDate: _selectedDay,
                onSave: _saveEvent,
                onDelete: _deleteEvent,
                onClose: _closeModal,
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ocr',
            onPressed: _scanPhoto,
            backgroundColor: const Color(0xFF6366F1),
            tooltip: AppLocalizations.of(context).fotograftanEtkinlik,
            child: const Icon(Icons.document_scanner, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _openModal(date: _selectedDay),
            backgroundColor: const Color(0xFF6366F1),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            'Etkinlik Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).buGunIcinPlanlanmisEtkinlikYok,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).addEvent),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



