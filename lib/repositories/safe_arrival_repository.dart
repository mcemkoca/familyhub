import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../services/auth_service.dart';
import '../services/child_auth_service.dart';

class SafeArrivalRepository {
  static final SafeArrivalRepository _instance =
      SafeArrivalRepository._internal();
  factory SafeArrivalRepository() => _instance;
  SafeArrivalRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    try {
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
    } catch (e) {
      debugPrint('SafeArrivalRepository._getFamilyId error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActiveMonitors() async {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];
      final response = await _client
          .from('safe_arrivals')
          .select('*')
          .eq('family_id', familyId)
          .inFilter('status', ['active', 'delayed'])
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('SafeArrivalRepository.getActiveMonitors error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
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
    } catch (e) {
      debugPrint('SafeArrivalRepository.getHistory error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<Map<String, dynamic>> createMonitor({
    required String memberId,
    required String memberName,
    required String destination,
    required int durationMinutes,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('SafeArrivalRepository.createMonitor error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateProgress(String id, double progress) async {
    try {
      await _client
          .from('safe_arrivals')
          .update({
            'progress': progress,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('SafeArrivalRepository.updateProgress error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> markArrived(String id) async {
    try {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'arrived',
            'actual_arrival': DateTime.now().toIso8601String(),
            'progress': 1.0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('SafeArrivalRepository.markArrived error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> markDelayed(String id, int delayMinutes) async {
    try {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'delayed',
            'delay_minutes': delayMinutes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('SafeArrivalRepository.markDelayed error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> cancelMonitor(String id) async {
    try {
      await _client
          .from('safe_arrivals')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('SafeArrivalRepository.cancelMonitor error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchFamilyArrivals() async* {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) {
        yield [];
        return;
      }
      yield* _client
          .from('safe_arrivals')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) => data.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('SafeArrivalRepository.watchFamilyArrivals error: $e');
      yield* Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }
}
