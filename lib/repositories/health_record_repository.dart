import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../services/auth_service.dart';
import '../domain/models/health_record.dart';

/// Sağlık kayıtları — aile-izole CRUD (Supabase `health_records`).
/// Backend RLS aile erişimini zorlar (spec §21); uygulama katmanı soft-delete
/// filtresini uygular. Bağlantı yoksa boş/işlemsiz döner (sahte başarı YOK).
class HealthRecordRepository {
  HealthRecordRepository._();
  static final instance = HealthRecordRepository._();

  SupabaseClient? get _client => SupabaseConfig.safeClient;

  /// Ailenin (opsiyonel üye/tip filtreli) silinmemiş kayıtları, tarihe göre.
  Future<List<HealthRecord>> listForFamily(
    String familyId, {
    String? memberId,
    String? recordType,
  }) async {
    final client = _client;
    if (client == null || familyId.isEmpty) return const [];
    try {
      var q = client
          .from('health_records')
          .select('*')
          .eq('family_id', familyId)
          .isFilter('deleted_at', null);
      if (memberId != null && memberId.isNotEmpty) {
        q = q.eq('member_id', memberId);
      }
      if (recordType != null && recordType.isNotEmpty) {
        q = q.eq('record_type', recordType);
      }
      final res = await q.order('record_date', ascending: false);
      return (res as List)
          .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('HealthRecordRepository.list error: $e');
      return const [];
    }
  }

  /// Kayıt oluştur — gerçek backend sonucu döner (başarısızsa null).
  Future<HealthRecord?> create(HealthRecord record) async {
    final client = _client;
    if (client == null) return null;
    try {
      final payload = record.toInsert()
        ..['created_by'] = AuthService.currentUserId;
      final res = await client
          .from('health_records')
          .insert(payload)
          .select()
          .single();
      return HealthRecord.fromJson(res);
    } catch (e) {
      if (kDebugMode) debugPrint('HealthRecordRepository.create error: $e');
      return null;
    }
  }

  /// Soft-delete (deleted_at damgası). Başarı bool döner.
  Future<bool> softDelete(String id) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('health_records').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_by': AuthService.currentUserId,
      }).eq('id', id);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('HealthRecordRepository.delete error: $e');
      return false;
    }
  }
}
