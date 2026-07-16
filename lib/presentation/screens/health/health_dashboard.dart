import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import 'health_store.dart';
import 'health_family.dart';
import 'health_women.dart';
import 'health_child.dart';
import 'health_articles.dart';
import 'family_health_screen.dart' show FamilyHealthScreen;
import 'medicine_add.dart';
import 'medicine_reminder.dart';
import '../../../features/vaccinations/presentation/vaccination_screen.dart';

/// Ekran 1 — Sağlık Ana Dashboard.
class HealthDashboard extends ConsumerStatefulWidget {
  const HealthDashboard({super.key});

  @override
  ConsumerState<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends ConsumerState<HealthDashboard> {
  static const _moods = [
    ('😣', 'Çok kötü', Color(0xFFEF4444)),
    ('🙁', 'Kötü', Color(0xFFF97316)),
    ('😐', 'Orta', Color(0xFFEAB308)),
    ('🙂', 'İyi', Color(0xFF22C55E)),
    ('😄', 'Çok iyi', Color(0xFF14B8A6)),
  ];

  @override
  Widget build(BuildContext context) {
    // Hesap sahibinin (giriş yapan kullanıcı) kendi adı — çocuğun adı DEĞİL.
    final meta = AuthService.currentUser?.userMetadata;
    final rawName = (meta?['display_name'] ?? meta?['full_name'] ?? '')
        .toString()
        .trim();
    final name = rawName.isNotEmpty ? rawName.split(' ').first : 'Aile';
    final mood = HealthStore.todayMood();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
                title: AppLocalizations.of(context).saglik, subtitle: 'Ailenizin sağlık merkezi'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _welcome(name),
                  const SizedBox(height: 16),
                  _categories(),
                  const SizedBox(height: 20),
                  _quickAccessTitle(),
                  const SizedBox(height: 12),
                  _quickAccess(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _moodCard(mood)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _tipCard(),
                  const SizedBox(height: 14),
                  _articlesCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome(String name) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1A3A), Color(0xFF141225)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x228B5CF6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(AppLocalizations.of(context).hdWelcome(name),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    const Icon(Icons.favorite_border,
                        color: Color(0xFF8B5CF6), size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(AppLocalizations.of(context).hdJourneyStart,
                    style:
                        const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5)),
              ],
            ),
          ),
          const Text('💜', style: TextStyle(fontSize: 46)),
        ],
      ),
    );
  }

  Widget _categories() {
    final cats = [
      (
        'Aile Sağlığı',
        'Anne + Baba',
        Icons.groups_rounded,
        [const Color(0xFF10B981), const Color(0xFF059669)],
        () => _go(const FamilySaglikScreen())
      ),
      (
        'Kadın Sağlığı',
        'Anne için',
        Icons.favorite_rounded,
        [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        () => _go(const KadinSaglikScreen())
      ),
      (
        'Çocuk Sağlığı',
        'Çocuk için',
        Icons.child_care_rounded,
        [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        () => _go(const CocukSaglikScreen())
      ),
    ];
    return Row(
      children: cats.map((c) {
        return Expanded(
          child: GestureDetector(
            onTap: c.$5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.$4.first.withAlpha(60)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: c.$4),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: c.$4.first.withAlpha(90), blurRadius: 10),
                      ],
                    ),
                    child: Icon(c.$3, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(c.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(c.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 11)),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.$4.first.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward,
                        color: c.$4.first, size: 17),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _quickAccessTitle() => Text(AppLocalizations.of(context).hizliErisim,
      style: const TextStyle(
          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800));

  Widget _quickAccess() {
    final items = [
      ('İlaçlarım', Icons.medication_rounded, const Color(0xFF8B5CF6),
          () => _go(const FamilyHealthScreen())),
      ('İlaç Ekle', Icons.add_circle_rounded, const Color(0xFF14B8A6),
          () => _go(const MedicineAddScreen())),
      ('Hatırlatma', Icons.notifications_active_rounded,
          const Color(0xFFF59E0B), () => _go(const MedicineReminderScreen())),
      ('Aşı Takvimi', Icons.vaccines_rounded, const Color(0xFF14B8A6),
          () => _go(const VaccinationScreen())),
      ('Sağlık Kayıtlarım', Icons.description_rounded, const Color(0xFF3B82F6),
          () => _go(const FamilyHealthScreen(initialTab: 2))),
      // "Belirtiler Kontrolü" yalnızca Kadın Sağlığı bölümünde (semptom takibi
      // döngüyle birlikte orada) — genel hızlı erişimden kaldırıldı.
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: items.map((it) {
        return GestureDetector(
          onTap: it.$4,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: it.$3.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(it.$2, color: it.$3, size: 24),
                ),
                const SizedBox(height: 10),
                Text(it.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _moodCard(int? mood) {
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
              const Icon(Icons.trending_up, color: Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).hdDailySummary,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context).hMoodQuestion,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (i) {
              final m = _moods[i];
              final sel = mood == i;
              return GestureDetector(
                onTap: () async {
                  await HealthStore.setMood(i);
                  setState(() {});
                },
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? m.$3.withAlpha(40) : const Color(0xFF1A1A24),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? m.$3 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(m.$1, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 6),
                    Text(m.$2,
                        style: TextStyle(
                            color: sel ? m.$3 : const Color(0xFF6B7280),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0F2A26), Color(0xFF13131A)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2214B8A6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xFF14B8A6), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(AppLocalizations.of(context).hTodaySuggestion,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Icon(Icons.auto_awesome,
                        size: 13, color: Color(0xFF14B8A6)),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<String>(
                  future: HealthStore.aiDailyTip(),
                  initialData: HealthStore.dailyTip(),
                  builder: (context, snap) => Text(
                    snap.data ?? HealthStore.dailyTip(),
                    style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 13.5,
                        height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _articlesCard() {
    return GestureDetector(
      onTap: () => _go(const HealthArticlesScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1A1330), Color(0xFF14122B)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x226366F1)),
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
              child: const Icon(Icons.menu_book_rounded,
                  color: Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).hdArticles,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(AppLocalizations.of(context).hdArticlesSub,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      if (mounted) setState(() {});
    });
  }
}
