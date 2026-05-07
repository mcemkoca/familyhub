import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';

abstract class BaseRepository<T> {
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
    try {
      _checkAuth();

      dynamic query = _safeClient!.from(table).select();

      eq?.forEach((key, value) {
        query = query.eq(key, value);
      });

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((e) => fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('BaseRepository.query error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<T> insert(Map<String, dynamic> data) async {
    try {
      _checkAuth();

      final response = await _safeClient!
          .from(table)
          .insert({...data, 'created_at': DateTime.now().toIso8601String()})
          .select()
          .single();

      return fromJson(response);
    } catch (e, st) {
      debugPrint('BaseRepository.insert error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<T> update(String id, Map<String, dynamic> data) async {
    try {
      _checkAuth();

      final response = await _safeClient!
          .from(table)
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return fromJson(response);
    } catch (e, st) {
      debugPrint('BaseRepository.update error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      _checkAuth();
      await _safeClient!.from(table).delete().eq('id', id);
    } catch (e, st) {
      debugPrint('BaseRepository.delete error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Stream<List<T>> watch({String? eqColumn, dynamic eqValue}) {
    try {
      final client = _safeClient;
      if (client == null) return const Stream.empty();

      dynamic query = client.from(table).stream(primaryKey: ['id']);

      if (eqColumn != null && eqValue != null) {
        query = query.eq(eqColumn, eqValue);
      }

      return query.map((data) => data.map((e) => fromJson(e)).toList());
    } catch (e, st) {
      debugPrint('BaseRepository.watch error: $e');
      return Stream.error(AppDatabaseException('Veritabanı hatası: $e'));
    }
  }

  T fromJson(Map<String, dynamic> json);
}
