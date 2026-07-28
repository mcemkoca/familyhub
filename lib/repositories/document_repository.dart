import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;
import '../core/utils/repository_mixin.dart';
import '../services/hive_service.dart';
import '../core/settings_store.dart';

/// Document categories matching Belgium family needs.
enum DocumentCategory {
  identity,
  health,
  insurance,
  school,
  residence,
  vehicle,
  tax,
  mutualite,
  other,
}

extension DocumentCategoryExt on DocumentCategory {
  String get label => switch (this) {
    DocumentCategory.identity  => 'Kimlik / Pasaport',
    DocumentCategory.health    => 'Sağlık',
    DocumentCategory.insurance => 'Sigorta',
    DocumentCategory.school    => 'Okul',
    DocumentCategory.residence => 'İkamet',
    DocumentCategory.vehicle   => 'Araç',
    DocumentCategory.tax       => 'Vergi',
    DocumentCategory.mutualite => 'Mutualité',
    DocumentCategory.other     => 'Diğer',
  };

  String get dbValue => name;

  static DocumentCategory fromString(String? v) => switch (v) {
    'identity'  => DocumentCategory.identity,
    'health'    => DocumentCategory.health,
    'insurance' => DocumentCategory.insurance,
    'school'    => DocumentCategory.school,
    'residence' => DocumentCategory.residence,
    'vehicle'   => DocumentCategory.vehicle,
    'tax'       => DocumentCategory.tax,
    'mutualite' => DocumentCategory.mutualite,
    _           => DocumentCategory.other,
  };
}

class FamilyDocument {
  final String id;
  final String title;
  final String fileUrl;
  final String fileType;
  final String? ocrText;
  final Map<String, dynamic>? extractedData;
  final String status;
  final String? relatedTaskId;
  final String? uploadedBy;
  final DateTime createdAt;
  final DocumentCategory category;
  final DateTime? expiryDate;

  FamilyDocument({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.fileType = 'pdf',
    this.ocrText,
    this.extractedData,
    this.status = 'active',
    this.relatedTaskId,
    this.uploadedBy,
    required this.createdAt,
    this.category = DocumentCategory.other,
    this.expiryDate,
  });

  factory FamilyDocument.fromJson(Map<String, dynamic> json) => FamilyDocument(
    id: json['id']?.toString() ?? '',
    title: (json['title'] as String?) ?? '',
    fileUrl: (json['file_url'] as String?) ?? '',
    fileType: (json['file_type'] as String?) ?? 'pdf',
    ocrText: json['ocr_text']?.toString(),
    extractedData: json['extracted_data'] as Map<String, dynamic>?,
    status: (json['status'] as String?) ?? 'active',
    relatedTaskId: json['related_task_id']?.toString(),
    uploadedBy: json['uploaded_by']?.toString(),
    createdAt: DateTime.parse(
      (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    ),
    category: DocumentCategoryExt.fromString(json['category'] as String?),
    expiryDate: json['expiry_date'] != null
        ? DateTime.tryParse(json['expiry_date'] as String)
        : null,
  );

  /// Days until expiry. Negative = already expired.
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon {
    final d = daysUntilExpiry;
    return d != null && d >= 0 && d <= 30;
  }

  bool get isExpired {
    final d = daysUntilExpiry;
    return d != null && d < 0;
  }
}

class DocumentRepository with RepositoryErrorHandler {
  static final DocumentRepository _instance = DocumentRepository._internal();
  factory DocumentRepository() => _instance;
  DocumentRepository._internal();
  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  String? get _userId => _safeClient?.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw app_errors.AppAuthException('Giriş yapmalısınız');
    }
  }

  /// Gerçek aile yoksa kullanılan yerel evrak kasası (Hive'da dosya yolları).
  static const String localFamilyId = 'local_family';

  List<Map<String, dynamic>> _localRaw() {
    final raw = HiveService.getSetting(SettingsStore.scopedKey('documents_local'));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  List<FamilyDocument> getLocalDocuments() =>
      _localRaw().map((e) => FamilyDocument.fromJson(e)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<FamilyDocument> addLocalDocument({
    required File file,
    required String title,
    String fileType = 'pdf',
    DocumentCategory category = DocumentCategory.other,
    DateTime? expiryDate,
  }) async {
    final map = {
      'id': 'local_${const Uuid().v4()}',
      'title': title,
      'file_url': file.path,
      'file_type': fileType,
      'uploaded_by': _userId,
      'category': category.dbValue,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    final all = _localRaw()..insert(0, map);
    await HiveService.setSetting(
        SettingsStore.scopedKey('documents_local'), jsonEncode(all));
    return FamilyDocument.fromJson(map);
  }

  Future<void> deleteLocalDocument(String id) async {
    final all = _localRaw()..removeWhere((e) => e['id'] == id);
    await HiveService.setSetting(
        SettingsStore.scopedKey('documents_local'), jsonEncode(all));
  }

  Future<List<FamilyDocument>> getDocuments(String familyId) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      final response = await _safeClient!
          .from('family_documents')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getDocuments');
  }

  Stream<List<FamilyDocument>> watchDocuments(String familyId) {
    try {
      return _safeClient!
          .from('family_documents')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => FamilyDocument.fromJson(e))
                .toList(),
          );
    } catch (e) {
      return Stream.error(
        RepositoryException('Beklenmeyen hata [watchDocuments]: $e'),
      );
    }
  }

  Future<FamilyDocument> uploadDocument({
    required String familyId,
    required File file,
    required String title,
    String fileType = 'pdf',
    String? ocrText,
    Map<String, dynamic>? extractedData,
    DocumentCategory category = DocumentCategory.other,
    DateTime? expiryDate,
  }) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      final ext = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_userId.$ext';
      final bucket = _safeClient!.storage.from('family-documents');
      await bucket.upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = bucket.getPublicUrl(fileName);

      final response = await _safeClient!
          .from('family_documents')
          .insert({
            'family_id': familyId,
            'title': title,
            'file_url': url,
            'file_type': fileType,
            'ocr_text': ocrText,
            'extracted_data': extractedData,
            'uploaded_by': _userId,
            'category': category.dbValue,
            'expiry_date': expiryDate?.toIso8601String(),
          })
          .select()
          .single();

      return FamilyDocument.fromJson(response);
    }, 'uploadDocument');
  }

  Future<void> updateDocument(String id, Map<String, dynamic> data) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      await _safeClient!.from('family_documents').update(data).eq('id', id);
    }, 'updateDocument');
  }

  Future<void> deleteDocument(String id, String fileUrl) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.sublist(1).join('/');
        try {
          await _safeClient!.storage.from('family-documents').remove([
            fileName,
          ]);
        } catch (e) { debugPrint('Document repository error: $e'); }
      }
      await _safeClient!.from('family_documents').delete().eq('id', id);
    }, 'deleteDocument');
  }

  Future<void> linkTask(String documentId, String taskId) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      await _safeClient!
          .from('family_documents')
          .update({'related_task_id': taskId})
          .eq('id', documentId);
    }, 'linkTask');
  }
}
