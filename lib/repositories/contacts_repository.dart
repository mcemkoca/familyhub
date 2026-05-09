import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;

class FamilyContact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String type;
  final String? avatarUrl;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  FamilyContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.type = 'other',
    this.avatarUrl,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory FamilyContact.fromJson(Map<String, dynamic> json) => FamilyContact(
    id: json['id']?.toString() ?? '',
    name: (json['name'] as String?) ?? '',
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    type: (json['type'] as String?) ?? 'other',
    avatarUrl: json['avatar_url']?.toString(),
    notes: json['notes']?.toString(),
    createdBy: json['created_by']?.toString(),
    createdAt: DateTime.parse(
      (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'type': type,
    'avatar_url': avatarUrl,
    'notes': notes,
  };
}

class ContactsRepository {
  static final ContactsRepository _instance = ContactsRepository._internal();
  factory ContactsRepository() => _instance;
  ContactsRepository._internal();
  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  String? get _userId => _safeClient?.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw app_errors.AppAuthException('Giriş yapmalısınız');
    }
  }

  Future<List<FamilyContact>> getContacts(String familyId) async {
    try {
      _checkAuth();
      final response = await _safeClient!
          .from('family_contacts')
          .select('*')
          .eq('family_id', familyId)
          .order('name', ascending: true);
      return (response as List)
          .map((e) => FamilyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ContactsRepository.getContacts error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Stream<List<FamilyContact>> watchContacts(String familyId) {
    try {
      return _safeClient!
          .from('family_contacts')
          .stream(primaryKey: ['id'])
          .order('name')
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => FamilyContact.fromJson(e))
                .toList(),
          );
    } catch (e) {
      debugPrint('ContactsRepository.watchContacts error: $e');
      return Stream.error(
        app_errors.AppDatabaseException('Veritabanı hatası: $e'),
      );
    }
  }

  Future<FamilyContact> createContact({
    required String familyId,
    required String name,
    String? phone,
    String? email,
    String type = 'other',
    String? notes,
  }) async {
    try {
      _checkAuth();
      final response = await _safeClient!
          .from('family_contacts')
          .insert({
            'family_id': familyId,
            'name': name,
            'phone': phone,
            'email': email,
            'type': type,
            'notes': notes,
            'created_by': _userId,
          })
          .select()
          .single();
      return FamilyContact.fromJson(response);
    } catch (e) {
      debugPrint('ContactsRepository.createContact error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    try {
      _checkAuth();
      await _safeClient!.from('family_contacts').update(data).eq('id', id);
    } catch (e) {
      debugPrint('ContactsRepository.updateContact error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      _checkAuth();
      await _safeClient!.from('family_contacts').delete().eq('id', id);
    } catch (e) {
      debugPrint('ContactsRepository.deleteContact error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }
}
