import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../services/auth_service.dart';
import '../services/child_auth_service.dart';

class SafeArrivalRepository with RepositoryErrorHandler {
  static final SafeArrivalRepository _instance =
      SafeArrivalRepository._internal();
  factory SafeArrivalRepository() => _instance;
  SafeArrivalRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    return handleRepositoryCall(() async {
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('family_id')
            .eq('id', user.id)
            .maybeSingle();
        final familyId = profile?['family_id'] as String?;
        if (familyId != null) return familyId;
      }
      return ChildAuthService.currentFamilyId;
    }, '_getFamilyId');
  }

  Future<List<Map<String, dynamic>>> getActiveMonitors() async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];
      final response = await _client
          .from('safe_arrivals')
          .select('*')
          .eq('family_id', familyId)
          .inFilter('status', ['active', 'delayed'])
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    }, 'getActiveMonitors');
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];
      final response = await _client
          .from('safe_arrivals')
          .select('*')
          .eq('family_id', familyId)
          .inFilter('status', ['arrived', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(20);
      return (response as List).cast<Map<String, dynamic>>();
    }, 'getHistory');
  }

  Future<Map<String, dynamic>> createMonitor({
    required String memberId,
    required String memberName,
    required String destination,
    required int durationMinutes,
  }) async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      final userId =
          AuthService.currentUserId ?? ChildAuthService.currentChildId;
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      final response = await _client
          .from('safe_arrivals')
          .insert({
            'family_id': familyId,
            'member_id': memberId,
            'member_name': memberName,
            'destination': destination,
            'estimated_arrival': DateTime.now()
                .add(Duration(minutes: durationMinutes))
                .toIso8601String(),
            'duration_minutes': durationMinutes,
            'created_by': userId,
          })
          .select()
          .single();

      return response;
    }, 'createMonitor');
  }

  Future<void> updateProgress(String id, double progress) async {
    return handleRepositoryCall(() async {
      await _client
          .from('safe_arrivals')
          .update({
            'progress': progress,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }, 'updateProgress');
  }

  Future<void> markArrived(String id) async {
    return handleRepositoryCall(() async {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'arrived',
            'actual_arrival': DateTime.now().toIso8601String(),
            'progress': 1.0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }, 'markArrived');
  }

  Future<void> markDelayed(String id, int delayMinutes) async {
    return handleRepositoryCall(() async {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'delayed',
            'delay_minutes': delayMinutes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }, 'markDelayed');
  }

  Future<void> cancelMonitor(String id) async {
    return handleRepositoryCall(() async {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }, 'cancelMonitor');
  }
}
