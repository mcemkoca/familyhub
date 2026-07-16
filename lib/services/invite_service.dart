import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import 'localization/locale_service.dart';


class InviteService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  final SupabaseClient _supabase;

  InviteService(this._supabase);

  static InviteService create() {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception(_text(const {'tr': 'Sunucu bağlantısı kurulamadı', 'en': 'Could not connect to the server', 'nl': 'Kan geen verbinding maken met de server', 'fr': 'Impossible de se connecter au serveur'}));
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

    if (family == null) throw FormatException(_text(const {'tr': 'Geçersiz davet kodu', 'en': 'Invalid invite code', 'nl': 'Ongeldige uitnodigingscode', 'fr': 'Code d’invitation invalide'}));
    if (family['invite_used'] == true) throw FormatException(_text(const {'tr': 'Kod zaten kullanılmış', 'en': 'The code has already been used', 'nl': 'De code is al gebruikt', 'fr': 'Le code a déjà été utilisé'}));

    final expiresAt = DateTime.tryParse(family['invite_expires_at'].toString());
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw FormatException(_text(const {'tr': 'Kodun süresi dolmuş (24 saat)', 'en': 'The code has expired (24 hours)', 'nl': 'De code is verlopen (24 uur)', 'fr': 'Le code a expiré (24 heures)'}));
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
        .eq('id', family['id'] as Object);
  }
}
