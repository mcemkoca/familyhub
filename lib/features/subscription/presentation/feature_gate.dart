import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

import '../application/subscription_providers.dart';
import '../domain/subscription_tier.dart';

/// Kilitli özelliklere merkezi erişim kontrolü + paywall sheet.
/// Mevcut çalışan akışlar retroaktif kilitlenMEZ; yalnızca çağrıldığı yerde.
class FeatureGate {
  const FeatureGate._();

  /// [feature] izinliyse true döner. Değilse paywall sheet gösterir, false döner.
  /// Kullanım: `if (!await FeatureGate.require(context, ref, Feature.x)) return;`
  static Future<bool> require(
    BuildContext context,
    WidgetRef ref,
    Feature feature,
  ) async {
    final ent = ref.read(entitlementProvider);
    if (ent.canUse(feature)) return true;
    if (!context.mounted) return false;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FeatureGateSheet(feature: feature),
    );
    return false;
  }
}

/// Paywall alt sayfası — özelliğin hangi planda açıldığını ve fiyatını gösterir.
class FeatureGateSheet extends ConsumerWidget {
  final Feature feature;
  const FeatureGateSheet({super.key, required this.feature});

  String _tierName(AppLocalizations t, SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.basic => t.planBasic,
        SubscriptionTier.plus => t.planPlus,
        SubscriptionTier.complete => t.planComplete,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final required = PlanCatalog.minTierFor(feature);
    final price = PlanCatalog.pricingFor(required);
    const accent = Color(0xFF6366F1);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141420),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x336366F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_outline, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            t.gateTitle,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            t.gateBody(_tierName(t, required)),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _tierName(t, required),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '€${price.monthly.toStringAsFixed(2)}${t.gatePerMonth}',
                  style: const TextStyle(
                      color: accent, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/plans');
            },
            child: Text(t.gateSeePlans,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.gateNotNow,
                style: const TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}
