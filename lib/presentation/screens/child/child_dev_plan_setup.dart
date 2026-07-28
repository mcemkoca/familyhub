import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../services/hive_service.dart';
import '../../../services/ai/pedagogy_engine.dart';
import 'child_development_screen.dart' show ChildProfile;
import 'child_dev_content.dart';

/// Ekran 4 — Haftalık Gelişim Planı Kurulumu.
class WeeklyPlanSetupScreen extends StatefulWidget {
  final ChildProfile child;
  const WeeklyPlanSetupScreen({super.key, required this.child});

  @override
  State<WeeklyPlanSetupScreen> createState() => _WeeklyPlanSetupScreenState();
}

class _WeeklyPlanSetupScreenState extends State<WeeklyPlanSetupScreen> {
  final Set<String> _focus = {'dil'};
  int _minutes = 10;
  String _difficulty = 'easy';
  String _planType = 'oyun';
  bool _loading = false;

  static const _focusOptions = [
    ('dil', 'Dil', Icons.chat_bubble_rounded, Color(0xFF22C55E)),
    ('motor', 'İnce Motor', Icons.back_hand_rounded, Color(0xFFF59E0B)),
    ('sosyal', 'Sosyal', Icons.groups_rounded, Color(0xFF14B8A6)),
    ('ozbakim', 'Öz Bakım', Icons.favorite_rounded, Color(0xFFEF4444)),
    ('bilissel', 'Bilişsel', Icons.psychology_rounded, Color(0xFF8B5CF6)),
    ('duyusal', 'Duyusal', Icons.visibility_rounded, Color(0xFF3B82F6)),
  ];

  static const _difficulties = [
    ('easy', 'Kolay'),
    ('medium', 'Orta'),
    ('mixed', 'Karışık'),
  ];

  static const _planTypes = [
    ('oyun', 'Oyun odaklı', Icons.sports_esports_rounded, Color(0xFF8B5CF6)),
    ('okul', 'Okul öncesi', Icons.school_rounded, Color(0xFF06B6D4)),
    ('ev', 'Ev rutini', Icons.home_rounded, Color(0xFFEC4899)),
  ];

  String get _lang {
    final l = HiveService.getSetting('language') ?? 'Türkçe';
    switch (l) {
      case 'English':
        return 'en';
      case 'Français':
        return 'fr';
      case 'Nederlands':
        return 'nl';
      default:
        return 'tr';
    }
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    final focusLabel = _focus
        .map((k) => _focusOptions.firstWhere((o) => o.$1 == k).$2)
        .join(', ');
    final planTypeLabel =
        _planTypes.firstWhere((p) => p.$1 == _planType).$2;
    final plan = await PedagogyEngine.generateWeeklyPlan(
      childName: widget.child.name,
      age: (widget.child.ageMonths ~/ 12).clamp(1, 12),
      language: _lang,
      focus: focusLabel.isEmpty ? 'genel gelişim' : focusLabel,
      minutesPerDay: _minutes,
      difficulty: _difficulty,
      specialNotes: 'Plan türü: $planTypeLabel',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    // Gemini başarısız olsa bile yerel içerikten plan üret — asla boş kalmasın.
    final finalPlan = (plan != null && (plan['days'] as List?)?.isNotEmpty == true)
        ? plan
        : _localFallbackPlan(focusLabel);
    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).cpsOfflinePlan)),
      );
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PlanResultSheet(plan: finalPlan, childName: widget.child.name),
    );
  }

  // Odak alanlarının etkinliklerinden 7 günlük yerel plan üretir (fallback).
  Map<String, dynamic> _localFallbackPlan(String focusLabel) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final focusKeys = _focus.toList();
    final dayList = <Map<String, dynamic>>[];
    for (var i = 0; i < 7; i++) {
      final areaKey = focusKeys[i % focusKeys.length];
      final content = areaContentFor(areaKey);
      final acts = content.activities;
      final act = acts[i % acts.length];
      final label =
          _focusOptions.firstWhere((o) => o.$1 == areaKey, orElse: () => _focusOptions.first).$2;
      dayList.add({
        'day': days[i],
        'lesson': {'title': '$label çalışması', 'description': act},
        'daily_task': {'title': act, 'description': ''},
      });
    }
    return {
      'week_theme': focusLabel.isEmpty
          ? 'Bu Haftanın Gelişim Planı'
          : '$focusLabel Odaklı Hafta',
      'weekly_goal':
          'Her gün $_minutes dakika, oyunlaştırılmış etkinliklerle seçili '
              'alanları destekleyin.',
      'days': dayList,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: AppLocalizations.of(context).cpsTitle,
              subtitle: AppLocalizations.of(context).cpsSubtitle(widget.child.name),
              trailing: const Icon(Icons.calendar_month, color: Colors.white),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _section('Odak Alanları', Icons.track_changes, _focusWrap()),
                  const SizedBox(height: 14),
                  _section('Günlük Süre', Icons.schedule, _durationRow()),
                  const SizedBox(height: 14),
                  _section('Zorluk Seviyesi', Icons.bar_chart, _difficultyRow()),
                  const SizedBox(height: 14),
                  _section('Plan Türü', Icons.extension, _planTypeRow()),
                  const SizedBox(height: 14),
                  _section('Plan Önizleme', Icons.visibility, _preview()),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _create,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(_loading ? AppLocalizations.of(context).cpsCreating : AppLocalizations.of(context).cpsCreate,
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

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _focusWrap() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _focusOptions.map((o) {
        final sel = _focus.contains(o.$1);
        return GestureDetector(
          onTap: () => setState(() {
            if (sel) {
              if (_focus.length > 1) _focus.remove(o.$1);
            } else {
              _focus.add(o.$1);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? o.$4.withAlpha(28) : const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? o.$4 : const Color(0x14FFFFFF),
                width: sel ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(o.$3, color: o.$4, size: 18),
                const SizedBox(width: 8),
                Text(o.$2,
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFFD1D5DB),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _durationRow() {
    const opts = [5, 10, 15, 20];
    return Row(
      children: opts.map((m) {
        final sel = _minutes == m;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _minutes = m),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF6366F1) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF6366F1)
                        : const Color(0x14FFFFFF)),
              ),
              child: Center(
                child: Text('$m dk',
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFFD1D5DB),
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _difficultyRow() {
    return Row(
      children: _difficulties.map((d) {
        final sel = _difficulty == d.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = d.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF8B5CF6) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF8B5CF6)
                        : const Color(0x14FFFFFF)),
              ),
              child: Center(
                child: Text(d.$2,
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFFD1D5DB),
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _planTypeRow() {
    return Row(
      children: _planTypes.map((p) {
        final sel = _planType == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _planType = p.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: sel ? p.$4.withAlpha(30) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: sel ? p.$4 : const Color(0x14FFFFFF),
                    width: sel ? 1.6 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(p.$3, color: p.$4, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(p.$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:
                                sel ? Colors.white : const Color(0xFFD1D5DB),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _preview() {
    // Odağa göre örnek 3 aktivite önizlemesi.
    final acts = <(String, IconData, Color)>[
      ('Hikaye ve Kelime Oyunu', Icons.menu_book, const Color(0xFF22C55E)),
      ('Renkleri Eşleştirme', Icons.palette, const Color(0xFFF59E0B)),
      ('Paylaşma Zamanı', Icons.groups, const Color(0xFF3B82F6)),
    ];
    return Column(
      children: acts.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: a.$3.withAlpha(40),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(a.$2, color: a.$3, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(a.$1,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.schedule, size: 14, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 4),
              Text('$_minutes dk',
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Üretilen planın sonuç görünümü.
class _PlanResultSheet extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String childName;
  const _PlanResultSheet({required this.plan, required this.childName});

  static const _dayTr = {
    'Monday': 'Pazartesi', 'Tuesday': 'Salı', 'Wednesday': 'Çarşamba',
    'Thursday': 'Perşembe', 'Friday': 'Cuma', 'Saturday': 'Cumartesi',
    'Sunday': 'Pazar',
  };

  @override
  Widget build(BuildContext context) {
    final days = (plan['days'] as List?) ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((plan['week_theme'] ?? 'Haftalık Plan').toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text((plan['weekly_goal'] ?? '').toString(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...days.map((d) => _dayCard(d as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(Map<String, dynamic> d) {
    final day = (d['day'] ?? '').toString();
    final lesson = d['lesson'] as Map<String, dynamic>?;
    final task = d['daily_task'] as Map<String, dynamic>?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dayTr[day] ?? day,
              style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          if (lesson != null && (lesson['title'] ?? '').toString().isNotEmpty)
            _line(Icons.school, const Color(0xFF06B6D4), 'Ders',
                lesson['title'].toString()),
          if (task != null && (task['title'] ?? '').toString().isNotEmpty)
            _line(Icons.star, const Color(0xFF10B981), 'Görev',
                task['title'].toString()),
        ],
      ),
    );
  }

  Widget _line(IconData ic, Color c, String label, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ic, size: 15, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label: $title',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
