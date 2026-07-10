import 'package:flutter/material.dart';
import '../../../../config/constants.dart';
import '../../../../domain/entities.dart';
import '../../../../repositories/child_task_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildTasksTab extends StatefulWidget {
  const ChildTasksTab({super.key});

  @override
  State<ChildTasksTab> createState() => _ChildTasksTabState();
}

class _ChildTasksTabState extends State<ChildTasksTab> {
  final _repo = ChildTaskRepository();

  Future<void> _completeTask(Task task) async {
    try {
      await _repo.completeTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).gorevTamamlandi),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      case 'low':
        return 'Düşük';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _repo.watchMyTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return const _EmptyTasksView();
        }

        final pending = tasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();
        final completed = tasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (pending.isNotEmpty) ...[
              _SectionTitle('Bekleyen Görevler (${pending.length})'),
              const SizedBox(height: AppSpacing.md),
              ...pending.map(
                (task) => _TaskCard(
                  task: task,
                  onComplete: () => _completeTask(task),
                  priorityColor: _priorityColor(task.priority),
                  priorityLabel: _priorityLabel(task.priority),
                ),
              ),
            ],
            if (completed.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Tamamlanan Görevler (${completed.length})'),
              const SizedBox(height: AppSpacing.md),
              ...completed.map(
                (task) => _TaskCard(
                  task: task,
                  onComplete: null,
                  priorityColor: _priorityColor(task.priority),
                  priorityLabel: _priorityLabel(task.priority),
                  isCompleted: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final Color priorityColor;
  final String priorityLabel;
  final bool isCompleted;

  const _TaskCard({
    required this.task,
    this.onComplete,
    required this.priorityColor,
    required this.priorityLabel,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: Color(0xFF9CA3AF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onComplete != null)
              Checkbox(
                value: isCompleted,
                onChanged: (_) => onComplete!(),
                activeColor: Colors.green,
              )
            else
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: priorityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isOverdue(task.dueDate!) && !isCompleted
                                ? Colors.red
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Bugün';
    if (dateDay == today.add(const Duration(days: 1))) return 'Yarın';
    return '${date.day}/${date.month}';
  }

  static bool _isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Color(0xFF9CA3AF)),
          SizedBox(height: AppSpacing.md),
          Text(AppLocalizations.of(context).henuzGorevinYok,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(AppLocalizations.of(context).gorevlerinEklendigindeBuradaGorunecek,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
