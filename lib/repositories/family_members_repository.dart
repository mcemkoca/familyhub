import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities.dart';
import '../core/supabase_client.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';

class FamilyMembersRepository {
  static final FamilyMembersRepository _instance =
      FamilyMembersRepository._internal();
  factory FamilyMembersRepository() => _instance;
  FamilyMembersRepository._internal();

  SupabaseClient? get _client => SupabaseConfig.safeClient;

  Future<String?> _getFamilyId() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await client
            .from('profiles')
            .select('family_id')
            .eq('id', user.id)
            .maybeSingle();
        final familyId = profile?['family_id'] as String?;
        if (familyId != null) return familyId;
      } catch (e) {
        debugPrint('FamilyMembersRepository._getFamilyId error: $e');
      }
    }
    return ChildAuthService.currentFamilyId;
  }

  Future<List<FamilyMember>> getMembers() async {
    final cached = HiveService.getFamilyMembers();
    if (cached.isNotEmpty) return cached;

    final familyId = await _getFamilyId();
    if (familyId == null) return [];

    final client = _client;
    if (client == null) return [];

    try {
      // Load family_members to get roles
      final fmResponse = await client
          .from('family_members')
          .select('*')
          .eq('family_id', familyId);
      final familyMembers = (fmResponse as List).cast<Map<String, dynamic>>();

      // Load profiles
      final profilesResponse = await client
          .from('profiles')
          .select('id, display_name, avatar_url, email')
          .eq('family_id', familyId);
      final profiles = (profilesResponse as List).cast<Map<String, dynamic>>();

      // Load child_accounts
      final childrenResponse = await client
          .from('child_accounts')
          .select('id, name, color, created_at')
          .eq('family_id', familyId);
      final children = (childrenResponse as List).cast<Map<String, dynamic>>();

      final result = <FamilyMember>[];

      // Add parents from profiles
      for (final p in profiles) {
        final id = p['id'] as String;
        final fm = familyMembers.firstWhere(
          (m) => m['user_id'] == id,
          orElse: () => {'role': 'parent'},
        );
        final roleStr = (fm['role'] ?? 'parent') as String;
        final role = _parseRole(roleStr);

        result.add(
          FamilyMember(
            id: id,
            name: (p['display_name'] ?? p['email'] ?? 'Üye') as String,
            initial: ((p['display_name'] ?? p['email'] ?? 'U') as String)[0]
                .toUpperCase(),
            color: _parseColor(fm['color']),
            avatarUrl: p['avatar_url'] as String?,
            role: role,
            isOnline: false, // Will be updated by SafetyService
            lastSeen: null,
            joinedAt: fm['joined_at'] != null
                ? DateTime.tryParse(fm['joined_at'].toString())
                : null,
          ),
        );
      }

      // Add children from child_accounts
      for (final c in children) {
        final id = c['id'] as String;
        final name = (c['name'] ?? 'Çocuk') as String;
        result.add(
          FamilyMember(
            id: id,
            name: name,
            initial: name.isNotEmpty ? name[0].toUpperCase() : 'C',
            color: _parseColor(c['color']),
            role: MemberRole.child,
            isOnline: false,
            lastSeen: c['created_at'] != null
                ? DateTime.tryParse(c['created_at'].toString())
                : null,
            joinedAt: c['created_at'] != null
                ? DateTime.tryParse(c['created_at'].toString())
                : null,
          ),
        );
      }

      await HiveService.saveFamilyMembers(result);
      return result;
    } catch (e) {
      debugPrint('FamilyMembersRepository.getMembers error: $e');
      return [];
    }
  }

  Stream<List<FamilyMember>> watchMembers() async* {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) {
        yield [];
        return;
      }
      final client = _client;
      if (client == null) {
        yield [];
        return;
      }
      // Watch both tables and reload on every change
      yield* client
          .from('family_members')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .asyncMap((_) => getMembers());
    } catch (e) {
      debugPrint('FamilyMembersRepository.watchMembers error: $e');
      yield* Stream.error(Exception('Veritabanı hatası: $e'));
    }
  }

  static MemberRole _parseRole(String? val) {
    return switch (val) {
      'admin' => MemberRole.admin,
      'parent' => MemberRole.parent,
      'teen' => MemberRole.teen,
      'child' => MemberRole.child,
      'elder' => MemberRole.elder,
      'guest' => MemberRole.guest,
      'baby' => MemberRole.baby,
      _ => MemberRole.parent,
    };
  }

  Future<void> updateRole(String userId, String familyId, String role) async {
    try {
      final client = _client;
      if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
      await client
          .from('family_members')
          .update({'role': role})
          .eq('user_id', userId)
          .eq('family_id', familyId);
    } catch (e) {
      debugPrint('FamilyMembersRepository.updateRole error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> removeMember(String userId, String familyId) async {
    try {
      final client = _client;
      if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
      await client
          .from('family_members')
          .delete()
          .eq('user_id', userId)
          .eq('family_id', familyId);
    } catch (e) {
      debugPrint('FamilyMembersRepository.removeMember error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  static Color _parseColor(dynamic val) {
    if (val == null) return const Color(0xFF3B82F6);
    if (val is int) return Color(val);
    if (val is String) {
      try {
        return Color(int.parse(val.replaceFirst('#', '0xFF')));
      } catch (_) {
        return const Color(0xFF3B82F6);
      }
    }
    return const Color(0xFF3B82F6);
  }
}
