import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../presentation/providers/insights_provider.dart';

/// Hub'da gerçek verilerden üretilen akıllı uyarılar/öneriler.
/// Kural tabanlı (çevrimdışı), en önemli 3 içgörüyü gösterir.
class SmartInsightsCard extends ConsumerWidget {
  const SmartInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(familyInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();
    final top = insights.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262631)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded,
                    size: 18, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).sicTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.familyReport),
                  child: Row(
                    children: [
                      Text(AppLocalizations.of(context).frpTitle,
                          style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF8B5CF6), size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const Divider(height: 16, color: Color(0xFF1F1F29)),
              _InsightRow(insight: top[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: insight.route == null
          ? null
          : () => context.push(insight.route!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: insight.color.withAlpha(28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(insight.icon, color: insight.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(insight.message,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12.5,
                          height: 1.35)),
                ],
              ),
            ),
            if (insight.route != null)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF6B7280), size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
