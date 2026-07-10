import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../../../../domain/entities.dart';
import '../../../../domain/models/ai_suggestion.dart';
import '../../../../domain/models/child_homework.dart';
import '../../../../domain/models/child_schedule.dart';
import '../../../../repositories/child_homework_repository.dart';
import '../../../../repositories/child_schedule_repository.dart';
import '../../../../repositories/child_streak_repository.dart';
import '../../../../repositories/child_task_repository.dart';
import '../../../../services/child_ai_service.dart';
import '../../../../services/child_auth_service.dart';

class ChildHomeTab extends StatelessWidget {
  final String childName;

  const ChildHomeTab({super.key, required this.childName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingHeader(childName: childName),
          const SizedBox(height: AppSpacing.xl),
          const _TasksProgressCard(),
          const SizedBox(height: AppSpacing.xl),
          const _QuickStatsRow(),
          const SizedBox(height: AppSpacing.xl),
          const _TodaySchedulePreview(),
          const SizedBox(height: AppSpacing.xl),
          const _UpcomingHomeworksPreview(),
          const SizedBox(height: AppSpacing.xl),
          const _AiSuggestionsSection(),
          const SizedBox(height: AppSpacing.xl),
          const _QuickAccessGrid(),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String childName;

  const _GreetingHeader({required this.childName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi günler';
    } else {
      greeting = 'İyi akşamlar';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $childName! 👋',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(AppLocalizations.of(context).bugunNelerYapacaginaBirBakalim,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _TasksProgressCard extends StatelessWidget {
  const _TasksProgressCard();

  @override
  Widget build(BuildContext context) {
    final repo = ChildTaskRepository();

    return StreamBuilder<List<Task>>(
      stream: repo.watchMyTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final total = tasks.length;
        final completed = tasks
            .where((t) => t.status == TaskStatus.completed)
            .length;
        final progress = total > 0 ? completed / total : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).gunlukGorevler,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                total == 0
                    ? 'Bugün görevin yok! 🌟'
                    : 'Bugün $total görevin var. ${completed > 0 ? "$completed'ini tamamladın!" : "Hadi başlayalım!"}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(progress * 100).toInt()}% tamamlandı',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context) {
    final taskRepo = ChildTaskRepository();
    final homeworkRepo = ChildHomeworkRepository();

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<Task>>(
            stream: taskRepo.watchMyTasks(),
            builder: (context, snapshot) {
              final pending = (snapshot.data ?? [])
                  .where((t) => t.status != TaskStatus.completed)
                  .length;
              return _StatCard(
                icon: Icons.check_circle_outline,
                label: AppLocalizations.of(context).bekleyenGorev,
                value: pending.toString(),
                color: Colors.green,
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StreamBuilder<List<ChildHomework>>(
            stream: homeworkRepo.watchMyHomeworks(),
            builder: (context, snapshot) {
              final pending = (snapshot.data ?? [])
                  .where((h) => h.status != HomeworkStatus.completed)
                  .length;
              return _StatCard(
                icon: Icons.assignment_outlined,
                label: AppLocalizations.of(context).bekleyenOdev,
                value: pending.toString(),
                color: Colors.blue,
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FutureBuilder<StreakStats>(
            future: ChildStreakRepository().getStreakStats(
              ChildAuthService.currentChildId ?? '',
            ),
            builder: (context, snapshot) {
              final streak = snapshot.data?.currentStreak ?? 0;
              return _StatCard(
                icon: Icons.local_fire_department,
                label: AppLocalizations.of(context).gunStreak,
                value: streak.toString(),
                color: Colors.orange,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _TodaySchedulePreview extends StatelessWidget {
  const _TodaySchedulePreview();

  @override
  Widget build(BuildContext context) {
    final repo = ChildScheduleRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).bugunkuDerslerim,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<ChildSchedule>>(
          stream: repo.watchMySchedule(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final today = DateTime.now().weekday;
            final daySchedules = all
                .where((s) => s.dayOfWeek == today)
                .toList();

            if (daySchedules.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.beach_access, color: Color(0xFF9CA3AF)),
                    SizedBox(width: AppSpacing.sm),
                    Text(AppLocalizations.of(context).bugunDersYokKeyfiniCikar,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: daySchedules
                  .take(3)
                  .map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(color: s.color.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${s.startTime} - ${s.subject}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingHomeworksPreview extends StatelessWidget {
  const _UpcomingHomeworksPreview();

  @override
  Widget build(BuildContext context) {
    final repo = ChildHomeworkRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).yaklasanOdevler,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<ChildHomework>>(
          stream: repo.watchMyHomeworks(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final pending = all
                .where((h) => h.status != HomeworkStatus.completed)
                .toList();

            if (pending.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Color(0xFF9CA3AF)),
                    SizedBox(width: AppSpacing.sm),
                    Text(AppLocalizations.of(context).tumOdevlerTamamlandi,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: pending
                  .take(3)
                  .map(
                    (h) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: h.isOverdue
                            ? Colors.red.withAlpha(10)
                            : Colors.blue.withAlpha(10),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(
                          color: h.isOverdue
                              ? Colors.red.withAlpha(30)
                              : Colors.blue.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 16,
                            color: h.isOverdue ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${h.subject}: ${h.title}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (h.dueDate != null)
                            Text(
                              _formatDate(h.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: h.isOverdue
                                    ? Colors.red
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return '${-diff} gün geçti';
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    return '$diff gün';
  }
}

class _AiSuggestionsSection extends StatefulWidget {
  const _AiSuggestionsSection();

  @override
  State<_AiSuggestionsSection> createState() => _AiSuggestionsSectionState();
}

class _AiSuggestionsSectionState extends State<_AiSuggestionsSection> {
  final _aiService = ChildAiService();
  late Future<List<AiSuggestion>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _aiService.generateSuggestions();
  }

  Future<void> _refresh() async {
    setState(() {
      _suggestionsFuture = _aiService.generateSuggestions();
    });
  }

  void _onApplySuggestion(AiSuggestion suggestion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${suggestion.title}" önerisi ebeveyne iletildi!'),
        backgroundColor: suggestion.color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(AppLocalizations.of(context).aiOnerileri,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _refresh,
              child: const Icon(Icons.refresh, size: 18, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<AiSuggestion>>(
          future: _suggestionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA855F7)),
                ),
              );
            }

            final suggestions = snapshot.data ?? [];

            if (suggestions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF6B7280),
                      size: 32,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(AppLocalizations.of(context).henuzAiOnerisiYok,
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(AppLocalizations.of(context).dahaFazlaAktiviteKaydiOlusuncaOnerilerGelecek,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                children: suggestions
                    .take(3)
                    .map(
                      (s) => _AiSuggestionCard(
                        suggestion: s,
                        onApply: () => _onApplySuggestion(s),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onApply;

  const _AiSuggestionCard({required this.suggestion, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: suggestion.color.withAlpha(30),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(suggestion.icon, color: suggestion.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  suggestion.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  suggestion.reason,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              suggestion.actionLabel ?? 'Ekle',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).hizliErisim,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _QuickAccessCard(
              icon: Icons.check_circle,
              label: AppLocalizations.of(context).gorevlerim,
              color: Colors.green,
              onTap: () => context.push(AppRoutes.tasks),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAccessCard(
              icon: Icons.chat_bubble,
              label: 'Aile Sohbeti',
              color: Colors.blue,
              onTap: () => context.push(AppRoutes.chat),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAccessCard(
              icon: Icons.location_on,
              label: 'Konumum',
              color: Colors.purple,
              onTap: () => context.push(AppRoutes.location),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _QuickAccessCard(
              icon: Icons.family_restroom,
              label: 'Ailem',
              color: Colors.teal,
              onTap: () => context.push('/family-manage'),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAccessCard(
              icon: Icons.backup,
              label: 'Yedekleme',
              color: const Color(0xFF4285F4),
              onTap: () => context.push('/google-drive-backup'),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickAccessCard(
              icon: Icons.auto_awesome,
              label: 'Rotasyon',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push(
                AppRoutes.smartRotation,
                extra: ChildAuthService.currentFamilyId,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
    return Expanded(child: child);
  }
}
