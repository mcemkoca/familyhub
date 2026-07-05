import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/routine.dart';
import '../services/auth_service.dart';

class RoutineRepository with RepositoryErrorHandler {
  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  String get _table => 'routines';

  Future<List<Routine>> getRoutines(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getRoutines');
  }

  Future<List<Routine>> getRoutinesByType(
    String familyId,
    RoutineType type,
  ) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .eq('type', type.name)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getRoutinesByType');
  }

  Future<Routine> getById(String id) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (response == null) throw Exception('Rutin bulunamadı: $id');
      return Routine.fromJson(response);
    }, 'getById');
  }

  Future<Routine> create(Routine routine) async {
    return handleRepositoryCall(() async {
      final data = routine.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return Routine.fromJson(response);
    }, 'create');
  }

  Future<Routine> update(Routine routine) async {
    return handleRepositoryCall(() async {
      final data = routine.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('created_by')
        ..remove('family_id');
      final response = await _client
          .from(_table)
          .update(data)
          .eq('id', routine.id)
          .select()
          .single();
      return Routine.fromJson(response);
    }, 'update');
  }

  Future<void> delete(String id) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).delete().eq('id', id);
    }, 'delete');
  }

  Stream<List<Routine>> watchRoutines(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) => data.map((e) => Routine.fromJson(e)).toList());
    } catch (e) {
      debugPrint('RoutineRepository.watchRoutines error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchRoutines]: $e'));
    }
  }

  Future<void> updateStatus(String id, RoutineStatus status) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({'status': status.toJson()})
          .eq('id', id);
    }, 'updateStatus');
  }

  Future<void> updateSteps(String id, List<RoutineStep> steps) async {
    return handleRepositoryCall(() async {
      await _client
          .from(_table)
          .update({'steps': steps.map((s) => s.toJson()).toList()})
          .eq('id', id);
    }, 'updateSteps');
  }
}
