import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/context_snapshot.dart';
import '../services/auth_service.dart';

class ContextSnapshotRepository {
  static final ContextSnapshotRepository _instance =
      ContextSnapshotRepository._internal();
  factory ContextSnapshotRepository() => _instance;
  ContextSnapshotRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  String get _table => 'context_snapshots';

  Future<List<ContextSnapshot>> getRecentSnapshots(
    String memberId, {
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ContextSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ContextSnapshotRepository.getRecentSnapshots error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<ContextSnapshot> getLatestSnapshot(String memberId) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      return ContextSnapshot.fromJson(response);
    } catch (e) {
      debugPrint('ContextSnapshotRepository.getLatestSnapshot error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<ContextSnapshot> save(ContextSnapshot snapshot) async {
    try {
      final data = snapshot.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return ContextSnapshot.fromJson(response);
    } catch (e) {
      debugPrint('ContextSnapshotRepository.save error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteOldSnapshots(Duration maxAge) async {
    try {
      final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
      await _client.from(_table).delete().lt('created_at', cutoff);
    } catch (e) {
      debugPrint('ContextSnapshotRepository.deleteOldSnapshots error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }
}
