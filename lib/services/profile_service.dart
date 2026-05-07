import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../domain/models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase;
  final Box<dynamic> _userBox;

  ProfileService(this._supabase, this._userBox);

  /// Factory: mevcut Supabase client ve Hive userBox ile instance oluşturur.
  static Future<ProfileService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception('Supabase bağlantısı yok');
    final box = await Hive.openBox<dynamic>('userBox');
    return ProfileService(client, box);
  }

  Future<ProfileModel> getCurrentProfile() async {
    // 1. Cache kontrolü (TTL: 1 saat)
    final cached = _userBox.get('current_profile');
    if (cached != null) {
      final cacheTime = _userBox.get('profile_cache_time');
      if (cacheTime != null) {
        final parsed = DateTime.tryParse(cacheTime.toString());
        if (parsed != null &&
            DateTime.now().difference(parsed) < const Duration(hours: 1)) {
          return ProfileModel.fromMap(Map<String, dynamic>.from(cached as Map));
        }
      }
    }

    // 2. Supabase sorgusu
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException('Oturum açık değil');

    final profileResponse = await _supabase
        .from('profiles')
        .select('''
          id, display_name, full_name, avatar_url,
          is_premium, premium_expires_at, xp, badges
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (profileResponse == null) {
      throw AppAuthException('Profil bulunamadı');
    }

    // family_id ve role family_members üzerinden çek (profiles'ta olmayabilir)
    // Eğer family_members sorgusu başarısız olursa (örn. RLS), profili yine de döndür
    Map<String, dynamic>? familyMember;
    try {
      familyMember = await _supabase
          .from('family_members')
          .select('family_id, role, families(name)')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      // family_members erişilemezse profiller tablosundan family_id almaya çalış
      familyMember = null;
    }

    // profiles tablosundan da family_id alınabilir (021 migration'ında eklendi)
    final profileFamilyId = profileResponse['family_id'] as String?;

    final merged = <String, dynamic>{
      ...profileResponse,
      'family_id': familyMember?['family_id'] ?? profileFamilyId,
      'families': familyMember?['families'],
      'role': familyMember?['role'] ?? 'member',
    };

    final profile = ProfileModel.fromMap(merged);

    // 3. Cache'e kaydet
    await _userBox.put('current_profile', merged);
    await _userBox.put('profile_cache_time', DateTime.now().toIso8601String());

    return profile;
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException('Oturum açık değil');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['display_name'] = fullName;
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('profiles').update(updates).eq('id', userId);

    // Cache'i temizle (bir sonraki get'te yeniden çek)
    await _userBox.delete('current_profile');
    await _userBox.delete('profile_cache_time');
  }

  String? get currentFamilyId {
    final cached = _userBox.get('current_profile');
    if (cached != null) {
      return (cached as Map)['family_id'] as String?;
    }
    return null;
  }

  String get currentRole {
    final cached = _userBox.get('current_profile');
    if (cached != null) {
      return ((cached as Map)['role'] ?? 'member') as String;
    }
    return 'member';
  }
}
