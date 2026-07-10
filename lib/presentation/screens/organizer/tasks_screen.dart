import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/entities.dart';
import '../../../repositories/task_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/family_avatar.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _titleController = TextEditingController();
  final _editController = TextEditingController();
  final _descController = TextEditingController();
  final _editDescController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  DateTime? _editDueDate;
  String _assignedTo = '';
  String _editAssignedTo = '';

  final _priorities = [
    {'key': 'low', 'label': 'Düşük', 'color': AppColors.green},
    {'key': 'medium', 'label': 'Orta', 'color': AppColors.blue},
    {'key': 'high', 'label': 'Yüksek', 'color': AppColors.orange},
    {'key': 'urgent', 'label': 'Acil', 'color': AppColors.red},
  ];

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await AuthService.safeClient
        ?.from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  StreamSubscription<List<Task>>? _tasksSub;

  Future<void> _loadTasks() async {
    final familyId = await _getFamilyId() ?? 'local_family';
    final tasks = await TaskRepository().getTasks(familyId);
    ref.read(tasksProvider.notifier).state = tasks;
    await HiveService.saveTasks(tasks);
  }

  void _subscribeToTasks() async {
    final familyId = await _getFamilyId();
    if (familyId == null) return; // yerel modda realtime yok, cache yeterli
    _tasksSub?.cancel();
    _tasksSub = TaskRepository().watchTasks(familyId).listen((tasks) {
      ref.read(tasksProvider.notifier).state = tasks;
      HiveService.saveTasks(tasks);
    }, onError: (e) => debugPrint('Tasks stream error: $e'));
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _subscribeToTasks();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _titleController.dispose();
    _editController.dispose();
    _descController.dispose();
    _editDescController.dispose();
    super.dispose();
  }

  void _addTask() async {
    if (_titleController.text.isEmpty) {
      _showSnack('Görev başlığı boş olamaz');
      return;
    }
    try {
      final familyId = await _getFamilyId() ?? 'local_family';
      final userId = AuthService.currentUserId ?? '';
      final newTask = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descController.text.isEmpty ? null : _descController.text,
        assignedTo: _assignedTo.isEmpty ? userId : _assignedTo,
        priority: _selectedPriority,
        dueDate: _dueDate,
      );
      await TaskRepository().createTask(newTask, familyId);
      if (!mounted) return;
      _titleController.clear();
      _descController.clear();
      _selectedPriority = 'medium';
      _dueDate = null;
      _assignedTo = '';
      Navigator.pop(context);
      _showSnack('Görev eklendi');
    } catch (e) {
      _showSnack('Görev eklenirken hata: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _editTask(Task task, List<FamilyMember> members) {
    _editController.text = task.title;
    _editDescController.text = task.description ?? '';
    _selectedPriority = task.priority;
    _editDueDate = task.dueDate;
    _editAssignedTo = task.assignedTo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).goreviDuzenle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).taskTitle),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _editDescController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).description),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _priorities.map((p) {
                    final selected = _selectedPriority == p['key'];
                    return ChoiceChip(
                      label: Text(p['label'] as String),
                      selected: selected,
                      onSelected: (_) => setModalState(
                        () => _selectedPriority = p['key'] as String,
                      ),
                      selectedColor: (p['color'] as Color).withAlpha(30),
                      checkmarkColor: p['color'] as Color,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6366F1),
                  ),
                  title: Text(
                    _editDueDate == null
                        ? 'Bitiş Tarihi Seç'
                        : 'Bitiş: ${_editDueDate!.day}/${_editDueDate!.month}/${_editDueDate!.year}',
                  ),
                  trailing: _editDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setModalState(() => _editDueDate = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _editDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => _editDueDate = picked);
                    }
                  },
                ),
                if (members.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _editAssignedTo.isEmpty
                        ? null
                        : _editAssignedTo,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).atananKisi),
                    items: members.map((m) {
                      return DropdownMenuItem(value: m.id, child: Text(m.name));
                    }).toList(),
                    onChanged: (v) =>
                        setModalState(() => _editAssignedTo = v ?? ''),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_editController.text.isEmpty) {
                          _showSnack('Görev başlığı boş olamaz');
                          return;
                        }
                        try {
                          final updated = task.copyWith(
                            title: _editController.text,
                            description: _editDescController.text.isEmpty
                                ? null
                                : _editDescController.text,
                            priority: _selectedPriority,
                            dueDate: _editDueDate,
                          );
                          final updatedTask =
                              _editAssignedTo.isNotEmpty &&
                                  _editAssignedTo != task.assignedTo
                              ? updated.copyWith(assignedTo: _editAssignedTo)
                              : updated;
                          await TaskRepository().updateTask(updatedTask);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _showSnack('Görev güncellendi');
                        } catch (e) {
                          _showSnack('Görev güncellenirken hata: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleTask(Task task) async {
    try {
      final updated = task.copyWith(
        status: task.status == TaskStatus.completed
            ? TaskStatus.pending
            : TaskStatus.completed,
        completedAt: task.status == TaskStatus.completed ? null : DateTime.now(),
      );
      await TaskRepository().updateTask(updated);
    } catch (e) {
      _showSnack('Durum değiştirilirken hata: $e');
    }
  }

  void _deleteTask(Task task) async {
    try {
      await TaskRepository().deleteTask(task.id);
    } catch (e) {
      _showSnack('Silinirken hata: $e');
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text('"${task.title}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await TaskRepository().deleteTask(task.id);
    }
  }

  void _showAddSheet(List<FamilyMember> members) {
    _titleController.clear();
    _descController.clear();
    _selectedPriority = 'medium';
    _dueDate = null;
    _assignedTo = members.isNotEmpty ? members.first.id : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).yeniGorev,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).taskTitle),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (opsiyonel)',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _priorities.map((p) {
                    final selected = _selectedPriority == p['key'];
                    return ChoiceChip(
                      label: Text(p['label'] as String),
                      selected: selected,
                      onSelected: (_) => setModalState(
                        () => _selectedPriority = p['key'] as String,
                      ),
                      selectedColor: (p['color'] as Color).withAlpha(30),
                      checkmarkColor: p['color'] as Color,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6366F1),
                  ),
                  title: Text(
                    _dueDate == null
                        ? 'Bitiş Tarihi Seç (opsiyonel)'
                        : 'Bitiş: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                  trailing: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setModalState(() => _dueDate = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModalState(() => _dueDate = picked);
                  },
                ),
                if (members.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _assignedTo.isEmpty ? null : _assignedTo,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).atananKisi),
                    items: members.map((m) {
                      return DropdownMenuItem(value: m.id, child: Text(m.name));
                    }).toList(),
                    onChanged: (v) =>
                        setModalState(() => _assignedTo = v ?? ''),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Ekle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent':
        return AppColors.red;
      case 'high':
        return AppColors.orange;
      case 'low':
        return AppColors.green;
      default:
        return AppColors.blue;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'urgent':
        return 'Acil';
      case 'high':
        return 'Yüksek';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final members = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).tasks),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: AppLocalizations.of(context).akilliRotasyon,
            onPressed: () => context.push(AppRoutes.smartRotation),
          ),
        ],
      ),
      body: Stack(
        children: [
          tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt, size: 64, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context).henuzGorevYok,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Yeni görev eklemek için + butonuna basın',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final member = members.firstWhere(
                      (m) => m.id == task.assignedTo,
                      orElse: () => members.first,
                    );
                    final isCompleted = task.status == TaskStatus.completed;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _editTask(task, members),
                              backgroundColor: AppColors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            SlidableAction(
                              onPressed: (_) => _deleteTask(task),
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withAlpha(20)
                                  : const Color(0xFFF3F4F6),
                            ),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _toggleTask(task),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.green
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted
                                        ? AppColors.green
                                        : Colors.white.withAlpha(80),
                                    width: 2,
                                  ),
                                ),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted ? const Color(0xFF6B7280) : null,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _priorityColor(task.priority),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  _priorityLabel(task.priority),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FamilyAvatar(member: member, size: 32),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Color(0xFF6366F1),
                                  ),
                                  onPressed: () => _editTask(task, members),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _confirmDeleteTask(task),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: FloatingActionButton(
              onPressed: () => _showAddSheet(members),
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
