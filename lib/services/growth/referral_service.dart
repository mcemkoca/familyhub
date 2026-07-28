import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/errors.dart';
import '../../core/supabase_client.dart';
import '../notification_service.dart';
import '../../core/analytics/analytics_service.dart';
import '../localization/locale_service.dart';

class ReferralService {
  static String _text(Map<String, String> values) { final lang = LocaleService.resolveInitialLocale().languageCode; return values[lang] ?? values['tr']!; }
  static const String _inviteLinkBase = 'https://familyhub.app/join';

  static Future<String> generateInviteLink(String familyId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw AppAuthException(_text(const {'tr': 'Giriş yapmalısınız', 'en': 'You must sign in', 'nl': 'Je moet inloggen', 'fr': 'Vous devez vous connecter'}));

    final code = _generateReferralCode(userId, familyId);

    await SupabaseConfig.client.from('referrals').insert({
      'code': code,
      'inviter_id': userId,
      'family_id': familyId,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'active',
    });

    return '$_inviteLinkBase?ref=$code';
  }

  static Future<Map<String, dynamic>?> processReferral(String code) async {
    final response = await SupabaseConfig.client
        .from('referrals')
        .select('*, inviter:profiles!referrals_inviter_id_fkey(display_name)')
        .eq('code', code)
        .maybeSingle();

    if (response == null) return null;

    AnalyticsService.track(
      'referral_click',
      properties: {'code': code, 'inviter': response['inviter_id']},
    );

    return response;
  }

  static Future<void> completeReferral(String code, String newUserId) async {
    final referral = await SupabaseConfig.client
        .from('referrals')
        .update({
          'invited_id': newUserId,
          'completed_at': DateTime.now().toIso8601String(),
          'status': 'completed',
        })
        .eq('code', code)
        .select()
        .maybeSingle();

    if (referral == null) return;
    await _rewardInviter(referral['inviter_id'] as String);

    AnalyticsService.track(
      'referral_complete',
      properties: {
        'code': code,
        'inviter': referral['inviter_id'],
        'invited': newUserId,
      },
    );
  }

  static Future<void> _rewardInviter(String inviterId) async {
    try {
      await SupabaseConfig.client.rpc(
        'add_premium_days',
        params: {'user_id': inviterId, 'days': 7},
      );

      await NotificationService.showInstantNotification(
        title: _text(const {'tr': '🎉 Davet Ödülü!', 'en': '🎉 Referral Reward!', 'nl': '🎉 Uitnodigingsbeloning!', 'fr': '🎉 Récompense de parrainage !'}),
        body: _text(const {'tr': 'Bir arkadaşını davet ettin! 7 gün Premium kazandın.', 'en': 'You invited a friend and earned 7 days of Premium!', 'nl': 'Je hebt een vriend uitgenodigd en 7 dagen Premium verdiend!', 'fr': 'Vous avez invité un ami et gagné 7 jours de Premium !'}),
      );
    } catch (_) {
      // Reward failure is non-critical
    }
  }

  static String _generateReferralCode(String userId, String familyId) {
    final hash = sha256
        .convert(
          utf8.encode(
            '$userId:$familyId:${DateTime.now().millisecondsSinceEpoch}',
          ),
        )
        .toString();
    return hash.substring(0, 8).toUpperCase();
  }
}
