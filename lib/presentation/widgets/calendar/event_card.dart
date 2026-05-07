import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';

class EventCard extends ConsumerWidget {
  final CalendarEvent event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPast = event.end.isBefore(DateTime.now());
    final catConfig = _categoryConfig(event.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(15)
                    : Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: isPast ? 0.65 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                SizedBox(
                  width: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        event.isAllDay
                            ? 'T.Gün'
                            : DateFormat('HH:mm').format(event.start),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark,
                        ),
                      ),
                      if (!event.isAllDay) ...[
                        const SizedBox(height: 4),
                        Text(
                          _durationText(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        width: 3,
                        height: 40,
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: category + recurrence
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: event.color
                                  .withAlpha(isDark ? 30 : 20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  catConfig.icon,
                                  size: 12,
                                  color: event.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  catConfig.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: event.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (event.recurrenceRule != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightGray,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tekrarlayan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark,
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      // Location
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Description
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Footer: attendees + reminder
                      Row(
                        children: [
                          // Attendee avatars
                          if (event.attendees.isNotEmpty)
                            _AttendeeStack(
                              attendeeIds: event.attendees,
                            ),
                          const Spacer(),
                          // Reminder badge
                          if (event.reminders.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning
                                    .withAlpha(isDark ? 25 : 15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    size: 12,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatReminder(
                                        event.reminders.first),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _durationText() {
    final diff = event.end.difference(event.start);
    if (diff.inHours >= 1) {
      return '${diff.inHours} sa';
    }
    return '${diff.inMinutes} dk';
  }

  String _formatReminder(int minutes) {
    if (minutes < 60) return '$minutes dk';
    if (minutes < 1440) return '${minutes ~/ 60} sa';
    if (minutes < 10080) return '${minutes ~/ 1440} gün';
    return '${minutes ~/ 10080} hafta';
  }

  _CategoryConfig _categoryConfig(EventCategory cat) {
    return switch (cat) {
      EventCategory.appointment =>
        _CategoryConfig(label: 'Randevu', icon: Icons.medical_services_outlined),
      EventCategory.birthday =>
        _CategoryConfig(label: 'Doğum Günü', icon: Icons.cake_outlined),
      EventCategory.school =>
        _CategoryConfig(label: 'Okul', icon: Icons.school_outlined),
      EventCategory.activity =>
        _CategoryConfig(label: 'Aktivite', icon: Icons.sports_soccer_outlined),
      EventCategory.work =>
        _CategoryConfig(label: 'İş', icon: Icons.work_outline),
      EventCategory.family =>
        _CategoryConfig(label: 'Aile', icon: Icons.people_outline),
      EventCategory.travel =>
        _CategoryConfig(label: 'Seyahat', icon: Icons.flight_takeoff),
      EventCategory.other =>
        _CategoryConfig(label: 'Diğer', icon: Icons.circle_outlined),
    };
  }
}

class _AttendeeStack extends ConsumerWidget {
  final List<String> attendeeIds;

  const _AttendeeStack({required this.attendeeIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    final displayed = attendeeIds
        .map((id) => members.firstWhere(
              (m) => m.id == id,
              orElse: () => members.first,
            ))
        .take(3)
        .toList();

    return Row(
      children: [
        for (var i = 0; i < displayed.length; i++) ...[
          if (i > 0)
            const SizedBox(width: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: displayed[i].color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                displayed[i].initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        if (attendeeIds.length > 3) ...[
          const SizedBox(width: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+${attendeeIds.length - 3}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.slate,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryConfig {
  final String label;
  final IconData icon;

  _CategoryConfig({required this.label, required this.icon});
}
