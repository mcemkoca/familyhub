import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;
import '../core/utils/repository_mixin.dart';
import '../services/hive_service.dart';

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

class ContactsRepository with RepositoryErrorHandler {
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

  // ── Yerel (Hive) fallback — bulut yoksa/çevrimdışıysa kişiler kaybolmasın ──
  static const _localKey = 'local_contacts';

  List<FamilyContact> _readLocal() {
    final raw = HiveService.getSetting(_localKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FamilyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocal(List<FamilyContact> items) async {
    await HiveService.setSetting(
      _localKey,
      jsonEncode(items
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'phone': c.phone,
                'email': c.email,
                'type': c.type,
                'avatar_url': c.avatarUrl,
                'notes': c.notes,
                'created_by': c.createdBy,
                'created_at': c.createdAt.toIso8601String(),
              })
          .toList()),
    );
  }

  Future<List<FamilyContact>> getContacts(String familyId) async {
    // Bulut yoksa/oturum yoksa doğrudan yerel.
    if (_safeClient == null || _userId == null) return _readLocal();
    try {
      final response = await _safeClient!
          .from('family_contacts')
          .select('*')
          .eq('family_id', familyId)
          .order('name', ascending: true);
      final cloud = (response as List)
          .map((e) => FamilyContact.fromJson(e as Map<String, dynamic>))
          .toList();
      // Yalnızca yerelde olan (henüz buluta gitmemiş) kişileri birleştir.
      final locals = _readLocal().where((c) => c.id.startsWith('local_'));
      return [...cloud, ...locals];
    } catch (_) {
      return _readLocal();
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
      return Stream.error(
        RepositoryException('Beklenmeyen hata [watchContacts]: $e'),
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
    // Yerele yaz (offline/ailesiz kayıp olmasın) yardımcı.
    Future<FamilyContact> saveLocal() async {
      final contact = FamilyContact(
        id: 'local_${const Uuid().v4()}',
        name: name,
        phone: phone,
        email: email,
        type: type,
        notes: notes,
        createdBy: _userId,
        createdAt: DateTime.now(),
      );
      await _writeLocal([..._readLocal(), contact]);
      return contact;
    }

    if (_safeClient == null || _userId == null) return saveLocal();
    try {
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
    } catch (_) {
      // Bulut başarısızsa yerele düş.
      return saveLocal();
    }
  }

  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    // Yerel kişi → Hive'da güncelle.
    if (id.startsWith('local_')) {
      final all = _readLocal();
      final updated = all.map((c) {
        if (c.id != id) return c;
        return FamilyContact(
          id: c.id,
          name: (data['name'] as String?) ?? c.name,
          phone: data.containsKey('phone') ? data['phone'] as String? : c.phone,
          email: data.containsKey('email') ? data['email'] as String? : c.email,
          type: (data['type'] as String?) ?? c.type,
          avatarUrl: c.avatarUrl,
          notes: data.containsKey('notes') ? data['notes'] as String? : c.notes,
          createdBy: c.createdBy,
          createdAt: c.createdAt,
        );
      }).toList();
      await _writeLocal(updated);
      return;
    }
    return handleRepositoryCall(() async {
      _checkAuth();
      await _safeClient!.from('family_contacts').update(data).eq('id', id);
    }, 'updateContact');
  }

  Future<void> deleteContact(String id) async {
    // Yerel kişi → Hive'dan sil.
    if (id.startsWith('local_')) {
      await _writeLocal(_readLocal().where((c) => c.id != id).toList());
      return;
    }
    return handleRepositoryCall(() async {
      _checkAuth();
      await _safeClient!.from('family_contacts').delete().eq('id', id);
    }, 'deleteContact');
  }
}
