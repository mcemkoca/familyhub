import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/supabase_client.dart';
import '../../core/utils/subscription_status.dart';

/// RevenueCat-backed subscription management.
///
/// RevenueCat webhooks are the only authority allowed to update premium fields
/// in Supabase. The client reads entitlements but never grants them to itself.
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

  static Future<bool> purchasePlan(String planId) async {
    final offering = await getOfferings();
    if (offering == null) {
      throw Exception('Abonelik planları şu anda kullanılamıyor');
    }

    Package? selected;
    for (final package in offering.availablePackages) {
      if (package.identifier == planId ||
          package.storeProduct.identifier == planId) {
        selected = package;
        break;
      }
    }
    if (selected == null) {
      throw Exception('Seçilen abonelik planı mağazada bulunamadı');
    }
    return purchasePackage(selected);
  }

  static Future<bool> purchasePackage(Package package) async {
    if (!isConfigured) return false;
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium = customerInfo.entitlements.active.containsKey('premium');
      if (isPremium) {
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
      await Purchases.restorePurchases();
    } catch (e) {
      AnalyticsService.trackBillingError(e.toString());
    }
  }

  static Future<bool> canCreateEvent(int currentCount) async =>
      currentCount < 10 || await checkPremiumAsync();
  static Future<bool> canAddMember(int currentCount) async =>
      currentCount < 4 || await checkPremiumAsync();
  static Future<bool> canAccessHistory() => checkPremiumAsync();
  static Future<bool> canExportData() => checkPremiumAsync();
  static Future<bool> canUseAI() => checkPremiumAsync();
  static Future<bool> canEnableSmartHome() => checkPremiumAsync();
  static Future<bool> canViewHealthSummary() => checkPremiumAsync();

  /// Validates premium status against the server-managed profile and expiry.
  static Future<bool> checkPremiumAsync() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('is_premium, subscription_tier, subscription_expires_at')
          .eq('id', user.id)
          .maybeSingle();

      final expiresAt = response?['subscription_expires_at'];
      return hasActivePremium(
        isPremium: response?['is_premium'] == true,
        subscriptionTier: response?['subscription_tier']?.toString(),
        expiresAt: expiresAt == null
            ? null
            : DateTime.tryParse(expiresAt.toString()),
      );
    } catch (_) {
      return false;
    }
  }
}
