import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';

class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  void _persist(List<StreakEntry> entries) {
    ref.read(streakEntriesProvider.notifier).state = entries;
    HiveService.saveStreaks(entries);
  }

  void _addEntry() {
    if (_titleController.text.isEmpty) return;
    final current = ref.read(streakEntriesProvider);
    final newEntry = StreakEntry(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      date: DateTime.now(),
      completed: true,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    _persist([...current, newEntry]);
    _titleController.clear();
    _noteController.clear();
    Navigator.pop(context);
  }

  void _deleteEntry(String id) {
    final current = ref.read(streakEntriesProvider);
    _persist(current.where((e) => e.id != id).toList());
  }

  void _toggleEntry(StreakEntry entry) {
    final current = ref.read(streakEntriesProvider);
    final updated = current.map((e) {
      if (e.id == entry.id) {
        return StreakEntry(
          id: e.id,
          title: e.title,
          date: e.date,
          completed: !e.completed,
          note: e.note,
        );
      }
      return e;
    }).toList();
    _persist(updated);
  }

  void _showAddSheet() {
    _titleController.clear();
    _noteController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Streak Ekle',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).strTitleHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).strNoteHint,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _addEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  int _calculateCurrentStreak(List<StreakEntry> entries) {
    if (entries.isEmpty) return 0;
    final sorted = entries.where((e) => e.completed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    final today = DateTime(checkDate.year, checkDate.month, checkDate.day);

    for (final entry in sorted) {
      final entryDay = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (entryDay.isAtSameMomentAs(checkDate) ||
          (streak == 0 &&
              entryDay.isAtSameMomentAs(
                today.subtract(const Duration(days: 1)),
              ))) {
        streak++;
        checkDate = entryDay.subtract(const Duration(days: 1));
      } else if (entryDay.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = entryDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateBestStreak(List<StreakEntry> entries) {
    if (entries.isEmpty) return 0;
    final completed =
        entries
            .where((e) => e.completed)
            .map((e) {
              return DateTime(e.date.year, e.date.month, e.date.day);
            })
            .toSet()
            .toList()
          ..sort();

    if (completed.isEmpty) return 0;
    int best = 1;
    int current = 1;
    for (int i = 1; i < completed.length; i++) {
      final diff = completed[i].difference(completed[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(streakEntriesProvider);
    final streakCount = _calculateCurrentStreak(entries);
    final bestStreak = _calculateBestStreak(entries);

    // Weekly view
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayEntries = entries.where((e) {
        final ed = e.date;
        return e.completed &&
            ed.year == day.year &&
            ed.month == day.month &&
            ed.day == day.day;
      });
      return {'day': day, 'active': dayEntries.isNotEmpty};
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).strTitle,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.streakGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withAlpha(40),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(AppLocalizations.of(context).gunlukSeri,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildStatCard(
                        'En İyi',
                        '$bestStreak',
                        Icons.emoji_events,
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Toplam',
                        '${entries.length}',
                        Icons.format_list_numbered,
                        const Color(0xFF10B981),
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).haftalikGorunum,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: weekDays.map((d) {
                            final day = d['day'] as DateTime;
                            final active = d['active'] as bool;
                            final dayName = DateFormat(
                              'E',
                              'tr_TR',
                            ).format(day);
                            return _buildDayCircle(
                              dayName.substring(0, 3),
                              active,
                              isDark,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (entries.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppLocalizations.of(context).tumGirisler,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entries.map(
                      (e) => _StreakEntryTile(
                        entry: e,
                        isDark: isDark,
                        onToggle: () => _toggleEntry(e),
                        onDelete: () => _deleteEntry(e.id),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showAddSheet,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context).strAddNew),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE5E7EB),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day, bool active, bool isDark) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange.withAlpha(40)
                : (const Color(0xFF0A0A0F)),
            shape: BoxShape.circle,
          ),
          child: active
              ? const Icon(
                  Icons.local_fire_department,
                  color: AppColors.orange,
                  size: 20,
                )
              : const Icon(
                  Icons.circle,
                  color: Color(0x1EFFFFFF),
                  size: 12,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? AppColors.orange
                : (const Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class _StreakEntryTile extends StatelessWidget {
  final StreakEntry entry;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _StreakEntryTile({
    required this.entry,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0x1EFFFFFF),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: entry.completed
                        ? AppColors.orange
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: entry.completed
                          ? AppColors.orange
                          : const Color(0x1EFFFFFF),
                      width: 2,
                    ),
                  ),
                  child: entry.completed
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: entry.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    if (entry.note != null)
                      Text(
                        entry.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    Text(
                      DateFormat(
                        'd MMMM yyyy, HH:mm',
                        'tr_TR',
                      ).format(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
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
