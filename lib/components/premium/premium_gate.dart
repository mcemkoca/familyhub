import 'package:flutter/material.dart';

import '../../core/analytics/analytics_service.dart';
import '../../services/billing/subscription_service.dart';

/// Blurs / locks child widget if user is not premium.
/// Tapping the locked overlay shows an upgrade bottom sheet.
class PremiumGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final VoidCallback? onLockedTap;

  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (_hasAccess()) return child;

    return GestureDetector(
      onTap: () {
        onLockedTap?.call();
        _showUpgradeModal(context);
      },
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(166),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Color(0xFFF59E0B), size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Premium Gerekli',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    feature,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAccess() {
    // Feature-specific premium checks
    final lower = feature.toLowerCase();
    if (lower.contains('ai') || lower.contains('öneri')) {
      return SubscriptionService.canUseAI();
    }
    if (lower.contains('geçmiş') || lower.contains('history')) {
      return SubscriptionService.canAccessHistory();
    }
    if (lower.contains('dışa aktar') || lower.contains('export')) {
      return SubscriptionService.canExportData();
    }
    if (lower.contains('akıllı ev') || lower.contains('smart home')) {
      return SubscriptionService.canEnableSmartHome();
    }
    if (lower.contains('sağlık') || lower.contains('health')) {
      return SubscriptionService.canViewHealthSummary();
    }
    // Default: any premium tier
    return SubscriptionService.canAccessHistory();
  }

  void _showUpgradeModal(BuildContext context) {
    AnalyticsService.track('premium_gate_shown', properties: {'feature': feature});

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PremiumUpgradeSheet(feature: feature),
    );
  }
}

class _PremiumUpgradeSheet extends StatelessWidget {
  final String feature;

  const _PremiumUpgradeSheet({required this.feature});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 48),
            const SizedBox(height: 16),
            Text(
              '$feature Özelliği',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu özelliği kullanmak için Premium\'a yükseltin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleUpgrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Premium\'a Yükselt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Şimdi Değil', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade(BuildContext context) async {
    final offering = await SubscriptionService.getOfferings();
    final packages = offering?.availablePackages;

    if (packages == null || packages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şu anda ürün bulunamadı. Lütfen daha sonra tekrar deneyin.')),
        );
      }
      return;
    }

    final success = await SubscriptionService.purchasePackage(packages.first);
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium aktif! 🎉')),
      );
    }
  }
}
