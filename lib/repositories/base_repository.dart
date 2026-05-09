import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../core/utils/repository_mixin.dart';

abstract class BaseRepository<T> with RepositoryErrorHandler {
  final String table;

  BaseRepository(this.table);

  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  SupabaseClient get client => _safeClient!;

  String? get currentUserId => _safeClient?.auth.currentUser?.id;

  void _checkAuth() {
    if (_safeClient == null) {
      throw AppAuthException('Bağlantı hatası. Lütfen tekrar deneyin.');
    }
    if (currentUserId == null) {
      throw AppAuthException('Giriş yapmalısınız');
    }
  }

  Future<List<T>> query({
    Map<String, dynamic>? eq,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    return handleRepositoryCall(() async {
      _checkAuth();

      // ignore: avoid_dynamic_calls
      dynamic query = _safeClient!.from(table).select();

      eq?.forEach((key, value) {
        // ignore: avoid_dynamic_calls
        query = query.eq(key, value);
      });

      if (orderBy != null) {
        // ignore: avoid_dynamic_calls
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        // ignore: avoid_dynamic_calls
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }, 'query');
  }

  Future<T> insert(Map<String, dynamic> data) async {
    return handleRepositoryCall(() async {
      _checkAuth();

      final response = await _safeClient!
          .from(table)
          .insert({...data, 'created_at': DateTime.now().toIso8601String()})
          .select()
          .single();

      return fromJson(response);
    }, 'insert');
  }

  Future<T> update(String id, Map<String, dynamic> data) async {
    return handleRepositoryCall(() async {
      _checkAuth();

      final response = await _safeClient!
          .from(table)
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return fromJson(response);
    }, 'update');
  }

  Future<void> delete(String id) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      await _safeClient!.from(table).delete().eq('id', id);
    }, 'delete');
  }

  Stream<List<T>> watch({String? eqColumn, dynamic eqValue}) {
    try {
      final client = _safeClient;
      if (client == null) return const Stream.empty();

      // ignore: avoid_dynamic_calls
      dynamic query = client.from(table).stream(primaryKey: ['id']);

      if (eqColumn != null && eqValue != null) {
        // ignore: avoid_dynamic_calls
        query = query.eq(eqColumn, eqValue);
      }

      return (query as Stream<List<dynamic>>).map((data) => data.map((e) => fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      debugPrint('BaseRepository.watch error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watch]: $e'));
    }
  }

  T fromJson(Map<String, dynamic> json);
}
