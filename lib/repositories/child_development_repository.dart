import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/models/child_development_log.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';

class ChildDevelopmentRepository {
  static final ChildDevelopmentRepository _instance =
      ChildDevelopmentRepository._internal();
  factory ChildDevelopmentRepository() => _instance;
  ChildDevelopmentRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  Future<List<ChildDevelopmentLog>> getMyLogs({
    DevelopmentLogType? type,
    int limit = 50,
  }) async {
    _checkSession();
    try {
      var query = _client
          .from('child_development_logs')
          .select('*')
          .eq('child_id', _childId!);

      if (type != null) {
        query = query.eq('log_type', type.name);
      }

      final response = await query
          .order('logged_at', ascending: false)
          .limit(limit);
      final list = (response as List)
          .map((e) => ChildDevelopmentLog.fromJson(e as Map<String, dynamic>))
          .toList();
      await HiveService.saveChildDevLogs(list);
      return list;
    } catch (_) {
      final cached = HiveService.getChildDevLogs();
      if (type != null) {
        return cached.where((l) => l.logType == type).toList();
      }
      return cached;
    }
  }

  Future<List<ChildDevelopmentLog>> getLogsByType(
    DevelopmentLogType type,
  ) async {
    return getMyLogs(type: type);
  }

  Stream<List<ChildDevelopmentLog>> watchMyLogs() {
    try {
      final childId = _childId;
      if (childId == null) return Stream.value([]);
      return _client
          .from('child_development_logs')
          .stream(primaryKey: ['id'])
          .map((data) {
            final filtered = data
                .where((e) => e['child_id'] == childId)
                .toList();
            filtered.sort(
              (a, b) => (a['logged_at'] ?? '').toString().compareTo(
                (b['logged_at'] ?? '').toString(),
              ),
            );
            return filtered
                .map((e) => ChildDevelopmentLog.fromJson(e))
                .toList();
          });
    } catch (e) {
      debugPrint('ChildDevelopmentRepository.watchMyLogs error: $e');
      return Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  // ── Parent methods ──
  Future<ChildDevelopmentLog> createLog({
    required DevelopmentLogType logType,
    required String value,
    String? unit,
    DateTime? loggedAt,
    String? notes,
  }) async {
    try {
      _checkSession();
      final response = await _client
          .from('child_development_logs')
          .insert({
            'family_id': _familyId!,
            'child_id': _childId!,
            'log_type': logType.name,
            'value': value,
            'unit': unit,
            'logged_at': (loggedAt ?? DateTime.now())
                .toIso8601String()
                .substring(0, 10),
            'notes': notes,
          })
          .select()
          .single();
      return ChildDevelopmentLog.fromJson(response);
    } catch (e) {
      debugPrint('ChildDevelopmentRepository.createLog error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      _checkSession();
      await _client.from('child_development_logs').delete().eq('id', id);
    } catch (e) {
      debugPrint('ChildDevelopmentRepository.deleteLog error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }
}
