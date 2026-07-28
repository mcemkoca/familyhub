import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import 'auth_service.dart';

/// Sohbet medyasını private `chat-media` bucket'ına yükler.
///
/// Path şeması: `chat/{familyId}/{messageId veya uuid}/{dosya}`.
/// Böylece storage RLS aile üyeliğini path'in 2. segmentinden doğrular ve
/// başka aile tahmin edilebilir URL ile dosyaya erişemez (bkz. migration 067).
///
/// picked.path (yalnızca gönderen cihazda geçerli yerel yol) YERİNE bu servis
/// kullanılır; dönen imzalı URL diğer cihazlarda açılır.
class ChatStorageService {
  static const _bucket = 'chat-media';

  /// Yerel [file]'ı yükler ve 1 haftalık imzalı URL döner.
  /// Hata durumunda [ChatUploadException] fırlatır (sessiz yutma yok).
  static Future<String> uploadMedia({
    required String familyId,
    required File file,
    required String kind, // image | audio | video | file
  }) async {
    final client = AuthService.safeClient;
    if (client == null) {
      throw const ChatUploadException('Sunucu bağlantısı kurulmadı');
    }
    try {
      final ext = p.extension(file.path);
      final ts = DateTime.now().microsecondsSinceEpoch;
      final objectPath = 'chat/$familyId/$kind/$ts$ext';
      await client.storage.from(_bucket).upload(objectPath, file);
      // Private bucket → imzalı URL (7 gün). UI cache eder, süre dolunca yeniler.
      return await client.storage
          .from(_bucket)
          .createSignedUrl(objectPath, 60 * 60 * 24 * 7);
    } on StorageException catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'uploadMedia', stackTrace: st);
      throw ChatUploadException(e.message);
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'uploadMedia', stackTrace: st);
      throw const ChatUploadException('Dosya yüklenemedi');
    }
  }
}

class ChatUploadException implements Exception {
  final String message;
  const ChatUploadException(this.message);
  @override
  String toString() => message;
}
