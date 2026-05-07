import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';


class InviteService {
  final SupabaseClient _supabase;

  InviteService(this._supabase);

  static InviteService create() {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception('Supabase bağlantısı yok');
    return InviteService(client);
  }

  Future<String> generateInviteCode(String familyId, {String role = 'member'}) async {
    final response = await _supabase.rpc(
      'generate_invite_code',
      params: {'family_id': familyId, 'role': role},
    );
    return response as String;
  }

  Future<void> joinFamilyByCode(String code, String userId) async {
    // 1. Kodu doğrula
    final family = await _supabase
        .from('families')
        .select('id, invite_expires_at, invite_used')
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (family == null) throw FormatException('Geçersiz davet kodu');
    if (family['invite_used'] == true) throw FormatException('Kod zaten kullanılmış');

    final expiresAt = DateTime.tryParse(family['invite_expires_at'].toString());
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw FormatException('Kodun süresi dolmuş (24 saat)');
    }

    // 2. Kullanıcıyı aileye ekle
    await _supabase.from('family_members').insert({
      'user_id': userId,
      'family_id': family['id'],
      'role': 'member',
    });

    // 3. Kodu kullanılmış olarak işaretle
    await _supabase
        .from('families')
        .update({'invite_used': true})
        .eq('id', family['id']);
  }
}
