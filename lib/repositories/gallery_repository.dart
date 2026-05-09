import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart' as app_errors;
import '../core/utils/repository_mixin.dart';

class FamilyMedia {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String type;
  final String? caption;
  final String? uploadedBy;
  final DateTime createdAt;

  FamilyMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.type = 'image',
    this.caption,
    this.uploadedBy,
    required this.createdAt,
  });

  factory FamilyMedia.fromJson(Map<String, dynamic> json) => FamilyMedia(
    id: json['id']?.toString() ?? '',
    url: (json['url'] as String?) ?? '',
    thumbnailUrl: json['thumbnail_url']?.toString(),
    type: (json['type'] as String?) ?? 'image',
    caption: json['caption']?.toString(),
    uploadedBy: json['uploaded_by']?.toString(),
    createdAt: DateTime.parse(
      (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    ),
  );
}

class GalleryRepository with RepositoryErrorHandler {
  static final GalleryRepository _instance = GalleryRepository._internal();
  factory GalleryRepository() => _instance;
  GalleryRepository._internal();
  SupabaseClient? get _safeClient => SupabaseConfig.safeClient;
  String? get _userId => _safeClient?.auth.currentUser?.id;

  void _checkAuth() {
    if (_userId == null) {
      throw app_errors.AppAuthException('Giriş yapmalısınız');
    }
  }

  Future<List<FamilyMedia>> getMedia(String familyId) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      final response = await _safeClient!
          .from('family_media')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => FamilyMedia.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getMedia');
  }

  Stream<List<FamilyMedia>> watchMedia(String familyId) {
    try {
      return _safeClient!
          .from('family_media')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map(
            (data) => data
                .where((e) => e['family_id'] == familyId)
                .map((e) => FamilyMedia.fromJson(e))
                .toList(),
          );
    } catch (e) {
      return Stream.error(
        RepositoryException('Beklenmeyen hata [watchMedia]: $e'),
      );
    }
  }

  Future<FamilyMedia> uploadMedia({
    required String familyId,
    required File file,
    required String type,
    String? caption,
  }) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_userId}_${file.path.split('/').last}';
      final bucket = _safeClient!.storage.from('family-gallery');
      await bucket.upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = bucket.getPublicUrl(fileName);

      final response = await _safeClient!
          .from('family_media')
          .insert({
            'family_id': familyId,
            'url': url,
            'type': type,
            'caption': caption,
            'uploaded_by': _userId,
          })
          .select()
          .single();

      return FamilyMedia.fromJson(response);
    }, 'uploadMedia');
  }

  Future<void> deleteMedia(String id, String fileUrl) async {
    return handleRepositoryCall(() async {
      _checkAuth();
      // Extract filename from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final fileName = pathSegments.sublist(1).join('/');
        try {
          await _safeClient!.storage.from('family-gallery').remove([fileName]);
        } catch (_) {
          // Ignore storage delete errors
        }
      }
      await _safeClient!.from('family_media').delete().eq('id', id);
    }, 'deleteMedia');
  }
}
