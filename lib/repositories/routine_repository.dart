import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/models/routine.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class RoutineRepository with RepositoryErrorHandler {
  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  SupabaseClient? get _safe => AuthService.safeClient;
  String get _table => 'routines';

  // ── Yerel (Hive) fallback — bulut yoksa/çevrimdışıysa rutinler kaybolmasın ──
  static const _localKey = 'local_routines';

  List<Routine> _readLocal() {
    final raw = HiveService.getSetting(_localKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocal(List<Routine> items) async {
    await HiveService.setSetting(
        _localKey, jsonEncode(items.map((r) => r.toJson()).toList()));
  }

  Future<List<Routine>> getRoutines(String familyId) async {
    if (_safe == null) return _readLocal();
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      final cloud = (response as List)
          .map((e) => Routine.fromJson(e as Map<String, dynamic>))
          .toList();
      final locals = _readLocal().where((r) => r.id.startsWith('local_'));
      return [...cloud, ...locals];
    } catch (_) {
      return _readLocal();
    }
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
    Future<Routine> saveLocal() async {
      final json = routine.toJson();
      json['id'] = 'local_${const Uuid().v4()}';
      final local = Routine.fromJson(json);
      await _writeLocal([..._readLocal(), local]);
      return local;
    }

    if (_safe == null) return saveLocal();
    try {
      final data = routine.toJson()..remove('id');
      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      return Routine.fromJson(response);
    } catch (_) {
      return saveLocal();
    }
  }

  Future<Routine> update(Routine routine) async {
    // Yerel rutin → Hive'da güncelle.
    if (routine.id.startsWith('local_')) {
      final updated =
          _readLocal().map((r) => r.id == routine.id ? routine : r).toList();
      await _writeLocal(updated);
      return routine;
    }
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
    // Yerel rutin → Hive'dan sil.
    if (id.startsWith('local_')) {
      await _writeLocal(_readLocal().where((r) => r.id != id).toList());
      return;
    }
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
