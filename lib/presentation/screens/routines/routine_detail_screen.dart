import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/models/routine.dart';
import '../../../repositories/routine_repository.dart';
import '../../../services/routine_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;
  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  Routine? _routine;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    setState(() => _loading = true);
    try {
      _routine = await RoutineRepository().getById(widget.routineId);
    } catch (e) {
      _routine = null;
    }
    setState(() => _loading = false);
  }

  void _completeStep(RoutineStep step) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _routine = _routine!.copyWith(
        steps: _routine!.steps.map((s) {
          if (s.id == step.id) {
            return s.copyWith(
              status: StepStatus.completed,
              completedAt: DateTime.now(),
              completedBy: 'Ben',
            );
          }
          return s;
        }).toList(),
        status: _routine!.status.copyWith(
          progress: RoutineService.calculateProgress(_routine!),
        ),
      );
    });
    await RoutineRepository().update(_routine!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${step.title} tamamlandı! 🎉')));
  }

  void _skipStep(RoutineStep step) async {
    setState(() {
      _routine = _routine!.copyWith(
        steps: _routine!.steps.map((s) {
          if (s.id == step.id) return s.copyWith(status: StepStatus.skipped);
          return s;
        }).toList(),
      );
    });
    await RoutineRepository().update(_routine!);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _routine!;
    final color = _parseColor(r.color);
    final completed = r.steps
        .where((s) => s.status == StepStatus.completed)
        .length;
    final progress = RoutineService.calculateProgress(r);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        title: Text(r.name),
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8F9FA),
        foregroundColor: textColor,
        actions: [
          if (r.status.state == RoutineState.active)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                setState(() {
                  _routine = r.copyWith(
                    status: r.status.copyWith(state: RoutineState.paused),
                  );
                });
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildProgressCard(
                r,
                color,
                progress,
                completed,
                isDark,
                textColor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCurrentStepCard(r, color, isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tüm Adımlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildStepCard(r.steps[index], color, isDark, textColor),
              childCount: r.steps.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    Routine r,
    Color color,
    double progress,
    int completed,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                '%${progress.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.withAlpha(26),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Tamamlanan',
                '$completed',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Kalan',
                '${r.steps.length - completed}',
                Icons.pending,
                Colors.orange,
              ),
              _buildStatItem(
                'Toplam Süre',
                '${r.estimatedTotalDuration} dk',
                Icons.timer,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildCurrentStepCard(
    Routine r,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    final current = RoutineService.getCurrentStep(r);
    if (current == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.celebration, size: 48, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                '🎉 Rutin Tamamlandı!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context).tumAdimlariBasariylaTamamladiniz),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(204), color.withAlpha(102)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ŞU ANKİ ADIM',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(204),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (current.description != null) ...[
            const SizedBox(height: 4),
            Text(
              current.description!,
              style: TextStyle(color: Colors.white.withAlpha(230)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, color: Colors.white.withAlpha(204), size: 16),
              const SizedBox(width: 4),
              Text(
                '${current.estimatedDuration} dk',
                style: TextStyle(color: Colors.white.withAlpha(230)),
              ),
              if (current.isFlexible) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.schedule,
                  color: Colors.white.withAlpha(204),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Esnek',
                  style: TextStyle(color: Colors.white.withAlpha(230)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _completeStep(current),
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context).completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _skipStep(current),
                icon: const Icon(Icons.skip_next, color: Colors.white),
                label: const Text(
                  'Atla',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    RoutineStep step,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    final isCompleted = step.status == StepStatus.completed;
    final isSkipped = step.status == StepStatus.skipped;
    final isCurrent = step.status == StepStatus.inProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: isCurrent ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrent
              ? BorderSide(color: color, width: 2)
              : BorderSide.none,
        ),
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? Colors.green.withAlpha(26)
                : isSkipped
                ? Colors.grey.withAlpha(26)
                : isCurrent
                ? color.withAlpha(26)
                : Colors.grey.withAlpha(13),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.green)
                : isSkipped
                ? const Icon(Icons.skip_next, color: Colors.grey)
                : isCurrent
                ? Icon(Icons.play_arrow, color: color)
                : Text('${step.order + 1}', style: TextStyle(color: textColor)),
          ),
          title: Text(
            step.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isSkipped ? Colors.grey : textColor,
              decoration: isSkipped ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${step.estimatedDuration} dk${step.completedBy != null ? ' | ${step.completedBy}' : ''}',
            style: TextStyle(color: Colors.grey[500]),
          ),
          trailing: isCurrent
              ? IconButton(
                  icon: Icon(Icons.check_circle, color: color),
                  onPressed: () => _completeStep(step),
                )
              : isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
    );
  }
}
