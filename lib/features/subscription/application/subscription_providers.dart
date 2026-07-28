import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../domain/subscription_tier.dart';
import 'entitlement_service.dart';

/// Aktif kullanıcının abonelik katmanı (userMetadata → tier). Legacy güvenli.
final currentTierProvider = Provider<SubscriptionTier>((ref) {
  try {
    final meta = SupabaseConfig.safeClient?.auth.currentUser?.userMetadata;
    final key = meta?['subscription_tier']?.toString() ??
        (meta?['is_premium'] == true ? 'premium' : 'free');
    return tierFromKey(key);
  } catch (_) {
    return SubscriptionTier.basic;
  }
});

/// Merkezi entitlement servisi — modüller `ref.watch(entitlementProvider)`.
final entitlementProvider = Provider<EntitlementService>(
  (ref) => EntitlementService(ref.watch(currentTierProvider)),
);
