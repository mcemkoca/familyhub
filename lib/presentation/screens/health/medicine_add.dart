import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_store.dart';
import 'family_health_screen.dart';
import '../../../services/notification_service.dart';

/// İlaç Ekle — tam ilaç ekleme formu.
class MedicineAddScreen extends ConsumerStatefulWidget {
  const MedicineAddScreen({super.key});

  @override
  ConsumerState<MedicineAddScreen> createState() => _MedicineAddScreenState();
}

class _MedicineAddScreenState extends ConsumerState<MedicineAddScreen> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();

  String _type = 'Tablet';
  String _frequency = 'Günde 1 kez';
  DateTime _start = DateTime.now();
  DateTime? _end;
  bool _reminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _memberId = 'anne';

  static const _types = [
    'Tablet',
    'Şurup',
    'Damla',
    'Kapsül',
    'İğne',
    'Krem',
    'Sprey',
  ];
  static const _frequencies = [
    'Günde 1 kez',
    'Günde 2 kez',
    'Günde 3 kez',
    'Haftada 1 kez',
    'Gerektiğinde',
  ];

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : (_end ?? _start),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF14B8A6),
            surface: Color(0xFF13131A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).medEnterName)),
      );
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch;
    final med = Medicine(
      id: id.toString(),
      name: name,
      dosage: _dosage.text.trim().isEmpty ? _type : '${_dosage.text.trim()} · $_type',
      frequency: _frequency,
      startDate: _start.toIso8601String(),
      endDate: _end?.toIso8601String(),
      notes: _notes.text.trim(),
    );
    ref.read(familyHealthProvider.notifier).addMedicine(_memberId, med);

    var scheduled = false;
    if (_reminder) {
      scheduled = await _scheduleReminder(id, name);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(scheduled
              ? '$name eklendi · hatırlatma ${_fmtTime(_reminderTime)} kuruldu'
              : '$name eklendi.')),
    );
    Navigator.pop(context);
  }

  /// İlk uygun tarihte (bugün geçtiyse yarın) günlük hatırlatma kurar.
  Future<bool> _scheduleReminder(int id, String name) async {
    final medTimeTitle = AppLocalizations.of(context).medTime;
    try {
      await NotificationService.requestPermission();
      final now = DateTime.now();
      var when = DateTime(now.year, now.month, now.day, _reminderTime.hour,
          _reminderTime.minute);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      final doseLabel = _dosage.text.trim().isEmpty ? _type : _dosage.text.trim();
      await NotificationService.scheduleNotification(
        id: id % 2147483647,
        title: medTimeTitle,
        body: '$name · $doseLabel zamanı!',
        scheduledDate: when,
        payload: 'medicine_reminder',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyHealthProvider);
    if (members.isNotEmpty && !members.any((m) => m.id == _memberId)) {
      _memberId = members.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
              title: AppLocalizations.of(context).ilacEkle,
              subtitle: AppLocalizations.of(context).medNewRecordSub,
              icon: Icons.medication_rounded,
              gradient: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
              showBack: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (members.isNotEmpty) ...[
                    _label(AppLocalizations.of(context).medWhose),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: members.map((m) {
                        final sel = m.id == _memberId;
                        return GestureDetector(
                          onTap: () => setState(() => _memberId = m.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF14B8A6)
                                  : const Color(0xFF13131A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: sel
                                      ? const Color(0xFF14B8A6)
                                      : const Color(0xFF262631)),
                            ),
                            child: Text('${m.emoji} ${m.name}',
                                style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB),
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _label(AppLocalizations.of(context).medName),
                  const SizedBox(height: 8),
                  _field(_name, 'Örn: Parol 500 mg'),
                  const SizedBox(height: 18),
                  _label(AppLocalizations.of(context).medType),
                  const SizedBox(height: 8),
                  _dropdown(_type, _types, (v) => setState(() => _type = v!)),
                  const SizedBox(height: 18),
                  _label(AppLocalizations.of(context).medDose),
                  const SizedBox(height: 8),
                  _field(_dosage, 'Örn: 1 tablet'),
                  const SizedBox(height: 18),
                  _label(AppLocalizations.of(context).medFrequency),
                  const SizedBox(height: 8),
                  _dropdown(_frequency, _frequencies,
                      (v) => setState(() => _frequency = v!)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(AppLocalizations.of(context).medStart),
                            const SizedBox(height: 8),
                            _dateBtn(_fmt(_start), () => _pickDate(true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(AppLocalizations.of(context).medEndOptional),
                            const SizedBox(height: 8),
                            _dateBtn(_end == null ? 'Seç' : _fmt(_end!),
                                () => _pickDate(false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF262631)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: Color(0xFF14B8A6), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(AppLocalizations.of(context).medReminder,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: _reminder,
                          activeThumbColor: const Color(0xFF14B8A6),
                          onChanged: (v) => setState(() => _reminder = v),
                        ),
                      ],
                    ),
                  ),
                  if (_reminder) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF14B8A6),
                                surface: Color(0xFF13131A),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF262631)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: Color(0xFF14B8A6), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(AppLocalizations.of(context).medReminderTime,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15)),
                            ),
                            Text(_fmtTime(_reminderTime),
                                style: const TextStyle(
                                    color: Color(0xFF14B8A6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _label(AppLocalizations.of(context).medNote),
                  const SizedBox(height: 8),
                  _field(_notes, 'Yemekten sonra al...', maxLines: 3),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLocalizations.of(context).save,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13.5,
          fontWeight: FontWeight.w600));

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFF13131A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF262631)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF14B8A6)),
        ),
      ),
    );
  }

  Widget _dropdown(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262631)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF13131A),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF9CA3AF)),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF262631)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF14B8A6), size: 18),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
