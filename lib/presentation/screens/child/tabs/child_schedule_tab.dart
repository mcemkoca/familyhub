import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../domain/models/child_homework.dart';
import '../../../../domain/models/child_schedule.dart';
import '../../../../repositories/child_homework_repository.dart';
import '../../../../repositories/child_schedule_repository.dart';

class ChildScheduleTab extends StatefulWidget {
  const ChildScheduleTab({super.key});

  @override
  State<ChildScheduleTab> createState() => _ChildScheduleTabState();
}

class _ChildScheduleTabState extends State<ChildScheduleTab>
    with SingleTickerProviderStateMixin {
  final _scheduleRepo = ChildScheduleRepository();
  final _homeworkRepo = ChildHomeworkRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Start with today (weekday: 1=Mon, 7=Sun)
    final today = DateTime.now().weekday - 1; // 0-6
    _tabController.index = today.clamp(0, 6);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final _dayNames = const [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: const Color(0xFF10B981),
            tabs: _dayNames.map((d) => Tab(text: d)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(7, (index) => _DayView(
              dayOfWeek: index + 1,
              scheduleRepo: _scheduleRepo,
              homeworkRepo: _homeworkRepo,
            )),
          ),
        ),
      ],
    );
  }
}

class _DayView extends StatelessWidget {
  final int dayOfWeek;
  final ChildScheduleRepository scheduleRepo;
  final ChildHomeworkRepository homeworkRepo;

  const _DayView({
    required this.dayOfWeek,
    required this.scheduleRepo,
    required this.homeworkRepo,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // StreamBuilder auto-refreshes, but this gives haptic feedback
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule Section
            StreamBuilder<List<ChildSchedule>>(
              stream: scheduleRepo.watchMySchedule(),
              builder: (context, snapshot) {
                final allSchedules = snapshot.data ?? [];
                final daySchedules = allSchedules
                    .where((s) => s.dayOfWeek == dayOfWeek)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.schedule,
                      title: 'Ders Programı',
                      count: daySchedules.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (daySchedules.isEmpty)
                      _EmptyCard('Bugün ders yok 😊')
                    else
                      ...daySchedules.map((s) => _ScheduleCard(schedule: s)),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // Homework Section
            StreamBuilder<List<ChildHomework>>(
              stream: homeworkRepo.watchMyHomeworks(),
              builder: (context, snapshot) {
                final allHomeworks = snapshot.data ?? [];
                // Show all pending homeworks regardless of day
                final pendingHomeworks = allHomeworks
                    .where((h) => h.status != HomeworkStatus.completed)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.assignment,
                      title: 'Ödevlerim',
                      count: pendingHomeworks.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (pendingHomeworks.isEmpty)
                      _EmptyCard('Tüm ödevler tamamlandı! 🎉')
                    else
                      ...pendingHomeworks.map((h) => _HomeworkCard(homework: h)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ChildSchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: schedule.color.withAlpha(60)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          gradient: LinearGradient(
            colors: [
              schedule.color.withAlpha(15),
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: schedule.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.subject,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule.startTime} - ${schedule.endTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (schedule.teacher != null && schedule.teacher!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              schedule.teacher!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final ChildHomework homework;

  const _HomeworkCard({required this.homework});

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _priorityColor(homework.priority).withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: _priorityColor(homework.priority),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homework.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    homework.subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (homework.dueDate != null)
                    Text(
                      'Teslim: ${_formatDate(homework.dueDate!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: homework.isOverdue ? Colors.red : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
