import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../repositories/hub_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/family_avatar.dart';
import '../../widgets/hub_card_widget.dart';
import '../../../domain/entities.dart';
import '../../../services/weather_service.dart';
import '../../../services/hive_service.dart';
import '../../../components/hub/ai_suggestions_widget.dart';
import '../../../components/hub/content_widgets/content_highlights_widget.dart';
import '../../../services/location_tracking_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  @override
  void initState() {
    super.initState();
    LocationTrackingService.startTracking();
  }

  Future<void> _refresh() async {
    // Invalidate providers to trigger refetch
    ref.invalidate(todaySummaryProvider);
    ref.invalidate(upcomingEventsProvider);
    ref.invalidate(myTasksProvider);
    ref.invalidate(familyMoodsProvider);
    ref.invalidate(weatherProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final upcomingEventsAsync = ref.watch(upcomingEventsProvider);
    final myTasksAsync = ref.watch(myTasksProvider);
    final familyMoodsAsync = ref.watch(familyMoodsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.cobalt,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba,',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.gray),
                          ),
                          Text(
                            'Ailem',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                      _WeatherBadge(),
                    ],
                  ),
                ),
              ),
              // AI Suggestions
              const SliverToBoxAdapter(child: AISuggestionsWidget()),
              // Content Highlights (Daily Tips)
              const SliverToBoxAdapter(child: ContentHighlightsWidget()),
              // Family avatars
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 0, 24),
                  child: SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        if (index == members.length) {
                          return GestureDetector(
                            onTap: () => context.push(AppRoutes.family),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.gray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ekle',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return FamilyAvatar(
                          member: members[index],
                          onTap: () => context.push(AppRoutes.family),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Today Summary (from Supabase)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTodaySummary(todaySummaryAsync, isDark),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Hub cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final cards = ref.watch(hubCardsProvider);
                      final card = cards[index];
                      return HubCardWidget(
                        card: card,
                        onTap: () {
                          switch (card.type) {
                            case HubCardType.tasks:
                              context.push(AppRoutes.tasks);
                              break;
                            case HubCardType.calendar:
                              context.push(AppRoutes.calendar);
                              break;
                            case HubCardType.budget:
                              context.push(AppRoutes.budget);
                              break;
                            case HubCardType.streak:
                              context.push(AppRoutes.streak);
                              break;
                            case HubCardType.smartReminders:
                              context.push(AppRoutes.smartReminders);
                              break;
                            case HubCardType.routines:
                              context.push(AppRoutes.routines);
                              break;
                            case HubCardType.crashDetection:
                              context.push(AppRoutes.crashSettings);
                              break;
                            case HubCardType.locationTracking:
                              context.push(AppRoutes.locationTrackingSettings);
                              break;
                            case HubCardType.sos:
                              context.push(AppRoutes.sosMain);
                              break;
                            case HubCardType.contacts:
                              context.push(AppRoutes.contacts);
                              break;
                            case HubCardType.gallery:
                              context.push(AppRoutes.gallery);
                              break;
                            case HubCardType.documents:
                              context.push(AppRoutes.documents);
                              break;
                          }
                        },
                      );
                    }, childCount: ref.watch(hubCardsProvider).length),
                  ),
              ),
              // Upcoming Events header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yaklaşan Etkinlikler',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.calendar),
                        child: Text(AppLocalizations.of(context).tumunuGor),
                      ),
                    ],
                  ),
                ),
              ),
              // Upcoming Events list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildUpcomingEvents(upcomingEventsAsync, isDark),
                ),
              ),
              // My Tasks header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Görevlerim',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.tasks),
                        child: Text(AppLocalizations.of(context).tumunuGor),
                      ),
                    ],
                  ),
                ),
              ),
              // My Tasks list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMyTasks(myTasksAsync, isDark),
                ),
              ),
              // Family Mood header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aile Ruh Hali',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      TextButton(
                        onPressed: () => _showMoodPicker(),
                        child: Text(AppLocalizations.of(context).share),
                      ),
                    ],
                  ),
                ),
              ),
              // Family Moods list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildFamilyMoods(familyMoodsAsync, isDark),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(AsyncValue<TodaySummary> asyncValue, bool isDark) {
    return asyncValue.when(
      data: (summary) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.event,
              label: 'Etkinlik',
              value: '${summary.eventCount}',
              color: AppColors.cobalt,
            ),
            _SummaryItem(
              icon: Icons.task_alt,
              label: 'Görev',
              value: '${summary.taskCount}',
              color: AppColors.green,
            ),
            _SummaryItem(
              icon: Icons.mark_email_unread,
              label: 'Mesaj',
              value: '${summary.unreadMessages}',
              color: AppColors.orange,
            ),
            _SummaryItem(
              icon: Icons.people,
              label: 'Çevrimiçi',
              value: '${summary.onlineMembers}/${summary.totalMembers}',
              color: AppColors.purple,
            ),
          ],
        ),
      ),
      loading: () => _ShimmerCard(height: 80),
      error: (e, _) => _ErrorMiniCard(message: e.toString()),
    );
  }

  Widget _buildUpcomingEvents(
    AsyncValue<List<HubEvent>> asyncValue,
    bool isDark,
  ) {
    return asyncValue.when(
      data: (events) {
        if (events.isEmpty) {
          return _EmptyMiniCard(message: 'Yaklaşan etkinlik yok');
        }
        return Column(
          children: events
              .take(3)
              .map((e) => _EventListTile(event: e, isDark: isDark))
              .toList(),
        );
      },
      loading: () => _ShimmerCard(height: 120),
      error: (e, _) => _ErrorMiniCard(message: e.toString()),
    );
  }

  Widget _buildMyTasks(AsyncValue<List<HubTask>> asyncValue, bool isDark) {
    return asyncValue.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyMiniCard(message: 'Bekleyen görev yok');
        }
        return Column(
          children: tasks
              .take(3)
              .map(
                (t) => _TaskListTile(
                  task: t,
                  isDark: isDark,
                  onComplete: () => _completeTask(t.id),
                ),
              )
              .toList(),
        );
      },
      loading: () => _ShimmerCard(height: 120),
      error: (e, _) => _ErrorMiniCard(message: e.toString()),
    );
  }

  Widget _buildFamilyMoods(
    AsyncValue<List<FamilyMood>> asyncValue,
    bool isDark,
  ) {
    return asyncValue.when(
      data: (moods) {
        if (moods.isEmpty) {
          return _EmptyMiniCard(message: 'Henüz ruh hali paylaşılmamış');
        }
        return SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = moods[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mood.note ?? 'Ruh hali',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark,
                          ),
                        ),
                        if (mood.energyLevel != null)
                          Text(
                            'Enerji: ${mood.energyLevel}/10',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.gray,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => _ShimmerCard(height: 72),
      error: (e, _) => _ErrorMiniCard(message: e.toString()),
    );
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final repo = HubRepository();
      await repo.completeTask(taskId);
      HapticFeedback.mediumImpact();
      ref.invalidate(myTasksProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Görev tamamlanamadı: $e')));
      }
    }
  }

  void _showMoodPicker() {
    final emojis = ['😊', '😢', '😠', '😴', '🤒', '🥳'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ruh Halini Paylaş',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: emojis
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            final familyId = await ref.read(familyIdProvider.future);
                            if (familyId == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context).aileBilgisiBulunamadi)),
                                );
                              }
                              return;
                            }
                            final repo = HubRepository();
                            await repo.shareMood(
                              familyId: familyId,
                              emoji: emoji,
                            );
                            ref.invalidate(familyMoodsProvider);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Paylaşılamadı: $e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.dark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.gray,
          ),
        ),
      ],
    );
  }
}

class _EventListTile extends StatelessWidget {
  final HubEvent event;
  final bool isDark;

  const _EventListTile({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cobalt.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: AppColors.cobalt),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                Text(
                  '${event.start.day}/${event.start.month} ${event.start.hour}:${event.start.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  final HubTask task;
  final bool isDark;
  final VoidCallback onComplete;

  const _TaskListTile({
    required this.task,
    required this.isDark,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.green),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check, color: AppColors.green, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                if (task.dueDate != null)
                  Text(
                    'Bitiş: ${task.dueDate!.day}/${task.dueDate!.month}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _priorityColor(task.priority).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.priority.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _priorityColor(task.priority),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.orange;
      default:
        return AppColors.green;
    }
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _EmptyMiniCard extends StatelessWidget {
  final String message;
  const _EmptyMiniCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMiniCard extends StatelessWidget {
  final String message;
  const _ErrorMiniCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(128)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherBadge extends ConsumerWidget {
  String _getLocationName() {
    final useLoc = HiveService.getBoolSetting('weatherUseLocation', defaultValue: true);
    final savedLoc = HiveService.getLocation();
    if (savedLoc != null) {
      return savedLoc.city.isNotEmpty ? savedLoc.city : savedLoc.address;
    }
    if (useLoc) return 'Mevcut Konum';
    return HiveService.getSetting('weatherCity') ?? 'İstanbul';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.weatherSettings),
      child: weatherAsync.when(
        data: (weather) {
          final icon = WeatherService.weatherIconData(weather.weatherCode);
          final color = WeatherService.weatherColor(weather.weatherCode);
          final locName = _getLocationName();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${weather.temperature.round()}°C',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 1,
                  height: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                ),
                const SizedBox(width: 4),
                Text(
                  locName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, st) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.wb_sunny, color: AppColors.orange, size: 20),
              SizedBox(width: 6),
              Text(
                '--°C',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
