import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'health_store.dart';

/// Ekran 3 — Kadın Sağlığı (döngü + semptom takibi).
class KadinSaglikScreen extends StatefulWidget {
  const KadinSaglikScreen({super.key});

  @override
  State<KadinSaglikScreen> createState() => _KadinSaglikScreenState();
}

class _KadinSaglikScreenState extends State<KadinSaglikScreen> {
  late DateTime _month;

  static const _symptoms = [
    ('bas', 'Baş Ağrısı', Icons.psychology),
    ('halsizlik', 'Halsizlik', Icons.battery_2_bar),
    ('karin', 'Karın Ağrısı', Icons.sick),
    ('ruh', 'Ruh Hali', Icons.mood),
  ];

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  // Bir günün döngü sınıfı: period / fertile / ovulation / predicted / none
  String _dayClass(DateTime day) {
    final start = HealthStore.cycleStart();
    final diff = DateTime(day.year, day.month, day.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
    if (diff < 0) return 'none';
    final cd = (diff % HealthStore.cycleLength) + 1;
    if (cd <= HealthStore.periodLength) return 'period';
    if (cd == 14) return 'ovulation';
    if (cd >= 10 && cd <= 16) return 'fertile';
    if (cd == HealthStore.cycleLength) return 'predicted';
    return 'none';
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = HealthStore.symptomsToday();
    final day = HealthStore.cycleDay();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
              title: AppLocalizations.of(context).hwTitle,
              subtitle: AppLocalizations.of(context).hwSubtitle,
              icon: Icons.favorite_rounded,
              gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
              showBack: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _calendarCard(),
                  const SizedBox(height: 16),
                  _cycleCard(day),
                  const SizedBox(height: 16),
                  _symptomCard(symptoms),
                  const SizedBox(height: 16),
                  _tipCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarCard() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (first.weekday - 1) % 7; // Pzt=0
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      cells.add(_dayCell(date, d));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF241023), Color(0xFF161225)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33EC4899)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navBtn(Icons.chevron_left, () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1))),
              Text(DateFormat('MMMM yyyy', 'tr_TR').format(_month),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              _navBtn(Icons.chevron_right, () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legend(const Color(0xFFEC4899), 'Adet Dönemi'),
              _legend(const Color(0xFF8B5CF6), 'Doğurganlık'),
              _legend(const Color(0xFFEC4899), 'Tahmini Adet', dashed: true),
              _legend(const Color(0xFFA855F7), 'Yumurtlama', ring: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date, int d) {
    final cls = _dayClass(date);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    Color? bg;
    Border? border;
    switch (cls) {
      case 'period':
        bg = const Color(0xFFEC4899);
        break;
      case 'fertile':
        bg = const Color(0xFF8B5CF6).withAlpha(60);
        break;
      case 'ovulation':
        border = Border.all(color: const Color(0xFFA855F7), width: 2);
        break;
      case 'predicted':
        border = Border.all(
            color: const Color(0xFFEC4899), width: 1.4);
        break;
    }
    if (isToday) {
      border = Border.all(color: Colors.white, width: 2);
    }
    return Center(
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Text('$d',
            style: TextStyle(
                color: bg != null ? Colors.white : const Color(0xFFE5E7EB),
                fontSize: 14,
                fontWeight:
                    isToday ? FontWeight.w900 : FontWeight.w500)),
      ),
    );
  }

  Widget _navBtn(IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0x22FFFFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(ic, color: Colors.white, size: 20),
        ),
      );

  Widget _legend(Color c, String label,
      {bool dashed = false, bool ring = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: (dashed || ring) ? Colors.transparent : c,
            shape: BoxShape.circle,
            border: (dashed || ring) ? Border.all(color: c, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
      ],
    );
  }

  Widget _cycleCard(int day) {
    return GestureDetector(
      onTap: _pickCycleStart,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33EC4899)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).hwCycleTracking,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context).hwCycleDay(day),
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(AppLocalizations.of(context).hwTapToChangeStart,
                      style:
                          const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: CircularProgressIndicator(
                      value: day / HealthStore.cycleLength,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFF2A2A34),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFEC4899)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$day',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const Text('/28 gün',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 8)),
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

  Future<void> _pickCycleStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: HealthStore.cycleStart(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await HealthStore.setCycleStart(picked);
      if (mounted) setState(() {});
    }
  }

  Widget _symptomCard(Set<String> active) {
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
              const Icon(Icons.monitor_heart, color: Color(0xFFEC4899), size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).hwSymptomTracking,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).hMoodQuestion,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptoms.map((s) {
              final on = active.contains(s.$1);
              return GestureDetector(
                onTap: () async {
                  await HealthStore.toggleSymptom(s.$1);
                  setState(() {});
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 32 - 32 - 10) / 2,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: on
                        ? const Color(0xFFEC4899).withAlpha(30)
                        : const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: on
                            ? const Color(0xFFEC4899)
                            : const Color(0x14FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Icon(s.$3,
                          size: 18,
                          color: on
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.$2,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      Icon(on ? Icons.toggle_on : Icons.toggle_off,
                          color: on
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF6B7280),
                          size: 26),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33EC4899)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa, color: Color(0xFFEC4899), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).hTodaySuggestion,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                    'Bol su içmeyi unutma! Su, vücudunun dengesini korumasına ve şişkinliği azaltmana yardımcı olur.',
                    style: TextStyle(
                        color: Color(0xFFD1D5DB), fontSize: 13.5, height: 1.45)),
              ],
            ),
          ),
          const Text('💧', style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}
