import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/models/family_info.dart';
import '../domain/models/family_member_model.dart';

class FamilyService {
  final SupabaseClient _supabase;
  final Box<dynamic> _membersBox;

  FamilyService(this._supabase, this._membersBox);

  static Future<FamilyService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception('Supabase bağlantısı yok');
    final box = await Hive.openBox<dynamic>('membersBox');
    return FamilyService(client, box);
  }

  SupabaseClient get client => _supabase;

  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    // 1. Cache kontrolü (TTL: 30 dk)
    final cachedAdults = _membersBox.get('family_members_$familyId');
    final cachedChildren = _membersBox.get('child_accounts_$familyId');
    final cacheTime = _membersBox.get('members_cache_time_$familyId');

    if (cachedAdults != null && cachedChildren != null && cacheTime != null) {
      final parsed = DateTime.tryParse(cacheTime.toString());
      if (parsed != null &&
          DateTime.now().difference(parsed) < const Duration(minutes: 30)) {
        final adults = (cachedAdults as List)
            .map((e) => FamilyMemberModel.fromAdult(Map<String, dynamic>.from(e as Map)))
            .toList();
        final children = (cachedChildren as List)
            .map((e) => FamilyMemberModel.fromChild(Map<String, dynamic>.from(e as Map)))
            .toList();
        return [...adults, ...children];
      }
    }

    // 2. Paralel sorgular (ebeveynler + çocuklar)
    final futures = await Future.wait([
      _supabase
          .from('family_members')
          .select('''
            user_id, role, display_name, color, joined_at,
            profiles (display_name, avatar_url)
          ''')
          .eq('family_id', familyId)
          .eq('is_active', true),
      _supabase
          .from('child_accounts')
          .select('id, name, avatar_url, age')
          .eq('family_id', familyId),
    ]);

    final adults = (futures[0] as List)
        .map((e) => FamilyMemberModel.fromAdult(Map<String, dynamic>.from(e as Map)))
        .toList();

    final children = (futures[1] as List)
        .map((e) => FamilyMemberModel.fromChild(Map<String, dynamic>.from(e as Map)))
        .toList();

    final allMembers = [...adults, ...children];

    // 3. Cache'e kaydet
    await _membersBox.put('family_members_$familyId', futures[0]);
    await _membersBox.put('child_accounts_$familyId', futures[1]);
    await _membersBox.put(
        'members_cache_time_$familyId', DateTime.now().toIso8601String());

    return allMembers;
  }

  Future<void> addChildAccount({
    required String familyId,
    required String name,
    required String pin,
    int? age,
    String? avatarUrl,
  }) async {
    // PIN 4 haneli, sadece rakam kontrolü
    if (!RegExp(r'^\d{4}\$').hasMatch(pin)) {
      throw const FormatException('PIN 4 haneli rakam olmalı');
    }

    await _supabase.from('child_accounts').insert({
      'family_id': familyId,
      'name': name,
      'pin': pin,
      'age': age,
      'avatar_url': avatarUrl,
    });

    // Cache'i temizle
    await _membersBox.delete('child_accounts_$familyId');
    await _membersBox.delete('members_cache_time_$familyId');
  }

  Future<int> getMemberCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final fm = await _supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', userId)
        .maybeSingle();

    final familyId = fm?['family_id'] as String?;
    if (familyId == null) return 0;

    final res = await _supabase
        .from('family_members')
        .select('id')
        .eq('family_id', familyId)
        .eq('is_active', true);

    return (res as List).length;
  }

  Future<FamilyInfo?> getFamilyInfo(String familyId) async {
    try {
      final res = await _supabase
          .from('families')
          .select('*')
          .eq('id', familyId)
          .maybeSingle();

      if (res == null) return null;

      final memberRes = await _supabase
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('is_active', true);

      final data = Map<String, dynamic>.from(res);
      data['member_count'] = (memberRes as List).length;

      return FamilyInfo.fromJson(data);
    } catch (e) {
      debugPrint('getFamilyInfo error: \$e');
      return null;
    }
  }

  Future<List<FamilyHistory>> getFamilyHistory(String familyId) async {
    try {
      final res = await _supabase
          .from('family_history')
          .select('*')
          .eq('family_id', familyId)
          .order('event_date', ascending: false);

      return (res as List)
          .map((e) => FamilyHistory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('getFamilyHistory error: \$e');
      return [];
    }
  }

  Future<String> uploadFamilyPhoto(String familyId, File file) async {
    // ignore: unused_local_variable
    final ext = file.path.split('.').last;
    final path = 'family_photos/\$familyId.\$ext';

    await _supabase.storage.from('family-assets').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('family-assets').getPublicUrl(path);
  }

  Future<void> updateFamilyInfo({
    required String familyId,
    String? name,
    String? description,
    DateTime? foundedDate,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (foundedDate != null) data['founded_date'] = foundedDate.toIso8601String();
    if (photoUrl != null) data['photo_url'] = photoUrl;

    await _supabase.from('families').update(data).eq('id', familyId);
  }

  Future<void> deleteFamilyHistory(String historyId) async {
    await _supabase.from('family_history').delete().eq('id', historyId);
  }

  Future<void> addFamilyHistory({
    required String familyId,
    required String title,
    String? content,
    DateTime? eventDate,
    String? type,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('family_history').insert({
      'family_id': familyId,
      'title': title,
      'content': content,
      'event_date': eventDate?.toIso8601String(),
      'type': type ?? 'memory',
      'created_by': userId,
    });
  }
}
