import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/context_snapshot.dart';
import '../services/auth_service.dart';

class ContextSnapshotRepository with RepositoryErrorHandler {
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
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ContextSnapshot.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getRecentSnapshots');
  }

  Future<ContextSnapshot> getLatestSnapshot(String memberId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      return ContextSnapshot.fromJson(response);
    }, 'getLatestSnapshot');
  }

  Future<ContextSnapshot> save(ContextSnapshot snapshot) async {
    return handleRepositoryCall(() async {
      final data = snapshot.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return ContextSnapshot.fromJson(response);
    }, 'save');
  }

  Future<void> deleteOldSnapshots(Duration maxAge) async {
    return handleRepositoryCall(() async {
      final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
      await _client.from(_table).delete().lt('created_at', cutoff);
    }, 'deleteOldSnapshots');
  }
}
