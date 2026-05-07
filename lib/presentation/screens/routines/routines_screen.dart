import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/models/routine.dart';
import '../../../repositories/routine_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/routine_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  List<Routine> _routines = [];
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  Future<void> _loadRealData() async {
    setState(() => _loading = true);
    final familyId = await _getFamilyId();
    if (familyId != null) {
      final routines = await RoutineRepository().getRoutines(familyId);
      setState(() {
        _routines = routines;
        _aiSuggestions = routines.isNotEmpty
            ? RoutineService.generateSuggestions(routines.first)
            : [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadRealData();
  }

  void _navigateToCreate() {
    context.push(AppRoutes.routineCreate);
  }

  void _navigateToDetail(Routine routine) {
    context.push('${AppRoutes.routines}/${routine.id}');
  }

  void _startRoutine(Routine routine) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${routine.name} başlatıldı!')),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.orange;
    }
  }

  String _typeLabel(RoutineType type) {
    switch (type) {
      case RoutineType.morning: return 'Sabah';
      case RoutineType.evening: return 'Akşam';
      case RoutineType.weekly: return 'Haftalık';
      case RoutineType.custom: return 'Özel';
      case RoutineType.seasonal: return 'Mevsimsel';
      case RoutineType.eventBased: return 'Etkinlik';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '🌅 Rutinler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFFFF3E0), const Color(0xFFF8F9FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            ],
          ),

          // Active routine card
          if (_routines.any((r) => r.status.state == RoutineState.active))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildActiveRoutineCard(
                  _routines.firstWhere((r) => r.status.state == RoutineState.active),
                  isDark, textColor,
                ),
              ),
            ),

          // AI Suggestions
          if (_aiSuggestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAiSuggestionsCard(isDark, textColor),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Daily routines header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Günlük Rutinler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (_loading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRoutineCard(_routines[index], isDark, textColor),
                childCount: _routines.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Rutin'),
        backgroundColor: AppColors.cobalt,
      ),
    );
  }

  Widget _buildActiveRoutineCard(Routine routine, bool isDark, Color textColor) {
    final color = _parseColor(routine.color);
    final currentStep = RoutineService.getCurrentStep(routine);
    final completed = routine.steps.where((s) => s.status == StepStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(204), color.withAlpha(102)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withAlpha(76), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
                child: Icon(_getIcon(routine.icon), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AKTİF RUTİN', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(204), fontWeight: FontWeight.w600)),
                    Text(routine.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              _buildStatusBadge(routine.status.state),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: routine.status.progress / 100,
              backgroundColor: Colors.white.withAlpha(51),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed/${routine.steps.length} adım | ${routine.estimatedTotalDuration} dk', style: TextStyle(color: Colors.white.withAlpha(230))),
              if (currentStep != null)
                Text('Şu an: ${currentStep.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToDetail(routine),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Devam Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionsCard(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple[400]),
              const SizedBox(width: 8),
              Text('AI Önerileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          ..._aiSuggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(s['type'] == 'new_routine' ? '💡' : s['type'] == 'modify_routine' ? '⚡' : '🔄', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['reason'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('%${((s['confidence'] as double) * 100).toInt()} güven', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                TextButton(onPressed: () { HapticFeedback.lightImpact(); }, child: const Text('Uygula')),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine, bool isDark, Color textColor) {
    final color = _parseColor(routine.color);
    final completed = routine.steps.where((s) => s.status == StepStatus.completed).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        child: InkWell(
          onTap: () => _navigateToDetail(routine),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getIcon(routine.icon), color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routine.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          Text('${routine.estimatedTotalDuration} dk | ${routine.steps.length} adım | ${_typeLabel(routine.type)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    _buildStatusBadge(routine.status.state),
                  ],
                ),
                const SizedBox(height: 12),
                if (routine.status.state == RoutineState.active)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: routine.status.progress / 100,
                      backgroundColor: Colors.grey.withAlpha(26),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  )
                else
                  Row(
                    children: [
                      _buildBadge('📊 $completed/${routine.steps.length}', color),
                      const SizedBox(width: 8),
                      _buildBadge('🔔 ${routine.recurrence.pattern.name}', Colors.blue),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (routine.status.state == RoutineState.scheduled)
                      TextButton.icon(
                        onPressed: () => _startRoutine(routine),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(AppLocalizations.of(context).baslat),
                      ),
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _navigateToDetail(routine)),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _deleteRoutine(routine),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RoutineState state) {
    final labels = {
      RoutineState.scheduled: ('Planlandı', Colors.grey),
      RoutineState.active: ('Aktif', Colors.green),
      RoutineState.paused: ('Duraklatıldı', Colors.orange),
      RoutineState.completed: ('Tamamlandı', Colors.blue),
      RoutineState.cancelled: ('İptal', Colors.red),
    };
    final label = labels[state]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: label.$2.withAlpha(26), borderRadius: BorderRadius.circular(8)),
      child: Text(label.$1, style: TextStyle(fontSize: 11, color: label.$2, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'sunrise': return Icons.wb_sunny;
      case 'moon': return Icons.nightlight_round;
      case 'broom': return Icons.cleaning_services;
      case 'heart': return Icons.favorite;
      case 'book': return Icons.menu_book;
      default: return Icons.schedule;
    }
  }

  void _deleteRoutine(Routine routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rutini Sil'),
        content: Text('"${routine.name}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () {
              setState(() => _routines.removeWhere((r) => r.id == routine.id));
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
