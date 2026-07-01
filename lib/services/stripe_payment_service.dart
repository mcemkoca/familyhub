// Stripe Payment Service — Skeleton (NOT YET ACTIVE)
// Activate by: setting STRIPE_PUBLISHABLE_KEY env var + calling StripePaymentService.init()
// Package: flutter_stripe (add to pubspec when activating)

import 'package:flutter/foundation.dart';

enum StripePaymentStatus { success, cancelled, failed, notConfigured }

class StripeProduct {
  final String id;
  final String name;
  final int amountCents;
  final String currency;
  final bool isSubscription;
  final String? priceId;

  const StripeProduct({
    required this.id,
    required this.name,
    required this.amountCents,
    this.currency = 'try',
    this.isSubscription = false,
    this.priceId,
  });
}

// Premium plan definitions (prices in kuruş)
class StripeProducts {
  static const premiumMonthly = StripeProduct(
    id: 'premium_monthly',
    name: 'FamilyHub Premium — Aylık',
    amountCents: 4999, // ₺49.99/ay
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_monthly',
  );

  static const premiumYearly = StripeProduct(
    id: 'premium_yearly',
    name: 'FamilyHub Premium — Yıllık',
    amountCents: 39999, // ₺399.99/yıl (%33 indirim)
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_yearly',
  );

  static const familyPack = StripeProduct(
    id: 'family_pack',
    name: 'Aile Paketi — 6 Üye',
    amountCents: 6999, // ₺69.99/ay
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_family',
  );
}

class StripePaymentService {
  StripePaymentService._();
  static final instance = StripePaymentService._();

  bool _initialized = false;
  static const _publishableKeyEnvKey = 'STRIPE_PUBLISHABLE_KEY';

  // Features gated behind premium
  static const premiumFeatures = [
    'Sınırsız aile üyesi',
    'Bulut yedekleme',
    'AI gelişmiş modu',
    'Sürücü güvenlik raporu',
    'Çocuk dijital cüzdanı',
    'Öncelikli destek',
  ];

  /// Call this in main() when Stripe key is available.
  /// Currently a no-op until payment is activated.
  Future<void> init() async {
    // TODO (activate when ready):
    // Stripe.publishableKey = const String.fromEnvironment(_publishableKeyEnvKey);
    // await Stripe.instance.applySettings();
    _initialized = false; // keep false until activated
    debugPrint('[Stripe] Payment system not yet activated');
  }

  /// Initiate a one-time or subscription payment.
  /// Returns [StripePaymentStatus.notConfigured] until activated.
  Future<StripePaymentStatus> startPayment(StripeProduct product) async {
    if (!_initialized) {
      debugPrint('[Stripe] Not initialized — payment skipped');
      return StripePaymentStatus.notConfigured;
    }

    // TODO (activate when ready):
    // 1. Call your backend /create-payment-intent or /create-subscription
    // 2. Receive clientSecret
    // 3. await Stripe.instance.initPaymentSheet(paymentSheetParameters: ...)
    // 4. await Stripe.instance.presentPaymentSheet()
    // 5. Return success/cancelled/failed based on result

    return StripePaymentStatus.notConfigured;
  }

  /// Verify subscription status from backend.
  Future<bool> checkSubscriptionActive(String userId) async {
    if (!_initialized) return false;
    // TODO: Call backend /subscription-status?userId=...
    return false;
  }

  bool get isActive => _initialized;
}
