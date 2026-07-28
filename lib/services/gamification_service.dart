
import '../core/supabase_client.dart';
import 'auth_service.dart';

class GamificationService {
  static final _client = SupabaseConfig.client;

  static Future<void> addXp(int amount) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    await _client.rpc('add_user_xp', params: {
      'p_user_id': userId,
      'p_amount': amount,
    });

    await checkBadges(userId);
  }

  static Future<void> checkBadges(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('xp, badges')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) return;
    final currentXp = profile['xp'] as int? ?? 0;
    final currentBadges = (profile['badges'] as List<dynamic>? ?? []).cast<String>();

    final allBadges = await _client.from('badges').select('*');
    final newBadges = <String>[];

    for (final badge in allBadges) {
      final id = badge['id'] as String;
      final threshold = badge['threshold_xp'] as int;
      if (currentXp >= threshold && !currentBadges.contains(id)) {
        newBadges.add(id);
      }
    }

    if (newBadges.isNotEmpty) {
      await _client.from('profiles').update({
        'badges': [...currentBadges, ...newBadges],
      }).eq('id', userId);
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final profile = await _client
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    final familyId = profile?['family_id'] as String?;
    if (familyId == null) return [];

    final response = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, xp, badges')
        .eq('family_id', familyId)
        .order('xp', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getAllBadges() async {
    final response = await _client.from('badges').select('*').order('threshold_xp', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }
}