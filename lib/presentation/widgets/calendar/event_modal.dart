import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../../services/notification_service.dart';
import '../../providers/app_providers.dart';

class EventModal extends ConsumerStatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;
  final Function(CalendarEvent) onSave;
  final Function(String)? onDelete;
  final VoidCallback onClose;

  const EventModal({
    super.key,
    this.event,
    this.initialDate,
    required this.onSave,
    this.onDelete,
    required this.onClose,
  });

  @override
  ConsumerState<EventModal> createState() => _EventModalState();
}

class _EventModalState extends ConsumerState<EventModal> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descCtrl;

  late DateTime _start;
  late DateTime _end;
  late EventCategory _category;
  late bool _isAllDay;
  late List<String> _attendees;
  late List<int> _reminders;
  late String? _recurrence;

  final _categories = [
    EventCategory.appointment,
    EventCategory.birthday,
    EventCategory.school,
    EventCategory.activity,
    EventCategory.work,
    EventCategory.family,
    EventCategory.travel,
    EventCategory.other,
  ];

  final _reminderOptions = [5, 15, 30, 60, 1440, 10080];
  final _recurrenceOptions = [
    null,
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _start = e?.start ?? widget.initialDate ?? DateTime.now();
    _end = e?.end ?? _start.add(const Duration(hours: 1));
    _category = e?.category ?? EventCategory.family;
    _isAllDay = e?.isAllDay ?? false;
    _attendees = List<String>.from(e?.attendees ?? []);
    _reminders = List<int>.from(e?.reminders ?? [15]);
    _recurrence = e?.recurrenceRule;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: const Color(0xFF6366F1)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _start.hour,
          _start.minute,
        );
        if (_start.isAfter(_end)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _end.hour,
          _end.minute,
        );
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: const Color(0xFF6366F1)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        if (_start.isAfter(_end)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = DateTime(
          _end.year,
          _end.month,
          _end.day,
          picked.hour,
          picked.minute,
        );
      }
    });
  }

  void _handleSave() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).evTitleRequired)));
      return;
    }
    HapticFeedback.mediumImpact();
    final event = CalendarEvent(
      id: widget.event?.id ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      start: _start,
      end: _end,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      attendees: _attendees,
      category: _category,
      color: _categoryColor(_category),
      isAllDay: _isAllDay,
      reminders: _reminders,
      recurrenceRule: _recurrence,
    );
    widget.onSave(event);

    // Schedule notifications for reminders
    for (final minutes in _reminders) {
      final reminderTime = _start.subtract(Duration(minutes: minutes));
      if (reminderTime.isAfter(DateTime.now())) {
        NotificationService.scheduleNotification(
          id: event.id.hashCode + minutes,
          title: '⏰ ${event.title}',
          body: '${_formatReminderLabel(minutes)} sonra başlıyor',
          scheduledDate: reminderTime,
        );
      }
    }

    widget.onClose();
  }

  void _handleDelete() {
    if (widget.event?.id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).evDeleteEvent),
        content: const Text(
          'Bu etkinlik kalıcı olarak silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(widget.event!.id);
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).budDelete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final isEditing = widget.event != null;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withAlpha(40),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF13131A),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1EFFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          isEditing ? 'Etkinliği Düzenle' : 'Yeni Etkinlik',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        const Spacer(),
                        if (isEditing)
                          IconButton(
                            onPressed: _handleDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          _sectionLabel('Başlık'),
                          TextField(
                            controller: _titleCtrl,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5E7EB),
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).evTitleHint,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Category
                          _sectionLabel('Kategori'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final isSelected = _category == cat;
                              final color = _categoryColor(cat);
                              return ChoiceChip(
                                label: Text(_categoryLabel(cat)),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _category = cat),
                                selectedColor: color.withAlpha(
                                  40,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF0A0A0F)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? color : const Color(0xFF6B7280),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? color.withAlpha(80)
                                        : Colors.transparent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Date & Time
                          _sectionLabel('Tarih ve Saat'),
                          const SizedBox(height: 8),
                          _DateTimeRow(
                            label: AppLocalizations.of(context).medStart,
                            date: _start,
                            onDateTap: () => _pickDate(true),
                            onTimeTap: () => _pickTime(true),
                            isAllDay: _isAllDay,
                          ),
                          const SizedBox(height: 8),
                          _DateTimeRow(
                            label: AppLocalizations.of(context).evEnd,
                            date: _end,
                            onDateTap: () => _pickDate(false),
                            onTimeTap: () => _pickTime(false),
                            isAllDay: _isAllDay,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Tüm Gün',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isAllDay,
                                onChanged: (v) => setState(() => _isAllDay = v),
                                activeTrackColor: const Color(0xFF6366F1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Location
                          _sectionLabel('Konum'),
                          TextField(
                            controller: _locationCtrl,
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).evLocationHint,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                              ),
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0A0A0F)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Description
                          _sectionLabel('Açıklama'),
                          TextField(
                            controller: _descCtrl,
                            maxLines: 3,
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).evDescHint,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0A0A0F)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Attendees
                          _sectionLabel('Katılımcılar'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: members.map((m) {
                              final isSelected = _attendees.contains(m.id);
                              return FilterChip(
                                label: Text(m.name),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _attendees.remove(m.id);
                                    } else {
                                      _attendees.add(m.id);
                                    }
                                  });
                                },
                                selectedColor: m.color.withAlpha(
                                  40,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF0A0A0F)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? m.color
                                      : (const Color(0xFF6B7280)),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? m.color.withAlpha(80)
                                        : Colors.transparent,
                                  ),
                                ),
                                showCheckmark: false,
                                avatar: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: m.color,
                                      )
                                    : null,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Reminders
                          _sectionLabel('Hatırlatmalar'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _reminderOptions.map((min) {
                              final isSelected = _reminders.contains(min);
                              return ChoiceChip(
                                label: Text(_formatReminderLabel(min)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _reminders.remove(min);
                                    } else {
                                      _reminders.add(min);
                                      _reminders.sort();
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFF6366F1).withAlpha(
                                  40,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF0A0A0F)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF6B7280),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF6366F1).withAlpha(80)
                                        : Colors.transparent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Recurrence
                          _sectionLabel('Tekrar'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recurrenceOptions.map((rec) {
                              final isSelected = _recurrence == rec;
                              return ChoiceChip(
                                label: Text(_recurrenceLabel(rec)),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _recurrence = rec),
                                selectedColor: const Color(0xFF6366F1).withAlpha(
                                  40,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF0A0A0F)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF6B7280),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF6366F1).withAlpha(80)
                                        : Colors.transparent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isEditing ? 'Güncelle' : 'Oluştur',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Cancel
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: widget.onClose,
                              child: const Text(
                                'İptal',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Color _categoryColor(EventCategory cat) {
    return switch (cat) {
      EventCategory.appointment => AppColors.error,
      EventCategory.birthday => const Color(0xFFEC4899),
      EventCategory.school => const Color(0xFFF59E0B),
      EventCategory.activity => const Color(0xFF10B981),
      EventCategory.work => const Color(0xFF6366F1),
      EventCategory.family => const Color(0xFF8B5CF6),
      EventCategory.travel => AppColors.cyan,
      EventCategory.other => const Color(0xFF6B7280),
    };
  }

  String _categoryLabel(EventCategory cat) {
    return switch (cat) {
      EventCategory.appointment => 'Randevu',
      EventCategory.birthday => 'Doğum Günü',
      EventCategory.school => 'Okul',
      EventCategory.activity => 'Aktivite',
      EventCategory.work => 'İş',
      EventCategory.family => 'Aile',
      EventCategory.travel => 'Seyahat',
      EventCategory.other => 'Diğer',
    };
  }

  String _formatReminderLabel(int minutes) {
    if (minutes < 60) return '$minutes dk';
    if (minutes < 1440) return '${minutes ~/ 60} sa';
    if (minutes < 10080) return '${minutes ~/ 1440} gün';
    return '${minutes ~/ 10080} hafta';
  }

  String _recurrenceLabel(String? rec) {
    return switch (rec) {
      null => 'Bir Kez',
      'daily' => 'Her Gün',
      'weekly' => 'Her Hafta',
      'biweekly' => '2 Haftada',
      'monthly' => 'Her Ay',
      'yearly' => 'Her Yıl',
      _ => 'Bir Kez',
    };
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final bool isAllDay;

  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.onDateTap,
    required this.onTimeTap,
    required this.isAllDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A0F)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('d MMM yyyy', 'tr_TR').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isAllDay) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onTimeTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A0F)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
