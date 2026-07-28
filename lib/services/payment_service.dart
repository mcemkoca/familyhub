import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import 'localization/locale_service.dart';

/// Client-side Stripe payment service.
class PaymentService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  /// Present Stripe Payment Sheet for a given price.
  static Future<bool> presentPaymentSheet(String priceId) async {
    try {
      final userId = SupabaseConfig.safeClient?.auth.currentUser?.id;
      if (userId == null) throw AppAuthException(_text(const {'tr': 'Oturum açık değil', 'en': 'You are not signed in', 'nl': 'Je bent niet ingelogd', 'fr': 'Vous n’êtes pas connecté'}));

      // 1. Create PaymentIntent via Supabase Edge Function
      final response = await SupabaseConfig.safeClient!.functions.invoke(
        'create-payment-intent',
        body: {'price_id': priceId, 'user_id': userId},
      );
      final data = response.data as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String?;
      if (clientSecret == null) throw Exception(_text(const {'tr': 'Ödeme başlatılamadı', 'en': 'Could not start the payment', 'nl': 'De betaling kon niet worden gestart', 'fr': 'Impossible de démarrer le paiement'}));

      // 2. Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'FamilyHub',
          style: ThemeMode.system,
        ),
      );

      // 3. Present sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Confirm subscription in Supabase
      final expiresAt = DateTime.now().add(const Duration(days: 30));
      await SupabaseConfig.safeClient!.from('premium_subscriptions').insert({
        'user_id': userId,
        'tier': 'premium',
        'provider': 'stripe',
        'status': 'active',
        'expires_at': expiresAt.toIso8601String(),
      });

      await SupabaseConfig.safeClient!
          .from('profiles')
          .update({
            'is_premium': true,
            'subscription_tier': 'premium',
            'subscription_expires_at': expiresAt.toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } on StripeException catch (e) {
      if (e.error.code.name == 'Canceled') return false;
      throw Exception('${_text(const {'tr': 'Ödeme hatası', 'en': 'Payment error', 'nl': 'Betalingsfout', 'fr': 'Erreur de paiement'})}: ${e.error.localizedMessage}');
    } catch (e) {
      throw Exception('${_text(const {'tr': 'Ödeme başlatılamadı', 'en': 'Could not start the payment', 'nl': 'De betaling kon niet worden gestart', 'fr': 'Impossible de démarrer le paiement'})}: $e');
    }
  }
}
