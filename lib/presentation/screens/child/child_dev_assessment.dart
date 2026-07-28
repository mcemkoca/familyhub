import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'child_development_screen.dart' show ChildProfile;
import 'child_dev_content.dart';
import 'child_dev_store.dart';
import 'dev_sources.dart';

/// Ekran 3 — Yaşa Dayalı Beceri Değerlendirme.
class SkillAssessmentScreen extends StatefulWidget {
  final ChildProfile child;
  const SkillAssessmentScreen({super.key, required this.child});

  @override
  State<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends State<SkillAssessmentScreen> {
  late Map<String, String> _answers;
  late List<(String, String)> _items;

  static const _options = [
    ('yapiyor', 'Yapıyor', Icons.check_circle, Color(0xFF22C55E)),
    ('bazen', 'Bazen', Icons.circle_outlined, Color(0xFFF59E0B)),
    ('henuz', 'Henüz değil', Icons.cancel, Color(0xFFEF4444)),
    ('emin', 'Emin değilim', Icons.help_outline, Color(0xFF3B82F6)),
  ];

  String get _group => widget.child.devGroup;

  @override
  void initState() {
    super.initState();
    _items = assessmentFor(_group);
    _answers = DevStore.assessment(widget.child.id);
  }

  int get _answered =>
      List.generate(_items.length, (i) => '$_group|$i')
          .where(_answers.containsKey)
          .length;

  Future<void> _set(int index, String state) async {
    setState(() => _answers['$_group|$index'] = state);
    await DevStore.setAssessment(widget.child.id, '$_group|$index', state);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _items.isEmpty ? 0.0 : _answered / _items.length;
    final ageYears = (widget.child.ageMonths ~/ 12).clamp(0, 12);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: AppLocalizations.of(context).cdaTitle,
              subtitle: '$ageYears Yaş Gelişim Kontrolü',
              trailing: Text('$_answered/${_items.length}',
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
            // İlerleme çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1A1A24),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(AppLocalizations.of(context).cdaProgress((progress * 100).round()),
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const DevDisclaimerBanner(),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DevSourcesScreen()),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 15, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 5),
                        Text(AppLocalizations.of(context).cdaViewSources,
                            style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_items.length, (i) => _skillCard(i)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillCard(int i) {
    final item = _items[i];
    final area = areaByKey(item.$1);
    final selected = _answers['$_group|$i'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: area.gradient.first.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: area.gradient.first,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.$2,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _options.map((o) {
              final sel = selected == o.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _set(i, o.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? o.$4.withAlpha(30) : const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? o.$4 : const Color(0x14FFFFFF),
                        width: sel ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(o.$3, color: o.$4, size: 20),
                        const SizedBox(height: 6),
                        Text(o.$2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: o.$4,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
