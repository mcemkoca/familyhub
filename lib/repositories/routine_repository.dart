import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/routine.dart';
import '../services/auth_service.dart';

class RoutineRepository {
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
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      debugPrint('RoutineRepository.getRoutines error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<Routine>> getRoutinesByType(
    String familyId,
    RoutineType type,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .eq('type', type.name)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      debugPrint('RoutineRepository.getRoutinesByType error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<Routine> getById(String id) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('id', id)
          .single();
      return Routine.fromJson(response);
    } catch (e) {
      debugPrint('RoutineRepository.getById error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<Routine> create(Routine routine) async {
    try {
      final data = routine.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return Routine.fromJson(response);
    } catch (e) {
      debugPrint('RoutineRepository.create error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<Routine> update(Routine routine) async {
    try {
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
    } catch (e) {
      debugPrint('RoutineRepository.update error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      debugPrint('RoutineRepository.delete error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
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
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  Future<void> updateStatus(String id, RoutineStatus status) async {
    try {
      await _client
          .from(_table)
          .update({'status': status.toJson()})
          .eq('id', id);
    } catch (e) {
      debugPrint('RoutineRepository.updateStatus error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateSteps(String id, List<RoutineStep> steps) async {
    try {
      await _client
          .from(_table)
          .update({'steps': steps.map((s) => s.toJson()).toList()})
          .eq('id', id);
    } catch (e) {
      debugPrint('RoutineRepository.updateSteps error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }
}
