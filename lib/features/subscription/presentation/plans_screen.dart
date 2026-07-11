import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

import '../application/subscription_providers.dart';
import '../domain/subscription_tier.dart';

/// Plan karşılaştırma / paywall ekranı. Aylık↔Yıllık toggle.
/// NOT: Gerçek satın alma (StoreKit/Play Billing) henüz bağlı değil —
/// "Satın al" CTA'sı bilinçli olarak sonraki slice'a bırakıldı (sahte akış yok).
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentTier = ref.watch(currentTierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(t.plansTitle,
            style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _billingToggle(t),
          const SizedBox(height: 20),
          for (final tier in SubscriptionTier.values)
            _PlanCard(
              tier: tier,
              yearly: _yearly,
              isCurrent: tier == currentTier,
            ),
        ],
      ),
    );
  }

  Widget _billingToggle(AppLocalizations t) {
    const accent = Color(0xFF6366F1);
    Widget seg(String label, bool yearly) {
      final active = _yearly == yearly;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _yearly = yearly),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        seg(t.plansMonthly, false),
        seg(t.plansYearly, true),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionTier tier;
  final bool yearly;
  final bool isCurrent;

  const _PlanCard({
    required this.tier,
    required this.yearly,
    required this.isCurrent,
  });

  static const accent = Color(0xFF6366F1);

  String _name(AppLocalizations t) => switch (tier) {
        SubscriptionTier.basic => t.planBasic,
        SubscriptionTier.plus => t.planPlus,
        SubscriptionTier.complete => t.planComplete,
      };

  String _tagline(AppLocalizations t) => switch (tier) {
        SubscriptionTier.basic => t.planBasicTagline,
        SubscriptionTier.plus => t.planPlusTagline,
        SubscriptionTier.complete => t.planCompleteTagline,
      };

  List<String> _highlights(AppLocalizations t) => switch (tier) {
        SubscriptionTier.basic => [
            t.planFeatCore,
            t.planFeatStorage('500 MB'),
            t.planFeatHistory('30'),
          ],
        SubscriptionTier.plus => [
            t.planFeatPlusIntel,
            t.planFeatLegal,
            t.planFeatExport,
            t.planFeatStorage('10 GB'),
            t.planFeatHistory('90'),
          ],
        SubscriptionTier.complete => [
            t.planFeatProactive,
            t.planFeatRoutines,
            t.planFeatGuest,
            t.planFeatStorage('50 GB'),
            t.planFeatUnlimitedHistory,
          ],
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final price = PlanCatalog.pricingFor(tier);
    final highlighted = tier == SubscriptionTier.plus;

    final amount = yearly ? price.yearly : price.monthly;
    final suffix = price.isFree
        ? ''
        : (yearly ? t.gatePerYear : t.gatePerMonth);
    final priceLabel =
        price.isFree ? t.plansFree : '€${amount.toStringAsFixed(2)}$suffix';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? accent : const Color(0xFF23233A),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_name(t),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (highlighted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x336366F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(t.plansPopular,
                    style: const TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            const Spacer(),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x3310B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(t.plansCurrent,
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 4),
          Text(_tagline(t),
              style:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(priceLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            if (yearly && !price.isFree && price.yearlySavingsPercent > 0) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  t.plansSave(price.yearlySavingsPercent),
                  style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          for (final h in _highlights(t))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(h,
                      style: const TextStyle(
                          color: Color(0xFFD1D5DB), fontSize: 14)),
                ),
              ]),
            ),
          const SizedBox(height: 8),
          if (!isCurrent && !price.isFree)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: accent),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.plansComingSoon)),
                );
              },
              child: Text(t.plansChoose(_name(t)),
                  style: const TextStyle(
                      color: accent, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
