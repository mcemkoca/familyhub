import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;

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
  });

  factory FamilyDocument.fromJson(Map<String, dynamic> json) => FamilyDocument(
    id: json['id']?.toString() ?? '',
    title: json['title'] ?? '',
    fileUrl: json['file_url'] ?? '',
    fileType: json['file_type'] ?? 'pdf',
    ocrText: json['ocr_text']?.toString(),
    extractedData: json['extracted_data'] as Map<String, dynamic>?,
    status: json['status'] ?? 'active',
    relatedTaskId: json['related_task_id']?.toString(),
    uploadedBy: json['uploaded_by']?.toString(),
    createdAt: DateTime.parse(
      json['created_at'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

class DocumentRepository {
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

  Future<List<FamilyDocument>> getDocuments(String familyId) async {
    try {
      _checkAuth();
      final response = await _safeClient!
          .from('family_documents')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => FamilyDocument.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('DocumentRepository.getDocuments error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
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
    } catch (e, st) {
      debugPrint('DocumentRepository.watchDocuments error: $e');
      return Stream.error(app_errors.AppDatabaseException('Veritabanı hatası: $e'));
    }
  }

  Future<FamilyDocument> uploadDocument({
    required String familyId,
    required File file,
    required String title,
    String fileType = 'pdf',
    String? ocrText,
    Map<String, dynamic>? extractedData,
  }) async {
    try {
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
          })
          .select()
          .single();

      return FamilyDocument.fromJson(response);
    } catch (e, st) {
      debugPrint('DocumentRepository.uploadDocument error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> updateDocument(String id, Map<String, dynamic> data) async {
    try {
      _checkAuth();
      await _safeClient!.from('family_documents').update(data).eq('id', id);
    } catch (e, st) {
      debugPrint('DocumentRepository.updateDocument error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteDocument(String id, String fileUrl) async {
    try {
      _checkAuth();
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.sublist(1).join('/');
        try {
          await _safeClient!.storage.from('family-documents').remove([fileName]);
        } catch (_) {}
      }
      await _safeClient!.from('family_documents').delete().eq('id', id);
    } catch (e, st) {
      debugPrint('DocumentRepository.deleteDocument error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }

  Future<void> linkTask(String documentId, String taskId) async {
    try {
      _checkAuth();
      await _safeClient!
          .from('family_documents')
          .update({'related_task_id': taskId})
          .eq('id', documentId);
    } catch (e, st) {
      debugPrint('DocumentRepository.linkTask error: $e');
      throw app_errors.AppDatabaseException('Veritabanı hatası: $e');
    }
  }
}
