// Stripe Payment Service — Skeleton (NOT YET ACTIVE)
// Activate by: setting STRIPE_PUBLISHABLE_KEY env var + calling StripePaymentService.init()
// Package: flutter_stripe (add to pubspec when activating)

import 'package:flutter/foundation.dart';
import 'localization/locale_service.dart';

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
  static String _text(Map<String, String> values) { final lang = LocaleService.resolveInitialLocale().languageCode; return values[lang] ?? values['tr']!; }

  static StripeProduct get premiumMonthly => StripeProduct(
    id: 'premium_monthly',
    name: _text(const {'tr': 'FamilyHub Plus — Aylık', 'en': 'FamilyHub Plus — Monthly', 'nl': 'FamilyHub Plus — Maandelijks', 'fr': 'FamilyHub Plus — Mensuel'}),
    amountCents: 899, // €8.99/ay
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_monthly',
  );

  static StripeProduct get premiumYearly => StripeProduct(
    id: 'premium_yearly',
    name: _text(const {'tr': 'FamilyHub Plus — Yıllık', 'en': 'FamilyHub Plus — Yearly', 'nl': 'FamilyHub Plus — Jaarlijks', 'fr': 'FamilyHub Plus — Annuel'}),
    amountCents: 7900, // €79.00/yıl (%27 indirim)
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_yearly',
  );

  static StripeProduct get familyPack => StripeProduct(
    id: 'family_pack',
    name: _text(const {'tr': 'Aile Paketi — Sınırsız Üye', 'en': 'Family Plan — Unlimited Members', 'nl': 'Gezinsabonnement — Onbeperkt aantal leden', 'fr': 'Forfait Famille — Membres illimités'}),
    amountCents: 1299, // €12.99/ay
    isSubscription: true,
    priceId: 'price_PLACEHOLDER_family',
  );
}

class StripePaymentService {
  StripePaymentService._();
  static final instance = StripePaymentService._();

  bool _initialized = false;

  // Features gated behind premium
  static List<String> get premiumFeatures {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    const values = {
      'tr': ['Sınırsız aile üyesi', 'Bulut yedekleme', 'Yapay zekâ gelişmiş modu', 'Sürücü güvenlik raporu', 'Çocuk dijital cüzdanı', 'Öncelikli destek'],
      'en': ['Unlimited family members', 'Cloud backup', 'Advanced AI mode', 'Driver safety report', 'Child digital wallet', 'Priority support'],
      'nl': ['Onbeperkt aantal gezinsleden', 'Cloudback-up', 'Geavanceerde AI-modus', 'Veiligheidsrapport voor bestuurders', 'Digitale kinderportemonnee', 'Prioriteitsondersteuning'],
      'fr': ['Membres de la famille illimités', 'Sauvegarde cloud', 'Mode IA avancé', 'Rapport de sécurité du conducteur', 'Portefeuille numérique pour enfant', 'Assistance prioritaire'],
    };
    return List.unmodifiable(values[lang] ?? values['tr']!);
  }

  /// Call this in main() when Stripe key is available.
  /// Currently a no-op until payment is activated.
  Future<void> init() async {
    // TODO (activate when ready):
    // Stripe.publishableKey = const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
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
