import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/hive_service.dart';
import 'child_development_screen.dart' show ChildProfile, childDevProvider;
import 'child_dev_content.dart';
import 'child_dev_store.dart';
import 'child_dev_observation.dart';
import 'child_dev_assessment.dart';
import 'child_dev_plan_setup.dart';
import 'child_dev_area_detail.dart';
import 'dev_sources.dart';
import 'child_dev_story_time.dart';
import 'child_dev_color_game.dart';
import 'child_dev_sensory_game.dart';

/// Ekran 1 — Çocuk Gelişim Dashboard.
class ChildDevelopmentHome extends ConsumerStatefulWidget {
  const ChildDevelopmentHome({super.key});

  @override
  ConsumerState<ChildDevelopmentHome> createState() =>
      _ChildDevelopmentHomeState();
}

class _ChildDevelopmentHomeState extends ConsumerState<ChildDevelopmentHome> {
  int _childIndex = 0;

  static const _weekActs = [
    ('Hikaye Zamanı', Icons.menu_book, Color(0xFF06B6D4)),
    ('Renkleri Eşleştirme', Icons.extension, Color(0xFF8B5CF6)),
    ('Duyusal Keşif', Icons.back_hand, Color(0xFF6366F1)),
  ];
  static const _states = ['bekliyor', 'devam', 'tamamlandi'];

  List<String> _weekStates(String childId) {
    final raw = HiveService.getSetting('dev_week_$childId');
    if (raw == null || raw.isEmpty) return ['tamamlandi', 'devam', 'bekliyor'];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return ['tamamlandi', 'devam', 'bekliyor'];
    }
  }

  // Plan öğesine göre ilgili içerik ekranını açar ve durumu "devam" yapar.
  Future<void> _openActivity(ChildProfile child, int i) async {
    final states = _weekStates(child.id);
    if (i < states.length && states[i] == 'bekliyor') {
      states[i] = 'devam';
      await HiveService.setSetting('dev_week_${child.id}', jsonEncode(states));
      if (mounted) setState(() {});
    }
    if (!mounted) return;
    Widget target;
    switch (i) {
      case 0:
        target = const StoryTimeScreen();
        break;
      case 1:
        target = const ColorGameScreen();
        break;
      default:
        target = const SensoryGameScreen();
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    if (mounted) setState(() {});
  }

  Future<void> _cycleWeek(String childId, int i) async {
    final states = _weekStates(childId);
    final cur = _states.indexOf(states[i]);
    states[i] = _states[(cur + 1) % _states.length];
    await HiveService.setSetting('dev_week_$childId', jsonEncode(states));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childDevProvider);
    if (children.isEmpty) return _emptyState();
    final child = children[_childIndex.clamp(0, children.length - 1)];
    final group = child.devGroup;
    final overall = DevStore.overallScore(child.id, group);
    final obs = DevStore.observations(child.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dev_obs',
        onPressed: () => _openObservation(child),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Gözlem',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: 'Gelişim',
              subtitle: '${child.name}\'in gelişim merkezi',
              trailing: const Icon(Icons.info_outline, color: Color(0xFF9CA3AF)),
              onTrailing: () => _openAssessment(child),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  _profileCard(child, overall, children),
                  const SizedBox(height: 14),
                  _areaGrid(child, group),
                  const SizedBox(height: 16),
                  _dailySummary(child),
                  const SizedBox(height: 20),
                  _weeklyPlan(child),
                  const SizedBox(height: 20),
                  _aiInsight(child, group),
                  const SizedBox(height: 20),
                  _observations(child, obs),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DevSourcesScreen()),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 6),
                        Text('İçeriklerimizin kaynakları',
                            style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DevDisclaimerBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profil kartı + dairesel skor ─────────────────────────────────────────
  Widget _profileCard(
      ChildProfile child, int overall, List<ChildProfile> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1330), Color(0xFF130E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1F8B5CF6)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: children.length > 1
                ? () => setState(() =>
                    _childIndex = (_childIndex + 1) % children.length)
                : null,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(child.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                Text(child.ageLabel,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 14)),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: overall / 100,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFF2A2440),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                  ),
                ),
                Text('%$overall',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 54,
            child: Text('Genel Gelişim Skoru',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── 6 gelişim alanı ──────────────────────────────────────────────────────
  Widget _areaGrid(ChildProfile child, String group) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: devAreas.map((a) {
        final score = DevStore.areaScore(child.id, a.key, group);
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AreaDetailScreen(child: child, areaKey: a.key)),
          ).then((_) {
            if (mounted) setState(() {});
          }),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: a.gradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: a.gradient.first.withAlpha(90),
                              blurRadius: 8),
                        ],
                      ),
                      child: Icon(a.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          Text('%$score',
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2A2A34),
                    valueColor: AlwaysStoppedAnimation(a.gradient.first),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Bugünün görevleri özeti (alan kartlarının altında) ───────────────────
  Widget _dailySummary(ChildProfile child) {
    final states = _weekStates(child.id);
    final total = _weekActs.length;
    final done = states.where((s) => s == 'tamamlandi').length;
    final ongoing = states.where((s) => s == 'devam').length;
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16122B), Color(0xFF13131A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F6366F1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(35),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.today, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bugünün Görevleri',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$total görev · $done tamamlandı · $ongoing devam ediyor',
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 12.5)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2A2A34),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${(pct * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ── Bu haftanın planı ────────────────────────────────────────────────────
  Widget _weeklyPlan(ChildProfile child) {
    final states = _weekStates(child.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowTitle('Bu Haftanın Planı',
            onSeeAll: () => _openPlanSetup(child)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            children: List.generate(_weekActs.length, (i) {
              final a = _weekActs[i];
              final st = states.length > i ? states[i] : 'bekliyor';
              return InkWell(
                onTap: () => _openActivity(child, i),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: a.$3.withAlpha(40),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(a.$2, color: a.$3, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.$1,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const Text('Başlamak için dokun',
                                style: TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 11.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _cycleWeek(child.id, i),
                        child: _statusChip(st),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String st) {
    late Color c;
    late String label;
    late IconData ic;
    switch (st) {
      case 'tamamlandi':
        c = const Color(0xFF22C55E);
        label = 'Tamamlandı';
        ic = Icons.check_circle;
        break;
      case 'devam':
        c = const Color(0xFFF59E0B);
        label = 'Devam Ediyor';
        ic = Icons.circle_outlined;
        break;
      default:
        c = const Color(0xFF6B7280);
        label = 'Bekliyor';
        ic = Icons.circle_outlined;
    }
    return Row(
      children: [
        Icon(ic, color: c, size: 16),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── AI Yorumu ────────────────────────────────────────────────────────────
  Widget _aiInsight(ChildProfile child, String group) {
    final scores = {
      for (final a in devAreas) a.label: DevStore.areaScore(child.id, a.key, group)
    };
    final top = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final low = scores.entries.reduce((a, b) => a.value <= b.value ? a : b);
    final text =
        '${child.name}\'in ${top.key.toLowerCase()} gelişimi harika gidiyor! '
        '${low.key} alanını destekleyici etkinliklere devam edin. '
        'Sosyal etkileşimlerde belleği güçleniyor.';
    return GestureDetector(
      onTap: () => _openPlanSetup(child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1330), Color(0xFF16122B)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1F8B5CF6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Yorumu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(text,
                      style: const TextStyle(
                          color: Color(0xFFB4B4C4),
                          fontSize: 13.5,
                          height: 1.45)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  // ── Son gözlemler ────────────────────────────────────────────────────────
  Widget _observations(ChildProfile child, List<Observation> obs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowTitle('Son Gözlemler',
            onSeeAll: obs.isEmpty ? null : () {}),
        const SizedBox(height: 10),
        if (obs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: const Center(
              child: Text('Henüz gözlem yok — "Gözlem" ile ilk kaydı ekleyin.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ),
          )
        else
          ...obs.take(4).map((o) => _obsCard(o)),
      ],
    );
  }

  Widget _obsCard(Observation o) {
    final area = areaByKey(o.area);
    final t = o.date;
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    final label = isToday
        ? 'Bugün ${DateFormat('HH:mm').format(t)}'
        : DateFormat('d MMM HH:mm', 'tr_TR').format(t);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, size: 16, color: area.gradient.first),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: area.gradient.first,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(o.note.isEmpty ? '(not yok)' : o.note,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.35)),
              ],
            ),
          ),
          if (o.media.isNotEmpty) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(o.media.first),
                  width: 54, height: 54, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFF1A1A24),
                      child: const Icon(Icons.image,
                          color: Color(0xFF6B7280), size: 20))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('Tümünü Gör',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(title: 'Gelişim', subtitle: 'Çocuk gelişim merkezi'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.child_care,
                          size: 64, color: Color(0xFF6B7280)),
                      SizedBox(height: 16),
                      Text('Henüz çocuk profili yok',
                          style: TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text(
                          'Gelişim takibi için Çocuk bölümünden bir profil ekleyin.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigasyon ───────────────────────────────────────────────────────────
  Future<void> _openObservation(ChildProfile child) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ObservationInputScreen(child: child)));
    if (mounted) setState(() {});
  }

  Future<void> _openAssessment(ChildProfile child) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => SkillAssessmentScreen(child: child)));
    if (mounted) setState(() {});
  }

  Future<void> _openPlanSetup(ChildProfile child) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => WeeklyPlanSetupScreen(child: child)));
    if (mounted) setState(() {});
  }
}
