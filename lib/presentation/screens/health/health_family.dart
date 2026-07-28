import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import 'health_store.dart';
import 'family_health_screen.dart' show familyHealthProvider;

/// Ekran 2 — Aile Sağlığı (ebeveynler).
class FamilySaglikScreen extends ConsumerStatefulWidget {
  const FamilySaglikScreen({super.key});

  @override
  ConsumerState<FamilySaglikScreen> createState() => _FamilySaglikScreenState();
}

class _FamilySaglikScreenState extends ConsumerState<FamilySaglikScreen> {
  @override
  Widget build(BuildContext context) {
    final steps = HealthStore.metric('steps', 0);
    final water = HealthStore.metric('water', 0);
    final sleep = HealthStore.metric('sleep', 0);
    final stress = HealthStore.metric('stress', 0); // 0-3

    // Gerçek ebeveynler (yoksa boş görünür ama ekran çalışır).
    final members = ref.watch(familyMembersProvider);
    final parents = members
        .where((m) =>
            m.role == MemberRole.parent ||
            m.role == MemberRole.admin ||
            m.role == MemberRole.elder)
        .toList();

    // Gerçek yaklaşan randevular (familyHealthProvider'dan).
    final appointments = _upcomingAppointments(ref);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
              title: AppLocalizations.of(context).hfTitle,
              subtitle: AppLocalizations.of(context).hfSubtitle,
              icon: Icons.favorite_rounded,
              gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              showBack: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (parents.isEmpty)
                    _emptyMembersCard()
                  else
                    Row(
                      children: [
                        for (var i = 0; i < parents.length && i < 2; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _memberCard(
                                parents[i].name,
                                _roleLabel(parents[i].role),
                                parents[i].color,
                                Icons.person_rounded),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    'Sağlık Özeti',
                    Icons.monitor_heart,
                    Column(
                      children: [
                        _metricRow('Adım', '${steps.round()} / 10.000',
                            steps / 10000, const Color(0xFF22C55E),
                            Icons.directions_walk, () => _editMetric('steps', steps, 500, 0, 30000)),
                        _metricRow('Su Tüketimi',
                            '${water.toStringAsFixed(1)} / 2,5 L', water / 2.5,
                            const Color(0xFF3B82F6), Icons.water_drop,
                            () => _editMetric('water', water, 0.25, 0, 5)),
                        _metricRow('Uyku',
                            '${sleep.floor()}s ${((sleep % 1) * 60).round()}d / 8s',
                            sleep / 8, const Color(0xFF8B5CF6), Icons.bedtime,
                            () => _editMetric('sleep', sleep, 0.25, 0, 12)),
                        _metricRow(
                            'Stres Seviyesi',
                            ['Düşük', 'Hafif', 'Orta', 'Yüksek'][stress.round().clamp(0, 3)],
                            (stress + 1) / 4, const Color(0xFFF59E0B),
                            Icons.sentiment_neutral,
                            () => _editMetric('stress', stress, 1, 0, 3),
                            isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    'Yaklaşan Randevular',
                    Icons.calendar_month,
                    appointments.isEmpty
                        ? _emptyRow('Yaklaşan randevu yok')
                        : Column(
                            children: [
                              for (var i = 0; i < appointments.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _apptRow(
                                    appointments[i].$1,
                                    appointments[i].$2,
                                    appointments[i].$3,
                                    appointments[i].$4),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _tipCard(
                      'Bugün 10.000 adım hedefini tamamlamana ${(10000 - steps).clamp(0, 10000).round()} adım kaldı.'),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).hfFamilyContent,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _contentChip('Beslenme', Icons.restaurant,
                          const Color(0xFF22C55E)),
                      const SizedBox(width: 10),
                      _contentChip('Egzersiz', Icons.directions_run,
                          const Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      _contentChip('Kalp Sağlığı', Icons.favorite,
                          const Color(0xFFEC4899)),
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

  String _roleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
      case MemberRole.parent:
        return 'Ebeveyn';
      case MemberRole.elder:
        return 'Büyük';
      default:
        return 'Üye';
    }
  }

  /// familyHealthProvider'daki tamamlanmamış randevuları toplar, tarihe göre
  /// sıralar ve (gün, ay, başlık, saat) tuple listesi döndürür.
  List<(String, String, String, String)> _upcomingAppointments(WidgetRef ref) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final result = <(DateTime, String, String, String, String)>[];
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    for (final m in ref.watch(familyHealthProvider)) {
      for (final a in m.appointments) {
        if (a.completed) continue;
        final parts = a.dateTime.split('.');
        if (parts.length != 3) continue;
        final d = DateTime.tryParse(
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
        if (d == null || d.isBefore(start)) continue;
        final title = a.specialty.isNotEmpty
            ? '${a.doctorName} · ${a.specialty}'
            : a.doctorName;
        result.add((d, d.day.toString(), months[d.month], title, '—'));
      }
    }
    result.sort((x, y) => x.$1.compareTo(y.$1));
    return result
        .take(4)
        .map((e) => (e.$2, e.$3, e.$4, e.$5))
        .toList();
  }

  Widget _emptyMembersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262631)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_add_rounded, color: Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppLocalizations.of(context).hfNoParent,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
    );
  }

  Future<void> _editMetric(String key, double current, double step,
      double min, double max) async {
    double v = current;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).hfSetValue,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepBtn(Icons.remove, () {
                    setSheet(() => v = (v - step).clamp(min, max));
                  }),
                  const SizedBox(width: 24),
                  Text(
                      step < 1
                          ? v.toStringAsFixed(2)
                          : v.round().toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 24),
                  _stepBtn(Icons.add, () {
                    setSheet(() => v = (v + step).clamp(min, max));
                  }),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await HealthStore.setMetric(key, v);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppLocalizations.of(context).save,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(ic, color: const Color(0xFF8B5CF6), size: 26),
        ),
      );

  Widget _memberCard(String name, String role, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withAlpha(180)]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text(role,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Widget child) {
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
              Icon(icon, color: const Color(0xFF14B8A6), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, double pct, Color color,
      IconData icon, VoidCallback onTap,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(value,
                          style: TextStyle(
                              color: color,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF2A2A34),
                      valueColor: AlwaysStoppedAnimation(color),
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

  Widget _apptRow(String day, String month, String title, String time) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withAlpha(30),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(day,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Text(month,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 13, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
      ],
    );
  }

  Widget _tipCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2214B8A6)),
      ),
      child: Row(
        children: [
          const Text('👟', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).hfDailySuggestion,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        color: Color(0xFFD1D5DB), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentChip(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
