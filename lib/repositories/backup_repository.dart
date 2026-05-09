import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../services/child_auth_service.dart';

class BackupRepository with RepositoryErrorHandler {
  static final BackupRepository _instance = BackupRepository._internal();
  factory BackupRepository() => _instance;
  BackupRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      // Önce profiles'tan dene (eski kullanıcılar için)
      try {
        final profile = await _client
            .from('profiles')
            .select('family_id, display_name, email')
            .eq('id', user.id)
            .maybeSingle();
        final familyId = profile?['family_id'] as String?;
        if (familyId != null) return familyId;
      } catch (e) {
        debugPrint('BackupRepository._getFamilyId error: $e');
      }

      // Yoksa family_members üzerinden çek
      try {
        final fm = await _client
            .from('family_members')
            .select('family_id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (fm?['family_id'] != null) return fm!['family_id'] as String;
      } catch (e) {
        debugPrint('BackupRepository._getFamilyId error: $e');
      }
    }
    return ChildAuthService.currentFamilyId;
  }

  Future<Map<String, dynamic>?> _getCreatorInfo() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select('id, display_name, email')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          return {
            'id': profile['id'] as String,
            'name': (profile['display_name'] ?? 'Üye') as String,
            'email': profile['email'] as String? ?? user.email ?? '',
          };
        }
      } catch (e) {
        debugPrint('BackupRepository._getCreatorInfo error: $e');
      }
    }
    final session = ChildAuthService.currentSession;
    if (session != null) {
      return {'id': session.childId, 'name': session.childName, 'email': ''};
    }
    return null;
  }

  /// Collect all Hive data into a JSON map
  Future<Map<String, dynamic>> _collectHiveData() async {
    final data = <String, dynamic>{};

    for (final boxName in [
      'tasks',
      'transactions',
      'chat',
      'streaks',
      'settings',
    ]) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          final map = <String, dynamic>{};
          for (final key in box.keys) {
            map[key.toString()] = box.get(key);
          }
          data[boxName] = map;
        }
      } catch (e) { debugPrint('Backup repository error: $e'); }
    }

    return data;
  }

  Future<int> _calculateSize(Map<String, dynamic> data) async {
    try {
      final jsonStr = jsonEncode(data);
      return utf8.encode(jsonStr).length;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> createBackup() async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      final creator = await _getCreatorInfo();
      if (familyId == null || creator == null) {
        throw Exception('Aile veya kullanıcı bilgisi bulunamadı');
      }

      final data = await _collectHiveData();
      final size = await _calculateSize(data);
      final recordCount = data.values.fold<int>(0, (sum, box) {
        if (box is Map) return sum + box.length;
        return sum;
      });

      final response = await _client
          .from('family_backups')
          .insert({
            'family_id': familyId,
            'created_by': creator['id'],
            'creator_name': creator['name'],
            'creator_email': creator['email'],
            'data_json': data,
            'size_bytes': size,
            'record_count': recordCount,
            'backup_type': 'manual',
          })
          .select()
          .single();

      return response;
    }, 'createBackup');
  }

  Future<List<Map<String, dynamic>>> getBackups() async {
    return handleRepositoryCall(() async {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('family_backups')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).cast<Map<String, dynamic>>();
    }, 'getBackups');
  }

  Future<Map<String, dynamic>?> getBackupById(String id) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from('family_backups')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      return response;
    }, 'getBackupById');
  }

  Future<void> deleteBackup(String id) async {
    return handleRepositoryCall(() async {
      await _client.from('family_backups').delete().eq('id', id);
    }, 'deleteBackup');
  }

  Stream<List<Map<String, dynamic>>> watchBackups() async* {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) {
        yield [];
        return;
      }
      yield* _client
          .from('family_backups')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) => data.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('BackupRepository.watchBackups error: $e');
      yield* Stream.error(RepositoryException('Beklenmeyen hata [watchBackups]: $e'));
    }
  }
}
