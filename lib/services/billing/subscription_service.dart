import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/supabase_client.dart';

/// RevenueCat-backed subscription management.
/// API key via --dart-define=REVENUECAT_API_KEY=...
class SubscriptionService {
  static const _apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Purchases.configure(PurchasesConfiguration(_apiKey));

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      await Purchases.logIn(userId);
    }
  }

  static Future<Offering?> getOfferings() async {
    if (!isConfigured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      AnalyticsService.trackBillingError(e.toString());
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (!isConfigured) return false;
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium = customerInfo.entitlements.active.containsKey('premium');

      if (isPremium) {
        final expiration = customerInfo.entitlements.active['premium']?.expirationDate;
        await SupabaseConfig.client.from('profiles').update({
          'is_premium': true,
          'subscription_tier': 'premium',
          'subscription_expires_at': expiration,
        }).eq('id', SupabaseConfig.client.auth.currentUser!.id);

        AnalyticsService.trackRevenue(
          package.identifier,
          package.storeProduct.price,
          package.storeProduct.currencyCode,
        );
      }

      return isPremium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        AnalyticsService.trackPurchaseFailed(e.message ?? 'unknown');
      }
      return false;
    } catch (e) {
      AnalyticsService.trackPurchaseFailed(e.toString());
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    if (!isConfigured) return;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey('premium');
      final expiration = customerInfo.entitlements.active['premium']?.expirationDate;

      await SupabaseConfig.client.from('profiles').update({
        'is_premium': isPremium,
        'subscription_tier': isPremium ? 'premium' : 'free',
        'subscription_expires_at': expiration,
      }).eq('id', SupabaseConfig.client.auth.currentUser!.id);
    } catch (e) {
      AnalyticsService.trackBillingError(e.toString());
    }
  }

  // ── Feature gates ──
  static bool canCreateEvent(int currentCount) => currentCount < 10 || _isPremium();
  static bool canAddMember(int currentCount) => currentCount < 4 || _isPremium();
  static bool canAccessHistory() => _isPremium();
  static bool canExportData() => _isPremium();
  static bool canUseAI() => true; // Local pool tüm kullanıcılara açık
  static bool canEnableSmartHome() => _isPremium();
  static bool canViewHealthSummary() => _isPremium();

  static bool _isPremium() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return false;

    // Check user metadata first (fast path)
    final tier = user.userMetadata?['subscription_tier'];
    if (tier == 'premium' || tier == 'family') {
      return true;
    }

    // Fallback to legacy is_premium flag
    return user.userMetadata?['is_premium'] == true;
  }

  /// Async premium check that validates against Supabase and expiry date.
  static Future<bool> checkPremiumAsync() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('subscription_tier, subscription_expires_at')
          .eq('id', user.id)
          .maybeSingle();

      final tier = response?['subscription_tier']?.toString();
      if (tier == 'premium' || tier == 'family') {
        final expiresAt = response?['subscription_expires_at'];
        if (expiresAt != null) {
          final expiry = DateTime.tryParse(expiresAt.toString());
          if (expiry != null && expiry.isBefore(DateTime.now())) {
            return false;
          }
        }
        return true;
      }

      return response?['is_premium'] == true;
    } catch (e) {
      return false;
    }
  }
}
