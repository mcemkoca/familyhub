
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/supabase_client.dart';

/// Gallery photo sync with Firebase Storage.
class GallerySyncService {
  static Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth;
  }

  /// Pick recent photos and upload to Firebase Storage.
  static Future<List<String>> uploadRecentPhotos({int limit = 10}) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) throw Exception('Galeri izni gerekli');

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final assets = await recentAlbum.getAssetListPaged(page: 0, size: limit);

    final urls = <String>[];
    final familyId = await _getFamilyId();
    if (familyId == null) throw Exception('Aile ID bulunamadı');

    for (final asset in assets) {
      final file = await asset.originFile;
      if (file == null) continue;

      final ref = FirebaseStorage.instance
          .ref()
          .child('families/$familyId/gallery/${asset.id}.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  static Future<String?> _getFamilyId() async {
    final userId = SupabaseConfig.safeClient?.auth.currentUser?.id;
    if (userId == null) return null;
    final result = await SupabaseConfig.safeClient!
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return result?['family_id'] as String?;
  }
}
