import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../domain/models/smart_rotation.dart';
import '../../../services/smart_rotation_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SmartRotationScreen extends StatefulWidget {
  final String? familyId;
  const SmartRotationScreen({super.key, this.familyId});

  @override
  State<SmartRotationScreen> createState() => _SmartRotationScreenState();
}

class _SmartRotationScreenState extends State<SmartRotationScreen> {
  List<RotationMember> _members = [];
  List<RotationTask> _tasks = [];
  FairnessRules _rules = const FairnessRules(familyId: '');
  RotationResult? _result;
  bool _loading = false;
  bool _showRules = false;
  bool _pageLoading = true;
  String? _error;
  Map<String, _MemberWorkload> _workloads = {};

  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => _pageLoading = true);
    try {
      // familyId'yi bul
      String familyId;
      if (widget.familyId != null && widget.familyId!.isNotEmpty) {
        familyId = widget.familyId!;
      } else {
        final user = _client.auth.currentUser;
        if (user == null) throw Exception('Oturum yok');
        final profile = await _client.from('profiles').select('family_id').eq('id', user.id).maybeSingle();
        if (profile == null || profile['family_id'] == null) {
          throw Exception('Aile bilgisi bulunamadı');
        }
        familyId = profile['family_id'] as String;
      }

      // Aile üyelerini çek (profiles + child_accounts)
      final List<Map<String, dynamic>> profiles = await _client.from('profiles').select('id, display_name, avatar_url').eq('family_id', familyId);
      final List<Map<String, dynamic>> children = await _client.from('child_accounts').select('id, name, color').eq('family_id', familyId);

      final memberList = <RotationMember>[];
      for (final p in profiles) {
        memberList.add(RotationMember(
          id: p['id'] as String,
          name: (p['display_name'] as String?) ?? 'Üye',
          avatar: p['avatar_url'] as String?,
          age: 0,
          workload: const MemberWorkload(),
          energyProfile: const EnergyProfile(),
          notifications: const NotificationPrefs(),
        ));
      }
      for (final c in children) {
        memberList.add(RotationMember(
          id: c['id'] as String,
          name: (c['name'] as String?) ?? 'Çocuk',
          age: 0,
          workload: const MemberWorkload(),
          energyProfile: const EnergyProfile(),
          notifications: const NotificationPrefs(),
        ));
      }

      // Bekleyen görevleri çek
      final List<Map<String, dynamic>> tasksRaw = await _client.from('tasks').select('*').eq('family_id', familyId).eq('status', 'pending').order('created_at', ascending: false);
      final taskList = tasksRaw.map((t) {
        final priority = (t['priority'] ?? 'medium') as String;
        final estMinutes = switch (priority) {
          'high' => 60,
          'medium' => 30,
          'low' => 15,
          _ => 30,
        };
        return RotationTask(
          id: t['id'] as String,
          title: (t['title'] as String?) ?? 'Görev',
          category: _priorityToCategory(priority),
          estimatedDuration: estMinutes,
          assignedTo: t['assigned_to'] as String?,
          createdBy: (t['created_by'] as String?) ?? '',
          createdAt: DateTime.tryParse((t['created_at'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();

      // Son 30 gündeki görev dağılımını çek (adalet durumu için)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final List<Map<String, dynamic>> allTasks = await _client.from('tasks').select('*').eq('family_id', familyId).gte('created_at', thirtyDaysAgo);
      final workloads = <String, _MemberWorkload>{};
      for (final t in allTasks) {
        final assignedTo = t['assigned_to'] as String?;
        if (assignedTo != null) {
          workloads.putIfAbsent(assignedTo, _MemberWorkload.new);
          workloads[assignedTo]!.assignedCount++;
          if (t['status'] == 'completed') {
            workloads[assignedTo]!.completedCount++;
          }
        }
      }

      // Kuralları yükle (yoksa default)
      FairnessRules rules;
      try {
        final rulesRaw = await _client.from('rotation_rules').select('*').eq('family_id', familyId).maybeSingle();
        if (rulesRaw != null) {
          rules = FairnessRules(
            familyId: familyId,
            weights: FairnessWeights(
              equalTime: (rulesRaw['equal_time'] as int?) ?? 40,
              skillMatch: (rulesRaw['skill_match'] as int?) ?? 20,
              energyAware: (rulesRaw['energy_aware'] as int?) ?? 20,
              preference: (rulesRaw['preference'] as int?) ?? 10,
              streakBalance: (rulesRaw['streak_balance'] as int?) ?? 10,
            ),
          );
        } else {
          rules = FairnessRules(familyId: familyId);
        }
      } catch (_) {
        rules = FairnessRules(familyId: familyId);
      }

      setState(() {
        _members = memberList;
        _tasks = taskList;
        _rules = rules;
        _workloads = workloads;
        _pageLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _pageLoading = false;
      });
    }
  }

  static TaskCategory _priorityToCategory(String priority) {
    return switch (priority) {
      'high' => TaskCategory.cleaning,
      'low' => TaskCategory.shopping,
      _ => TaskCategory.cooking,
    };
  }

  Future<void> _runRotation() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final result = await SmartRotationService.distributeTasks(
      tasks: _tasks,
      members: _members,
      rules: _rules,
    );
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _acceptAssignment(Assignment a) async {
    final idx = _tasks.indexWhere((t) => t.id == a.taskId);
    if (idx >= 0) {
      try {
        await _client.from('tasks').update({
          'assigned_to': a.memberId,
          'status': 'pending',
        }).eq('id', a.taskId);
        setState(() {
          _tasks[idx] = _tasks[idx].copyWith(
            assignedTo: a.memberId,
            assignedAt: DateTime.now(),
            status: RotationStatus.pending,
          );
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Atama kaydedilemedi: $e')),
          );
        }
      }
    }
    HapticFeedback.lightImpact();
  }

  void _rejectAssignment(String taskId) async {
    try {
      await _client.from('tasks').update({
        'status': 'rejected',
      }).eq('id', taskId);
      setState(() {
        _tasks = _tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(status: RotationStatus.rejected);
          }
          return t;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reddetme kaydedilemedi: $e')),
        );
      }
    }
  }

  void _toggleRules() => setState(() => _showRules = !_showRules);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).akilliGorevRotasyonu),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRealData,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.rule_folder_outlined),
            onPressed: _toggleRules,
            tooltip: 'Adalet Kuralları',
          ),
        ],
      ),
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(isDark)
              : _showRules
                  ? _buildRulesEditor(isDark)
                  : _buildMainContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Veriler yüklenemedi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.slate),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRealData,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).tryAgain),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.cobalt, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          _buildHeader(isDark),
          const SizedBox(height: 20),

          // Adalet Durumu
          _buildFairnessStatus(isDark),
          const SizedBox(height: 20),

          // Yeniden Dağıt Butonu
          _buildDistributeButton(isDark),
          const SizedBox(height: 20),

          // Dağıtım Sonucu
          if (_loading)
            _buildLoading(isDark)
          else if (_result != null)
            _buildDistributionResult(isDark)
          else
            _buildEmptyState(isDark),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cobalt,
            AppColors.cobalt.withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Akıllı Görev Rotasyonu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Otomatik dağıtım + Adalet algoritması',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_tasks.where((t) => t.status == RotationStatus.pending && t.assignedTo == null).length} bekleyen görev • ${_members.length} aile üyesi',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFairnessStatus(bool isDark) {
    final maxAssigned = _workloads.values.isEmpty
        ? 1
        : _workloads.values.map((w) => w.assignedCount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: AppColors.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aile Adalet Durumu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._members.map((m) {
            final wl = _workloads[m.id] ?? _MemberWorkload();
            final assigned = wl.assignedCount;
            final completed = wl.completedCount;
            final percent = maxAssigned > 0 ? assigned / maxAssigned : 0.0;
            final completionRate = assigned > 0 ? (completed / assigned * 100).toInt() : 0;
            final color = percent > 0.8
                ? AppColors.error
                : percent > 0.5
                    ? AppColors.orange
                    : AppColors.success;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _memberColor(m.id),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: Text(
                      m.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent.clamp(0.05, 1.0),
                            minHeight: 10,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completed / $assigned tamamlandı',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completionRate%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Divider(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genel memnuniyet:',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_result!.metrics.memberSatisfaction.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributeButton(bool isDark) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _runRotation,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.shuffle, color: Colors.white),
        label: Text(
          _loading ? 'AI optimizasyonu çalışıyor...' : '🔄 YENİDEN DAĞIT',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cobalt,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cobalt),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Adalet algoritması görevleri dağıtıyor...',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Genetik optimizasyon + Eşit yük dengelemesi',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 56,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightGray,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz dağıtım yapılmadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yeniden Dağıt butonuna basarak AI\'nın adil görev dağıtımını görebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionResult(bool isDark) {
    final assignments = _result!.assignments;
    final grouped = <String, List<Assignment>>{};
    for (final a in assignments) {
      grouped.putIfAbsent(a.memberId, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrikler
        _buildMetricsBar(isDark),
        const SizedBox(height: 16),

        // Atama başlığı
        Text(
          'Bugünkü Dağıtım (${DateTime.now().day} ${_monthName(DateTime.now().month)})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
          ),
        ),
        const SizedBox(height: 12),

        // Her üye için kart
        ...grouped.entries.map((entry) {
          final member = _members.firstWhere((m) => m.id == entry.key);
          final memberTasks = entry.value;
          final totalMinutes = memberTasks.fold<int>(
            0,
            (sum, a) => sum + _tasks.firstWhere((t) => t.id == a.taskId).estimatedDuration,
          );

          return _buildMemberAssignmentCard(
            isDark: isDark,
            member: member,
            assignments: memberTasks,
            totalMinutes: totalMinutes,
          );
        }),

        // AI Önerileri
        if (_result!.metrics.memberSatisfaction < 70) ...[
          const SizedBox(height: 16),
          _buildAiSuggestions(isDark),
        ],
      ],
    );
  }

  Widget _buildMetricsBar(bool isDark) {
    final m = _result!.metrics;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFBAE6FD),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricItem('Beceri Eşleşme', '${m.skillMatchRate.toStringAsFixed(0)}%', Icons.psychology),
          _metricItem('Enerji Opt.', '${m.energyOptimization.toStringAsFixed(0)}%', Icons.bolt),
          _metricItem('Workload Fark', '${m.maxWorkloadDiff.toStringAsFixed(0)} dk', Icons.timer),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.cobalt),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.cobalt,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAssignmentCard({
    required bool isDark,
    required RotationMember member,
    required List<Assignment> assignments,
    required int totalMinutes,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _memberColor(member.id),
                child: Text(
                  member.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                      ),
                    ),
                    Text(
                      'Toplam: $totalMinutes dk',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalMinutes > 90)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Yüksek',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...assignments.map((a) {
            final task = _tasks.firstWhere((t) => t.id == a.taskId);
            return _buildTaskRow(isDark, task, a);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskRow(bool isDark, RotationTask task, Assignment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.estimatedDuration} dk | ${_categoryEmoji(task.category)} ${_categoryLabel(task.category)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                  ),
                ),
                if (a.predictedCompletion > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.cobalt.withAlpha(180)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            a.reason,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.cobalt.withAlpha(180),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (task.assignedTo == null) ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              onPressed: () => _acceptAssignment(a),
              tooltip: 'Onayla',
              iconSize: 22,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              onPressed: () => _rejectAssignment(task.id),
              tooltip: 'Reddet',
              iconSize: 22,
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Atandı',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFFFF176),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                'AI Önerileri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Workload farkı ${_result!.metrics.maxWorkloadDiff.toStringAsFixed(0)} dakika. Daha iyi denge için görev sayısını artırın veya süreleri ayarlayın.\n'
            '• Beceri eşleşme oranı %${_result!.metrics.skillMatchRate.toStringAsFixed(0)}. Üye becerilerini güncellemek daha iyi dağıtım sağlar.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── KURALLAR EDİTÖRÜ ────────────────────────────────────────────────────

  Widget _buildRulesEditor(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleRules,
              ),
              const SizedBox(width: 8),
              Text(
                'Adalet Kuralları & Ağırlıklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ağırlıklar
          _buildWeightSlider(
            isDark,
            'Eşit Zaman Dağılımı',
            _rules.weights.equalTime,
            'Herkes eşit süre çalışsın',
            (v) => setState(() => _rules = FairnessRules(
              familyId: _rules.familyId,
              weights: FairnessWeights(
                equalTime: v.toInt(),
                skillMatch: _rules.weights.skillMatch,
                energyAware: _rules.weights.energyAware,
                preference: _rules.weights.preference,
                streakBalance: _rules.weights.streakBalance,
              ),
              constraints: _rules.constraints,
              specialRules: _rules.specialRules,
              rewards: _rules.rewards,
            )),
          ),
          _buildWeightSlider(
            isDark,
            'Beceri Eşleştirmesi',
            _rules.weights.skillMatch,
            'Doğru kişi, doğru iş',
            (v) => setState(() => _rules = FairnessRules(
              familyId: _rules.familyId,
              weights: FairnessWeights(
                equalTime: _rules.weights.equalTime,
                skillMatch: v.toInt(),
                energyAware: _rules.weights.energyAware,
                preference: _rules.weights.preference,
                streakBalance: _rules.weights.streakBalance,
              ),
              constraints: _rules.constraints,
              specialRules: _rules.specialRules,
              rewards: _rules.rewards,
            )),
          ),
          _buildWeightSlider(
            isDark,
            'Enerji Seviyesi',
            _rules.weights.energyAware,
            'Yorgun kişiye az görev',
            (v) => setState(() => _rules = FairnessRules(
              familyId: _rules.familyId,
              weights: FairnessWeights(
                equalTime: _rules.weights.equalTime,
                skillMatch: _rules.weights.skillMatch,
                energyAware: v.toInt(),
                preference: _rules.weights.preference,
                streakBalance: _rules.weights.streakBalance,
              ),
              constraints: _rules.constraints,
              specialRules: _rules.specialRules,
              rewards: _rules.rewards,
            )),
          ),
          _buildWeightSlider(
            isDark,
            'Kişisel Tercihler',
            _rules.weights.preference,
            'Sevdiği işleri yapsın',
            (v) => setState(() => _rules = FairnessRules(
              familyId: _rules.familyId,
              weights: FairnessWeights(
                equalTime: _rules.weights.equalTime,
                skillMatch: _rules.weights.skillMatch,
                energyAware: _rules.weights.energyAware,
                preference: v.toInt(),
                streakBalance: _rules.weights.streakBalance,
              ),
              constraints: _rules.constraints,
              specialRules: _rules.specialRules,
              rewards: _rules.rewards,
            )),
          ),

          const SizedBox(height: 20),

          // Özel Kurallar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özel Kurallar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 12),
                ..._rules.specialRules.map((rule) => _buildRuleItem(isDark, rule)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Ödül Sistemi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withAlpha(20) : Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ödül Sistemi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRewardRow('Görev başına puan', _rules.rewards.pointsPerTask),
                _buildRewardRow('Streak bonusu', _rules.rewards.bonusForStreak),
                _buildRewardRow('Kalite bonusu', _rules.rewards.bonusForQuality),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(
    bool isDark,
    String label,
    int value,
    String description,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cobalt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.cobalt,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(bool isDark, SpecialRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            rule.isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: rule.isActive ? AppColors.success : AppColors.lightGray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
                Text(
                  '${rule.condition} → ${rule.action}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cobalt.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$value',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.cobalt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── YARDIMCI ────────────────────────────────────────────────────────────

  Color _memberColor(String id) {
    final colors = [
      AppColors.blue,
      AppColors.pink,
      AppColors.orange,
      AppColors.success,
      AppColors.purple,
    ];
    return colors[id.hashCode % colors.length];
  }

  String _categoryEmoji(TaskCategory cat) {
    const map = {
      TaskCategory.cleaning: '🧹',
      TaskCategory.cooking: '🍳',
      TaskCategory.shopping: '🛒',
      TaskCategory.maintenance: '🔧',
      TaskCategory.education: '📚',
      TaskCategory.social: '👥',
      TaskCategory.admin: '📋',
      TaskCategory.urgent: '🚨',
    };
    return map[cat] ?? '📌';
  }

  String _categoryLabel(TaskCategory cat) {
    const map = {
      TaskCategory.cleaning: 'Temizlik',
      TaskCategory.cooking: 'Yemek',
      TaskCategory.shopping: 'Alışveriş',
      TaskCategory.maintenance: 'Bakım',
      TaskCategory.education: 'Eğitim',
      TaskCategory.social: 'Sosyal',
      TaskCategory.admin: 'İdari',
      TaskCategory.urgent: 'Acil',
    };
    return map[cat] ?? 'Genel';
  }

  String _monthName(int month) {
    const names = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return names[month];
  }
}

class _MemberWorkload {
  int assignedCount = 0;
  int completedCount = 0;
}
