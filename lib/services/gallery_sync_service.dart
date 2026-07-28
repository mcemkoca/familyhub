import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../core/supabase_client.dart';
import '../repositories/gallery_repository.dart';
import 'hive_service.dart';
import 'localization/locale_service.dart';

/// Cihaz galerisini aile bulut galerisiyle (Supabase) senkronlar.
///
/// - İzin cihazdan istenir (photo_manager).
/// - Zaten yüklenen fotoğraflar `asset.id` ile takip edilip atlanır (dedup).
/// - Otomatik senkron açık/kapalı ayarı Hive'da saklanır ve ayarlardan
///   değiştirilebilir.
class GallerySyncService {
  static const String _autoSyncKey = 'gallery_auto_sync';
  static const String _syncedIdsKey = 'gallery_synced_asset_ids';

  // ── Otomatik senkron ayarı ──────────────────────────────────────────────
  static bool get autoSyncEnabled =>
      (HiveService.getSetting(_autoSyncKey) ?? 'false') == 'true';

  static Future<void> setAutoSync(bool value) =>
      HiveService.setSetting(_autoSyncKey, value ? 'true' : 'false');

  // ── İzin ─────────────────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }

  // ── Dedup takibi ───────────────────────────────────────────────────────
  static Set<String> _syncedIds() {
    final raw = HiveService.getSetting(_syncedIdsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _saveSyncedIds(Set<String> ids) async {
    // Aşırı büyümesini engelle — en son 2000 kaydı tut.
    final list = ids.toList();
    final trimmed =
        list.length > 2000 ? list.sublist(list.length - 2000) : list;
    await HiveService.setSetting(_syncedIdsKey, jsonEncode(trimmed));
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

  /// Cihazdaki en son fotoğrafları tarar, daha önce yüklenmemiş olanları
  /// aile galerisine (Supabase) yükler. Yüklenen adet döner.
  static Future<int> syncRecentPhotos({int limit = 30}) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      final lang = LocaleService.resolveInitialLocale().languageCode;
      throw Exception(const {
        'tr': 'Galeri izni gerekli',
        'en': 'Gallery permission is required',
        'nl': 'Toestemming voor de galerij is vereist',
        'fr': 'L’autorisation d’accès à la galerie est requise',
      }[lang] ?? 'Galeri izni gerekli');
    }

    final familyId = await _getFamilyId();
    if (familyId == null) {
      final lang = LocaleService.resolveInitialLocale().languageCode;
      throw Exception(const {'tr': 'Aile bulunamadı', 'en': 'Family not found', 'nl': 'Gezin niet gevonden', 'fr': 'Famille introuvable'}[lang] ?? 'Aile bulunamadı');
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return 0;

    final assets = await albums.first.getAssetListPaged(page: 0, size: limit);
    final synced = _syncedIds();
    final repo = GalleryRepository();
    var uploaded = 0;

    for (final asset in assets) {
      if (synced.contains(asset.id)) continue;
      try {
        final file = await asset.originFile ?? await asset.file;
        if (file == null) continue;
        await repo.uploadMedia(
          familyId: familyId,
          file: File(file.path),
          type: 'image',
        );
        synced.add(asset.id);
        uploaded++;
      } catch (e) {
        debugPrint('Galeri senkron hatası (${asset.id}): $e');
      }
    }

    await _saveSyncedIds(synced);
    return uploaded;
  }
}
