import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class MoodRepository {
  static final MoodRepository _instance = MoodRepository._internal();
  factory MoodRepository() => _instance;
  MoodRepository._internal();
  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', user.id)
          .maybeSingle();
      return profile?['family_id'] as String?;
    } catch (e) {
      debugPrint('MoodRepository._getFamilyId error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<List<MoodEntry>> getEntries() async {
    try {
      final cached = HiveService.getMoodEntries();
      if (cached.isNotEmpty) return cached;

      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('mood_entries')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(50);

      final entries = (response as List).map((e) => _fromJson(e)).toList();
      await HiveService.saveMoodEntries(entries);
      return entries;
    } catch (e) {
      debugPrint('MoodRepository.getEntries error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<MoodEntry> createEntry(String emoji, {String? note}) async {
    try {
      final familyId = await _getFamilyId();
      final userId = AuthService.currentUserId;
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      final response = await _client
          .from('mood_entries')
          .insert({
            'family_id': familyId,
            'user_id': userId,
            'emoji': emoji,
            'note': note,
          })
          .select()
          .single();

      final created = _fromJson(response);
      final all = await getEntries();
      await HiveService.saveMoodEntries([created, ...all]);
      return created;
    } catch (e) {
      debugPrint('MoodRepository.createEntry error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _client.from('mood_entries').delete().eq('id', id);
      final all = await getEntries();
      await HiveService.saveMoodEntries(all.where((e) => e.id != id).toList());
    } catch (e) {
      debugPrint('MoodRepository.deleteEntry error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  MoodEntry _fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String,
      emoji: json['emoji'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
