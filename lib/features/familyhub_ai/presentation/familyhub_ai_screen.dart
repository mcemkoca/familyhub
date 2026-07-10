import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../../family_intelligence/application/family_intelligence_providers.dart';
import '../application/familyhub_ai_providers.dart';
import '../domain/ai_action.dart';

/// FamilyHub AI — bağımsız bölüm. Bağlamsal (deterministik) hızlı aksiyonlar,
/// veri minimizasyonu notu ve güvenlik disclaimer'ı. Kritik aksiyonlar
/// onay gerektirir; LOW-risk navigasyon aksiyonları doğrudan çalışır.
class FamilyHubAIScreen extends ConsumerWidget {
  const FamilyHubAIScreen({super.key});

  String _label(AppLocalizations t, String key) => switch (key) {
        'fhaQuickReviewTasks' => t.fhaQuickReviewTasks,
        'fhaQuickShopping' => t.fhaQuickShopping,
        'fhaQuickPlanDay' => t.fhaQuickPlanDay,
        'fhaQuickBudget' => t.fhaQuickBudget,
        'fhaQuickLegal' => t.fhaQuickLegal,
        _ => key,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(familySnapshotProvider);
    final quick = ref.watch(aiQuickActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.familyHubAITitle,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(t.familyHubAISubtitle,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 16),
          // Bağlam özeti (sayısal — hassas veri yok)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1330), Color(0xFF141225)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x2A8B5CF6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF8B5CF6), size: 18),
                  const SizedBox(width: 8),
                  Text(t.fhaSummaryTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _stat('${s.pendingTasks}', Icons.check_circle_outline),
                  _stat('${s.todayEvents}', Icons.event_outlined),
                  _stat('${s.pendingShoppingItems}',
                      Icons.shopping_cart_outlined),
                  _stat('${s.memberCount}', Icons.people_outline),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(t.fhaQuickActionsTitle,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final q in quick) _actionTile(context, t, q),
          const SizedBox(height: 16),
          // Sohbet henüz yok — dürüst bilgilendirme
          _note(t.fhaChatComingSoon, const Color(0xFF6366F1),
              Icons.chat_bubble_outline_rounded),
          const SizedBox(height: 10),
          _note(t.fhaContextInfo, const Color(0xFF10B981),
              Icons.privacy_tip_outlined),
          const SizedBox(height: 10),
          _note(t.fhaDisclaimer, const Color(0xFFF59E0B),
              Icons.info_outline_rounded),
        ],
      ),
    );
  }

  Widget _stat(String value, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _actionTile(BuildContext context, AppLocalizations t, AIQuickAction q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // LOW-risk navigasyon aksiyonu — onay gerektirmez; şema doğrulanır.
            final a = q.action;
            if (!a.requiresConfirmation &&
                AIActionPolicy.isValid(a) &&
                a.route != null) {
              context.push(a.route!);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(children: [
              const Icon(Icons.bolt_rounded,
                  size: 18, color: Color(0xFFA5B4FC)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_label(t, q.labelKey),
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF6B7280)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _note(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB), fontSize: 11.5, height: 1.4)),
          ),
        ]),
      );
}
