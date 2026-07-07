import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities.dart';
import '../../../services/ai/ai_content_service.dart';
import '../../providers/app_providers.dart';
import '../budget/subscription_screen.dart' show subscriptionProvider;
import '../child/child_development_screen.dart' show childDevProvider;
import '../child/child_dev_store.dart';
import '../health/health_store.dart';

/// Haftalık Aile Karnesi — bütçe, gelişim, sağlık ve aktiviteyi tek ekranda
/// birleştiren aile içgörü panosu. Skorlar gerçek yerel veriden hesaplanır;
/// veri yoksa dürüstçe boş/0 gösterir. AI yorumu haftalık önbelleklidir.
class FamilyReportScreen extends ConsumerWidget {
  const FamilyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    // ── Bütçe skoru: bu ayki tasarruf oranı ──
    final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
    final monthTxs = txs.where(
        (t) => t.createdAt.year == now.year && t.createdAt.month == now.month);
    final income = monthTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = monthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final hasBudget = income > 0 || expense > 0;
    final budgetScore = income > 0
        ? (((income - expense) / income) * 100).clamp(0, 100).round()
        : 0;

    // ── Gelişim skoru: çocukların ortalama genel skoru ──
    final children = ref.watch(childDevProvider);
    int devScore = 0;
    var devHasData = false;
    if (children.isNotEmpty) {
      var sum = 0;
      for (final c in children) {
        final s = DevStore.overallScore(c.id, c.devGroup);
        sum += s;
        if (s > 0) devHasData = true;
      }
      devScore = (sum / children.length).round();
    }

    // ── Sağlık skoru: bugünkü ruh hali (0-4 → 0-100) ──
    final mood = HealthStore.todayMood();
    final healthHasData = mood != null;
    final healthScore = mood != null ? ((mood / 4) * 100).round() : 0;

    // ── Aktivite skoru: planlama aktifliği (görev + etkinlik sayısı) ──
    final tasks = ref.watch(myTasksProvider).valueOrNull ?? const [];
    final events = ref.watch(upcomingEventsProvider).valueOrNull ?? const [];
    final planCount = tasks.length + events.length;
    final activityHasData = planCount > 0;
    final activityScore = (planCount * 15).clamp(0, 100);

    final subs = ref.watch(subscriptionProvider);
    final fixedMonthly = subs
        .where((s) => s.active)
        .fold<double>(0, (s, x) => s + x.monthlyAmount);

    // Genel skor: veri olan kategorilerin ortalaması.
    final parts = <int>[];
    if (hasBudget) parts.add(budgetScore);
    if (devHasData) parts.add(devScore);
    if (healthHasData) parts.add(healthScore);
    if (activityHasData) parts.add(activityScore);
    final overall =
        parts.isEmpty ? 0 : (parts.reduce((a, b) => a + b) / parts.length).round();

    final categories = <_Cat>[
      _Cat('Bütçe', budgetScore, hasBudget, const Color(0xFFA855F7),
          Icons.savings_rounded,
          hasBudget ? 'Tasarruf oranın' : 'Henüz işlem yok'),
      _Cat('Gelişim', devScore, devHasData, const Color(0xFFF43F5E),
          Icons.child_care_rounded,
          devHasData ? 'Çocuk gelişim skoru' : 'Değerlendirme yapılmadı'),
      _Cat('Sağlık', healthScore, healthHasData, const Color(0xFF14B8A6),
          Icons.favorite_rounded,
          healthHasData ? 'Bugünkü ruh hali' : 'Ruh hali girilmedi'),
      _Cat('Aktivite', activityScore, activityHasData, const Color(0xFF3B82F6),
          Icons.task_alt_rounded,
          activityHasData
              ? '$planCount planlı görev/etkinlik'
              : 'Planlı görev/etkinlik yok'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Aile Karnesi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _overallCard(overall, parts.isEmpty),
          const SizedBox(height: 18),
          const Text('Kategoriler',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final c in categories) ...[
            _catCard(c),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          if (fixedMonthly > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262631)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'Aylık sabit giderin ≈€${fixedMonthly.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          _aiComment(context, overall, categories),
        ],
      ),
    );
  }

  Widget _overallCard(int overall, bool empty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1330), Color(0xFF141225)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x2A8B5CF6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: overall / 100,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFF2A2440),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                ),
                Text('%$overall',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Genel Aile Skoru',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                    empty
                        ? 'Bölümleri kullandıkça karnen dolacak. Bütçe, gelişim, sağlık ve görevlerden veri toplanır.'
                        : 'Bu haftaki aile performansının birleşik özeti.',
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12.5,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catCard(_Cat c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262631)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.color.withAlpha(28),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(c.icon, color: c.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text(c.hasData ? '%${c.score}' : '—',
                        style: TextStyle(
                            color: c.hasData ? c.color : const Color(0xFF6B7280),
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.hasData ? c.score / 100 : 0,
                    backgroundColor: const Color(0xFF262631),
                    valueColor: AlwaysStoppedAnimation(c.color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(c.note,
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiComment(BuildContext context, int overall, List<_Cat> cats) {
    final withData = cats.where((c) => c.hasData).toList();
    final summary = withData.isEmpty
        ? ''
        : withData
            .map((c) => '${c.label}: %${c.score}')
            .join(', ');
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AiContentService.weeklyList(
        topic: 'family_report_comment',
        prompt:
            'Bir ailenin haftalık karne skorları: Genel %$overall. $summary. '
            'Bu skorlara göre 2 cümlelik sıcak, motive edici bir yorum ve 2 '
            'iyileştirme önerisi yaz. Sadece JSON: '
            '{"items":[{"comment":"...","tips":["...","..."]}]}. Türkçe.',
        listKey: 'items',
        fallback: [
          {
            'comment': withData.isEmpty
                ? 'Uygulamayı kullandıkça buraya kişiselleştirilmiş aile yorumu gelecek.'
                : 'Aile olarak güzel ilerliyorsunuz. Küçük düzenli adımlar büyük fark yaratır.',
            'tips': const [
              'En düşük kategoriye bu hafta biraz zaman ayırın',
              'Küçük hedefler koyup birlikte takip edin',
            ],
          }
        ],
        maxTokens: 400,
      ),
      builder: (context, snap) {
        final data = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data!.first
            : const <String, dynamic>{};
        final comment = data['comment']?.toString() ?? '';
        final tips = (data['tips'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [];
        if (comment.isEmpty && snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF8B5CF6))),
              SizedBox(width: 10),
              Text('AI yorumu hazırlanıyor…',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ]),
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A1330), Color(0xFF16122B)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x1F8B5CF6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 18),
                SizedBox(width: 8),
                Text('AI Aile Yorumu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              Text(comment,
                  style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 13.5,
                      height: 1.45)),
              for (final t in tips)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: 15, color: Color(0xFFA5B4FC)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t,
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12.5,
                                  height: 1.35)),
                        ),
                      ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Cat {
  final String label;
  final int score;
  final bool hasData;
  final Color color;
  final IconData icon;
  final String note;
  const _Cat(
      this.label, this.score, this.hasData, this.color, this.icon, this.note);
}
