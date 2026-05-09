import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';

class SubscriptionRepository with RepositoryErrorHandler {
  static final SubscriptionRepository _instance =
      SubscriptionRepository._internal();
  factory SubscriptionRepository() => _instance;
  SubscriptionRepository._internal();

  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  SupabaseClient get client => _safeClient!;
  String? get currentUserId => _safeClient?.auth.currentUser?.id;

  Future<void> activatePremium(String userId, String tier) async {
    return handleRepositoryCall(() async {
      final amount = tier == 'family' ? 9.99 : 4.99;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30)).toIso8601String();

      await client.from('subscriptions').insert({
        'user_id': userId,
        'subscription_tier': tier,
        'amount': amount,
        'currency': 'EUR',
        'status': 'active',
        'expires_at': expiresAt,
      });

      await client.from('profiles').update({
        'is_premium': true,
        'subscription_tier': tier,
        'subscription_expires_at': expiresAt,
        'updated_at': now.toIso8601String(),
      }).eq('id', userId);
    }, 'activatePremium');
  }
}
