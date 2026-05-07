import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class BackupService {
  final SupabaseClient _supabase;
  final Box<dynamic> _backupBox;
  final Box<dynamic> _settingsBox;

  BackupService(this._supabase, this._backupBox, this._settingsBox);

  static Future<BackupService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception('Supabase bağlantısı yok');
    final backupBox = await Hive.openBox<dynamic>('backupBox');
    final settingsBox = await Hive.openBox<dynamic>('settingsBox');
    return BackupService(client, backupBox, settingsBox);
  }

  Future<Map<String, dynamic>> createBackup(String familyId) async {
    // 1. Tüm veriyi topla
    final backupData = <String, dynamic>{
      'profiles': await _supabase
          .from('profiles')
          .select()
          .eq('family_id', familyId),
      'family_members': await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId),
      'child_accounts': await _supabase
          .from('child_accounts')
          .select()
          .eq('family_id', familyId),
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    // 2. Supabase'e kaydet
    final response = await _supabase.from('family_backups').insert({
      'family_id': familyId,
      'data_json': backupData,
    }).select().single();

    // 3. Local cache'e metadata kaydet
    await _backupBox.put('last_backup', {
      'id': response['id'],
      'created_at': response['created_at'],
      'size_kb': (backupData.toString().length / 1024).round(),
    });

    return backupData;
  }

  Future<void> restoreBackup(String backupId) async {
    // 1. Yedeği çek
    final response = await _supabase
        .from('family_backups')
        .select('data_json')
        .eq('id', backupId)
        .single();

    final data = response['data_json'] as Map<String, dynamic>;

    // 2. Hive'a yaz (offline kullanım için)
    await _settingsBox.put('restored_profiles', data['profiles']);
    await _settingsBox.put('restored_members', data['family_members']);
    await _settingsBox.put('restored_children', data['child_accounts']);
    await _settingsBox.put('restore_timestamp', DateTime.now().toIso8601String());
  }

  Future<List<Map<String, dynamic>>> getBackupHistory(String familyId) async {
    return await _supabase
        .from('family_backups')
        .select('id, created_at, data_json->version')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<Map<String, dynamic>?> getLastBackupInfo(String familyId) async {
    // 1. Cache kontrolü
    final cached = _backupBox.get('last_backup');
    if (cached != null) return Map<String, dynamic>.from(cached as Map);

    // 2. Supabase
    final response = await _supabase
        .from('family_backups')
        .select('id, created_at, size_bytes')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final info = {
        'id': response['id'],
        'created_at': response['created_at'],
        'size_kb': ((response['size_bytes'] as int? ?? 0) / 1024).round(),
      };
      await _backupBox.put('last_backup', info);
      return info;
    }
    return null;
  }

  Future<String?> getLastBackupRelativeTime() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();

    final familyId = profile?['family_id'] as String?;
    if (familyId == null) return null;

    final backups = await _supabase
        .from('family_backups')
        .select('created_at')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (backups == null) return 'Henüz yok';

    final last = DateTime.tryParse(backups['created_at'].toString());
    if (last == null) return 'Henüz yok';

    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}
