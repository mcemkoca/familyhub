import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import '../../widgets/calendar/event_card.dart';
import '../../widgets/calendar/event_modal.dart';
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
  Map<DateTime, List<CalendarEvent>>? _cachedMarkedDates;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _openModal({CalendarEvent? event, DateTime? date}) {
    setState(() {
      _editingEvent = event;
      _showModal = true;
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
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
                        onPressed: () => context.push('/calendar-sync'),
                        icon: Icon(
                          Icons.sync,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate,
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
                        icon: Icon(
                          Icons.today,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calendar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha(15)
                            : Colors.black.withAlpha(5),
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
                        color: AppColors.cobalt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      titleTextStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4),
                      cellPadding: EdgeInsets.zero,
                      markersMaxCount: 3,
                      markerSize: 5,
                      // markerOffset removed for compatibility,
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: BoxDecoration(
                        color: AppColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.cobalt.withAlpha(isDark ? 40 : 25),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.cobalt,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.cobalt,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle:
                          const TextStyle(color: Colors.white),
                      defaultTextStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                      weekendTextStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark,
                      ),
                      outsideTextStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightGray,
                      ),
                      disabledTextStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightGray,
                      ),
                      tablePadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Date header
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
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedEvents.length} etkinlik',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Events list
                Expanded(
                  child: selectedEvents.isEmpty
                      ? _EmptyState(onCreate: () => _openModal(date: _selectedDay))
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
            backgroundColor: Colors.orange,
            tooltip: 'Fotoğraftan Etkinlik',
            child: const Icon(Icons.document_scanner, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _openModal(date: _selectedDay),
            backgroundColor: AppColors.cobalt,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 56,
            color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'Etkinlik Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu gün için planlanmış etkinlik yok',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.slate,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).addEvent),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cobalt,
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
