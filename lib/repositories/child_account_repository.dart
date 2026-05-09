import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import '../domain/models/child_account.dart';

class ChildAccountRepository {
  static final ChildAccountRepository _instance =
      ChildAccountRepository._internal();
  factory ChildAccountRepository() => _instance;
  ChildAccountRepository._internal();
  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  SupabaseClient get client => _safeClient!;

  String? get currentUserId => _safeClient?.auth.currentUser?.id;

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _checkAuth() {
    if (_safeClient == null) {
      throw AppAuthException('Bağlantı hatası. Lütfen tekrar deneyin.');
    }
    if (currentUserId == null) {
      throw AppAuthException('Giriş yapmalısınız');
    }
  }

  Future<List<ChildAccount>> getChildrenForFamily(String familyId) async {
    try {
      _checkAuth();
      final response = await client
          .from('child_accounts')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return (response as List).map((e) => ChildAccount.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ChildAccountRepository.getChildrenForFamily error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<ChildAccount> getChildById(String childId) async {
    try {
      _checkAuth();
      final response = await client
          .from('child_accounts')
          .select()
          .eq('id', childId)
          .single();

      return ChildAccount.fromJson(response);
    } catch (e) {
      debugPrint('ChildAccountRepository.getChildById error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<ChildAccount> createChild({
    required String familyId,
    required String name,
    required String pin,
    required ChildRole role,
    Color? color,
    String? avatarUrl,
    int? dailyScreenTimeMinutes,
    bool? canApproveTasks,
    bool? canSendMessages,
    bool? canViewBudget,
    int? age,
  }) async {
    try {
      _checkAuth();

      if (familyId.trim().isEmpty) {
        throw ValidationException(
          'Aile bilgisi eksik. Lütfen sayfayı yenileyin.',
        );
      }
      if (name.trim().length < 2) {
        throw ValidationException('İsim en az 2 karakter olmalı');
      }
      if (pin.length < 4 || pin.length > 6) {
        throw ValidationException('PIN 4-6 haneli olmalı');
      }

      final data = {
        'family_id': familyId,
        'name': name.trim(),
        'pin_hash': _hashPin(pin), // Client-side SHA-256 hash
        'role': role.name,
        'avatar_url': avatarUrl,
        'color': color != null
            ? '#${color.value.toRadixString(16).substring(2).toUpperCase()}'
            : '#3B82F6',
        'created_by': currentUserId,
        'daily_screen_time_minutes': dailyScreenTimeMinutes ?? 120,
        'can_approve_tasks': canApproveTasks ?? false,
        'can_send_messages': canSendMessages ?? true,
        'can_view_budget': canViewBudget ?? false,
        'age': age,
      };

      final response = await client
          .from('child_accounts')
          .insert(data)
          .select()
          .single();
      return ChildAccount.fromJson(response);
    } catch (e) {
      debugPrint('ChildAccountRepository.createChild error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<ChildAccount> updateChild(
    String childId, {
    String? name,
    String? pin,
    ChildRole? role,
    Color? color,
    String? avatarUrl,
    bool? isActive,
    int? dailyScreenTimeMinutes,
    bool? canApproveTasks,
    bool? canSendMessages,
    bool? canViewBudget,
    int? age,
  }) async {
    try {
      _checkAuth();

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (pin != null) data['pin_hash'] = _hashPin(pin);
      if (role != null) data['role'] = role.name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (color != null) {
        data['color'] =
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      }
      if (isActive != null) data['is_active'] = isActive;
      if (dailyScreenTimeMinutes != null) {
        data['daily_screen_time_minutes'] = dailyScreenTimeMinutes;
      }
      if (canApproveTasks != null) data['can_approve_tasks'] = canApproveTasks;
      if (canSendMessages != null) data['can_send_messages'] = canSendMessages;
      if (canViewBudget != null) data['can_view_budget'] = canViewBudget;
      if (age != null) data['age'] = age;

      final response = await client
          .from('child_accounts')
          .update(data)
          .eq('id', childId)
          .select()
          .single();

      return ChildAccount.fromJson(response);
    } catch (e) {
      debugPrint('ChildAccountRepository.updateChild error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteChild(String childId) async {
    try {
      _checkAuth();
      await client.from('child_accounts').delete().eq('id', childId);
    } catch (e) {
      debugPrint('ChildAccountRepository.deleteChild error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<String?> uploadAvatar(String childId, String filePath) async {
    try {
      _checkAuth();
      final fileName =
          'avatars/$childId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from('family-gallery')
          .upload(fileName, File(filePath));
      return client.storage.from('family-gallery').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('ChildAccountRepository.uploadAvatar error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> updatePin(String childId, String newPin) async {
    try {
      _checkAuth();
      if (newPin.length < 4 || newPin.length > 6) {
        throw ValidationException('PIN 4-6 haneli olmalı');
      }
      await client
          .from('child_accounts')
          .update({'pin_hash': _hashPin(newPin)})
          .eq('id', childId);
    } catch (e) {
      debugPrint('ChildAccountRepository.updatePin error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> updateRemoteLock(
    String childId, {
    required bool enabled,
    DateTime? lockUntil,
    String? reason,
  }) async {
    try {
      _checkAuth();
      await client
          .from('child_accounts')
          .update({
            'remote_lock_enabled': enabled,
            'remote_lock_until': lockUntil?.toIso8601String(),
            'remote_lock_reason': reason,
          })
          .eq('id', childId);
    } catch (e) {
      debugPrint('ChildAccountRepository.updateRemoteLock error: $e');
      throw AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Stream<List<ChildAccount>> watchChildren(String familyId) {
    try {
      return client
          .from('child_accounts')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map(
            (data) => data
                .where((e) => e['is_active'] == true)
                .map((e) => ChildAccount.fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('ChildAccountRepository.watchChildren error: $e');
      return Stream.error(AppDatabaseException('Veritabanı hatası: $e'));
    }
  }
}
