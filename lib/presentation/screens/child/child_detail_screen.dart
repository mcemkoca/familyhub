import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/entities.dart';
import '../../../domain/models/child_account.dart';
import '../../../domain/models/child_development_log.dart';
import '../../../domain/models/child_homework.dart';
import '../../../domain/models/child_schedule.dart';
import '../../../repositories/child_account_repository.dart';
import '../../../repositories/child_streak_repository.dart';
import '../../../repositories/task_repository.dart';

import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildDetailScreen extends ConsumerStatefulWidget {
  final String childId;
  const ChildDetailScreen({super.key, required this.childId});

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChildAccount? _child;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadChild();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChild() async {
    try {
      final child = await ChildAccountRepository().getChildById(widget.childId);
      if (mounted) {
        setState(() {
          _child = child;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Child load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final child = _child;
    if (child == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).cocukDetayi)),
        body: Center(child: Text(AppLocalizations.of(context).cocukBulunamadi)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: child.color,
              child: Text(
                child.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(child.name),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: child.color,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Görevler'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Ödevler'),
            Tab(icon: Icon(Icons.schedule), text: 'Dersler'),
            Tab(icon: Icon(Icons.trending_up), text: 'Gelişim'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Konum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TasksTab(childId: child.id, familyId: child.familyId),
          _HomeworksTab(childId: child.id, familyId: child.familyId),
          _ScheduleTab(childId: child.id, familyId: child.familyId),
          _DevelopmentTab(childId: child.id, familyId: child.familyId),
          _LocationTab(childId: child.id),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TASKS TAB
// ═════════════════════════════════════════════════════════════════════════════
class _TasksTab extends StatefulWidget {
  final String childId;
  final String familyId;
  const _TasksTab({required this.childId, required this.familyId});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final _repo = TaskRepository();

  Future<void> _openAddTask() async {
    final result = await context.push(
      '/add-task',
      extra: {'childId': widget.childId, 'familyId': widget.familyId},
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTask(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Görev Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${task.title}" görevini silmek istiyor musun?',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteTask(task.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Task>>(
          future: _repo.getTasks(widget.familyId),
          builder: (context, snapshot) {
            final tasks =
                snapshot.data
                    ?.where((t) => t.assignedTo == widget.childId)
                    .toList() ??
                [];
            if (tasks.isEmpty) {
              return _EmptyStateWithAction(
                icon: Icons.task_alt,
                text: 'Henüz görev atanmamış',
                subtext: 'Yeni görev eklemek için butona bas',
                actionLabel: 'Yeni Görev Ekle',
                onAction: _openAddTask,
              );
            }
            final pending = tasks
                .where((t) => t.status != TaskStatus.completed)
                .toList();
            final done = tasks
                .where((t) => t.status == TaskStatus.completed)
                .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StreakWidget(childId: widget.childId),
                const SizedBox(height: 20),
                _AddTaskButton(onPressed: _openAddTask),
                const SizedBox(height: 16),
                if (pending.isNotEmpty) ...[
                  _SectionTitle('Bekleyen (${pending.length})'),
                  ...pending.map(
                    (t) => _TaskCard(task: t, onDelete: () => _deleteTask(t)),
                  ),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle('Tamamlanan (${done.length})'),
                  ...done.map(
                    (t) => _TaskCard(
                      task: t,
                      onDelete: () => _deleteTask(t),
                      isDone: true,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOMEWORKS TAB
// ═════════════════════════════════════════════════════════════════════════════
class _HomeworksTab extends StatefulWidget {
  final String childId;
  final String familyId;
  const _HomeworksTab({required this.childId, required this.familyId});

  @override
  State<_HomeworksTab> createState() => _HomeworksTabState();
}

class _HomeworksTabState extends State<_HomeworksTab> {
  final _client = SupabaseConfig.client;
  final _subjectCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;

  Future<void> _showAddHomework() async {
    _subjectCtrl.clear();
    _titleCtrl.clear();
    _descCtrl.clear();
    _priority = 'medium';
    _dueDate = null;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Yeni Ödev Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec(
                  'Ders Adı (Matematik, Türkçe...)',
                  Icons.book,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec('Ödev Başlığı', Icons.assignment),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDec('Açıklama', Icons.description),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF3B82F6),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setModalState(() => _dueDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate == null
                            ? 'Teslim Tarihi Seç'
                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: TextStyle(
                          color: _dueDate == null
                              ? const Color(0xFF9CA3AF)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _createHomework(),
                  child: const Text(
                    'Ödev Ekle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _createHomework() async {
    if (_subjectCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty) {
      return;
    }
    try {
      await _client.from('child_homeworks').insert({
        'family_id': widget.familyId,
        'child_id': widget.childId,
        'subject': _subjectCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'due_date': _dueDate?.toIso8601String(),
        'status': 'pending',
        'created_by': AuthService.currentUserId,
      });
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).odevEklendi),
            backgroundColor: Colors.green,
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

  Future<void> _deleteHomework(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ödev Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu ödevi silmek istiyor musun?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('child_homeworks').delete().eq('id', id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _client
              .from('child_homeworks')
              .select('*')
              .eq('child_id', widget.childId)
              .order('due_date', ascending: true),
          builder: (context, snapshot) {
            final list = (snapshot.data ?? [])
                .map((e) => ChildHomework.fromJson(e as Map<String, dynamic>))
                .toList();
            if (list.isEmpty) {
              return const _EmptyState(
                icon: Icons.assignment_outlined,
                text: 'Henüz ödev eklenmemiş',
                subtext: 'Yeni ödev eklemek için + butonuna bas',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: list
                  .map(
                    (h) => _HomeworkCard(
                      homework: h,
                      onDelete: () => _deleteHomework(h.id),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF3B82F6),
            onPressed: _showAddHomework,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SCHEDULE TAB
// ═════════════════════════════════════════════════════════════════════════════
class _ScheduleTab extends StatefulWidget {
  final String childId;
  final String familyId;
  const _ScheduleTab({required this.childId, required this.familyId});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  final _client = SupabaseConfig.client;
  final _subjectCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int _dayOfWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  Color _color = Colors.blue;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  Future<void> _showAddSchedule() async {
    _subjectCtrl.clear();
    _teacherCtrl.clear();
    _locationCtrl.clear();
    _dayOfWeek = 1;
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 9, minute: 0);
    _color = Colors.blue;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Yeni Ders Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec('Ders Adı', Icons.book),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _teacherCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec(
                  'Öğretmen Adı (isteğe bağlı)',
                  Icons.person,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec(
                  'Sınıf / Lokasyon (isteğe bağlı)',
                  Icons.place,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gün',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 1; i <= 7; i++)
                    ChoiceChip(
                      label: Text(
                        _dayName(i),
                        style: TextStyle(
                          color: _dayOfWeek == i
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      selected: _dayOfWeek == i,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFF334155),
                      onSelected: (_) => setModalState(() => _dayOfWeek = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF3B82F6),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (t != null) setModalState(() => _startTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Başlangıç: ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF3B82F6),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (t != null) setModalState(() => _endTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Bitiş: ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Renk',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colors
                    .map(
                      (c) => GestureDetector(
                        onTap: () => setModalState(() => _color = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _color == c
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: _color == c
                                ? [
                                    BoxShadow(
                                      color: c.withAlpha(150),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _createSchedule(),
                  child: const Text(
                    'Ders Ekle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _createSchedule() async {
    if (_subjectCtrl.text.trim().isEmpty) return;
    try {
      await _client.from('child_schedules').insert({
        'family_id': widget.familyId,
        'child_id': widget.childId,
        'day_of_week': _dayOfWeek,
        'start_time':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
        'subject': _subjectCtrl.text.trim(),
        'teacher': _teacherCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'color':
            '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'is_active': true,
      });
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ders eklendi'),
            backgroundColor: Colors.green,
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

  Future<void> _deleteSchedule(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ders Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu dersi silmek istiyor musun?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('child_schedules').delete().eq('id', id);
      setState(() {});
    }
  }

  static String _dayName(int d) =>
      ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][d];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _client
              .from('child_schedules')
              .select('*')
              .eq('child_id', widget.childId)
              .eq('is_active', true)
              .order('start_time', ascending: true),
          builder: (context, snapshot) {
            final list = (snapshot.data ?? [])
                .map((e) => ChildSchedule.fromJson(e as Map<String, dynamic>))
                .toList();
            if (list.isEmpty) {
              return const _EmptyState(
                icon: Icons.schedule,
                text: 'Henüz ders eklenmemiş',
                subtext: 'Yeni ders eklemek için + butonuna bas',
              );
            }
            final scheduleChildren = <Widget>[];
            for (int day = 1; day <= 7; day++) {
              final dayItems = list.where((s) => s.dayOfWeek == day).toList();
              if (dayItems.isNotEmpty) {
                scheduleChildren.add(_SectionTitle(_dayName(day)));
                scheduleChildren.addAll(
                  dayItems.map(
                    (s) => _ScheduleCard(
                      schedule: s,
                      onDelete: () => _deleteSchedule(s.id),
                    ),
                  ),
                );
                scheduleChildren.add(const SizedBox(height: 12));
              }
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: scheduleChildren,
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF3B82F6),
            onPressed: _showAddSchedule,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DEVELOPMENT TAB
// ═════════════════════════════════════════════════════════════════════════════
class _DevelopmentTab extends StatefulWidget {
  final String childId;
  final String familyId;
  const _DevelopmentTab({required this.childId, required this.familyId});

  @override
  State<_DevelopmentTab> createState() => _DevelopmentTabState();
}

class _DevelopmentTabState extends State<_DevelopmentTab> {
  final _client = SupabaseConfig.client;
  final _valueCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DevelopmentLogType _logType = DevelopmentLogType.height;

  Future<void> _showAddLog() async {
    _valueCtrl.clear();
    _unitCtrl.clear();
    _notesCtrl.clear();
    _logType = DevelopmentLogType.height;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Yeni Gelişim Kaydı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: DevelopmentLogType.values
                    .map(
                      (t) => ChoiceChip(
                        label: Text(
                          _typeLabel(t),
                          style: TextStyle(
                            color: _logType == t
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        selected: _logType == t,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: const Color(0xFF334155),
                        onSelected: (_) => setModalState(() => _logType = t),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _valueCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('Değer', Icons.straighten),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDec('Birim', Icons.scale),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDec('Notlar', Icons.notes),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _createLog(),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _createLog() async {
    if (_valueCtrl.text.trim().isEmpty) return;
    try {
      await _client.from('child_development_logs').insert({
        'family_id': widget.familyId,
        'child_id': widget.childId,
        'log_type': _logType.name,
        'value': _valueCtrl.text.trim(),
        'unit': _unitCtrl.text.trim(),
        'logged_at': DateTime.now().toIso8601String().substring(0, 10),
        'notes': _notesCtrl.text.trim(),
        'created_by': AuthService.currentUserId,
      });
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kaydedildi'),
            backgroundColor: Colors.green,
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

  Future<void> _deleteLog(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Kayıt Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu kaydı silmek istiyor musun?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('child_development_logs').delete().eq('id', id);
      setState(() {});
    }
  }

  String _typeLabel(DevelopmentLogType t) {
    return switch (t) {
      DevelopmentLogType.height => 'Boy',
      DevelopmentLogType.weight => 'Kilo',
      DevelopmentLogType.mood => 'Ruh Hali',
      DevelopmentLogType.milestone => 'Kazanım',
      DevelopmentLogType.note => 'Not',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _client
              .from('child_development_logs')
              .select('*')
              .eq('child_id', widget.childId)
              .order('logged_at', ascending: false)
              .limit(50),
          builder: (context, snapshot) {
            final list = (snapshot.data ?? [])
                .map(
                  (e) =>
                      ChildDevelopmentLog.fromJson(e as Map<String, dynamic>),
                )
                .toList();
            if (list.isEmpty) {
              return const _EmptyState(
                icon: Icons.trending_up,
                text: 'Henüz gelişim kaydı yok',
                subtext: 'Yeni kayıt eklemek için + butonuna bas',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: list
                  .map(
                    (l) => _DevelopmentCard(
                      log: l,
                      onDelete: () => _deleteLog(l.id),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF3B82F6),
            onPressed: _showAddLog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOCATION TAB
// ═════════════════════════════════════════════════════════════════════════════
class _LocationTab extends StatelessWidget {
  final String childId;
  const _LocationTab({required this.childId});

  @override
  Widget build(BuildContext context) {
    final client = SupabaseConfig.client;
    return FutureBuilder<Map<String, dynamic>?>(
      future: client
          .from('geolocations')
          .select('*')
          .eq('child_id', childId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      builder: (context, snapshot) {
        final loc = snapshot.data;
        if (loc == null) {
          return const _EmptyState(
            icon: Icons.location_off,
            text: 'Konum verisi yok',
            subtext: 'Çocuk henüz konum paylaşmamış',
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green.shade400),
                        const SizedBox(width: 8),
                        const Text(
                          'Son Konum',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lat: ${(loc['lat'] as num?)?.toStringAsFixed(6) ?? '-'}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Lng: ${(loc['lng'] as num?)?.toStringAsFixed(6) ?? '-'}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (loc['accuracy'] != null)
                      Text(
                        'Doğruluk: ${(loc['accuracy'] as num?)?.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    if (loc['battery_level'] != null)
                      Text(
                        'Pil: ${loc['battery_level']}%',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(loc['created_at']),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STREAK WIDGET — Canlı Takip
// ═════════════════════════════════════════════════════════════════════════════
class _StreakWidget extends StatelessWidget {
  final String childId;
  const _StreakWidget({required this.childId});

  @override
  Widget build(BuildContext context) {
    final repo = ChildStreakRepository();

    return StreamBuilder<StreakStats>(
      stream: repo.watchStreakStats(childId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            const StreakStats(
              currentStreak: 0,
              bestStreak: 0,
              totalCompleted: 0,
              weeklyView: {},
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana Streak Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.currentStreak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'günlük seri',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Alt Kartlar
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${stats.bestStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'En iyi',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.format_list_numbered,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${stats.totalCompleted}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Toplam',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Haftalık Görünüm
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HAFTALIK GÖRÜNÜM',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int i = 1; i <= 7; i++)
                        _DayDot(
                          day: _dayShort(i),
                          isCompleted: stats.weeklyView[i] ?? false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _dayShort(int d) {
    return ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][d];
  }
}

class _DayDot extends StatelessWidget {
  final String day;
  final bool isCompleted;
  const _DayDot({required this.day, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFF334155),
            shape: BoxShape.circle,
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(80),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            color: isCompleted ? Colors.white : const Color(0xFF6B7280),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED UI COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String subtext;
  const _EmptyState({
    required this.icon,
    required this.text,
    required this.subtext,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: const Color(0xFF6B7280)),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    ),
  );
}

class _EmptyStateWithAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final String subtext;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyStateWithAction({
    required this.icon,
    required this.text,
    required this.subtext,
    required this.actionLabel,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: const Color(0xFF6B7280)),
        const SizedBox(height: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 220,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              actionLabel,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            onPressed: onAction,
          ),
        ),
      ],
    ),
  );
}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddTaskButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Görev Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Çocuğuna yeni bir görev ata',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    ),
  );
}

InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
  prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
  filled: true,
  fillColor: const Color(0xFF334155),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
  ),
);

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final bool isDone;
  const _TaskCard({
    required this.task,
    required this.onDelete,
    this.isDone = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? Colors.green : const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  color: isDone ? const Color(0xFF6B7280) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Text(
                  task.description!,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ],
    ),
  );
}

class _HomeworkCard extends StatelessWidget {
  final ChildHomework homework;
  final VoidCallback onDelete;
  const _HomeworkCard({required this.homework, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final isOverdue = homework.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: isOverdue ? Border.all(color: Colors.red.withAlpha(60)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.red.withAlpha(20)
                  : Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment,
              color: isOverdue ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${homework.subject} • ${homework.displayStatus}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                if (homework.dueDate != null)
                  Text(
                    'Teslim: ${homework.dueDate!.day}/${homework.dueDate!.month}/${homework.dueDate!.year}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ChildSchedule schedule;
  final VoidCallback onDelete;
  const _ScheduleCard({required this.schedule, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: schedule.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${schedule.startTime} - ${schedule.endTime}${schedule.teacher != null && schedule.teacher!.isNotEmpty ? ' • ${schedule.teacher}' : ''}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ],
    ),
  );
}

class _DevelopmentCard extends StatelessWidget {
  final ChildDevelopmentLog log;
  final VoidCallback onDelete;
  const _DevelopmentCard({required this.log, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.trending_up, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.displayType}: ${log.displayValue}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}${log.notes != null && log.notes!.isNotEmpty ? ' • ${log.notes}' : ''}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDelete,
        ),
      ],
    ),
  );
}
