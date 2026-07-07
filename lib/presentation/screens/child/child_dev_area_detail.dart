import 'package:flutter/material.dart';
import '../../widgets/external_link.dart';
import '../../../services/ai/ai_content_service.dart';
import 'child_development_screen.dart' show ChildProfile;
import 'child_dev_content.dart';
import 'child_dev_store.dart';
import 'child_dev_plan_setup.dart';
import 'dev_sources.dart';

/// Bir gelişim alanının (Dil/Motor/…) konuya özel detay ekranı.
/// Her alan kendi açıklaması, beklentileri, etkinlikleri, ipuçları ve
/// kaynak linkleriyle gelir — alanlar arası içerik tekrarı yoktur.
class AreaDetailScreen extends StatelessWidget {
  final ChildProfile child;
  final String areaKey;
  const AreaDetailScreen({super.key, required this.child, required this.areaKey});

  @override
  Widget build(BuildContext context) {
    final area = areaByKey(areaKey);
    final content = areaContentFor(areaKey);
    final expectations = areaExpectations(areaKey, child.devGroup);
    final score = DevStore.areaScore(child.id, areaKey, child.devGroup);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: area.label,
              subtitle: '${child.name} · ${area.label} gelişimi',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _hero(area, content, score),
                  const SizedBox(height: 12),
                  const DevDisclaimerBanner(),
                  const SizedBox(height: 18),
                  if (expectations.isNotEmpty) ...[
                    _sectionTitle('Bu Yaşta Ne Beklenir?', Icons.flag_outlined,
                        area.gradient.first),
                    const SizedBox(height: 8),
                    _bullets(expectations, area.gradient.first,
                        icon: Icons.check_circle_outline),
                    const SizedBox(height: 18),
                  ],
                  _sectionTitle('Etkinlik Önerileri', Icons.extension,
                      area.gradient.first),
                  const SizedBox(height: 8),
                  _numbered(content.activities, area.gradient.first),
                  const SizedBox(height: 18),
                  _sectionTitle('AI Haftalık Öneriler', Icons.auto_awesome,
                      area.gradient.first),
                  const SizedBox(height: 8),
                  _AiWeeklyIdeas(
                    areaKey: areaKey,
                    areaLabel: area.label,
                    devGroup: child.devGroup,
                    color: area.gradient.first,
                    fallback: content.activities,
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('İpuçları', Icons.lightbulb_outline,
                      area.gradient.first),
                  const SizedBox(height: 8),
                  _bullets(content.tips, area.gradient.first,
                      icon: Icons.tips_and_updates_outlined),
                  const SizedBox(height: 18),
                  _sectionTitle('Resmi Kaynaklar', Icons.verified_outlined,
                      area.gradient.first),
                  const SizedBox(height: 8),
                  ...sourcesForArea(areaKey)
                      .map((s) => DevSourceTile(source: s)),
                  const SizedBox(height: 18),
                  _sectionTitle('Aktivite İlhamı', Icons.link,
                      area.gradient.first),
                  const SizedBox(height: 8),
                  ...content.links
                      .map((l) => _linkTile(context, l, area.gradient.first)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => WeeklyPlanSetupScreen(child: child)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: area.gradient.first,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text('${area.label} için AI planı',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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

  Widget _hero(DevArea area, AreaContent content, int score) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [area.gradient.first.withAlpha(60), const Color(0xFF13131A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: area.gradient.first.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: area.gradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: area.gradient.first.withAlpha(110),
                        blurRadius: 12),
                  ],
                ),
                child: Icon(area.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${area.label} Gelişimi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    Text('Gelişim skoru: %$score',
                        style: TextStyle(
                            color: area.gradient.first,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(content.description,
              style: const TextStyle(
                  color: Color(0xFFD1D5DB), fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData ic, Color c) {
    return Row(
      children: [
        Icon(ic, color: c, size: 20),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _bullets(List<String> items, Color c, {required IconData icon}) {
    return Column(
      children: items
          .map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 17, color: c),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s,
                          style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 13.5,
                              height: 1.4)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _numbered(List<String> items, Color c) {
    return Column(
      children: List.generate(items.length, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(items[i],
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB), fontSize: 13.5, height: 1.4)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _linkTile(BuildContext context, (String, String) link, Color c) {
    return GestureDetector(
      onTap: () => openExternalLink(context, link.$2),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.open_in_new, size: 18, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(link.$1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

/// Bu alan + yaş grubuna özel, haftalık AI (internet) etkinlik önerileri.
class _AiWeeklyIdeas extends StatelessWidget {
  final String areaKey;
  final String areaLabel;
  final String devGroup;
  final Color color;
  final List<String> fallback;
  const _AiWeeklyIdeas({
    required this.areaKey,
    required this.areaLabel,
    required this.devGroup,
    required this.color,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AiContentService.weeklyList(
        topic: 'dev_${areaKey}_$devGroup',
        prompt:
            '$devGroup yaş grubundaki bir çocuk için "$areaLabel" gelişim '
            'alanına yönelik, bu haftaya özel, evde uygulanabilir 5 etkinlik '
            'önerisi üret. Malzemeler basit ve güvenli olsun. Sadece JSON '
            'döndür: {"items":[{"idea":"..."}]}. Her öneri tek cümle, Türkçe.',
        listKey: 'items',
        fallback: fallback.map((a) => {'idea': a}).toList(),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
              const SizedBox(width: 10),
              const Text('AI öneriler hazırlanıyor…',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          );
        }
        final ideas = (snap.data ?? const [])
            .map((e) => e['idea']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        final list = ideas.isEmpty ? fallback : ideas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final idea in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 15, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(idea,
                          style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13.5,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
