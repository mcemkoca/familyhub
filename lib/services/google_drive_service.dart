import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:hive/hive.dart';
import '../domain/models/drive_backup_model.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();
  Future<void> signOut() => _googleSignIn.signOut();
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;
    return drive.DriveApi(authClient);
  }

  Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    const folderName = 'FamilyHub Backups';
    final existing = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false",
      spaces: 'drive',
    );
    if (existing.files?.isNotEmpty == true) return existing.files!.first.id!;
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }

  Future<Map<String, dynamic>> _collectHiveData() async {
    final data = <String, dynamic>{};
    final boxes = [
      'tasksBox',
      'transactionsBox',
      'chatBox',
      'streaksBox',
      'settingsBox',
    ];
    for (final boxName in boxes) {
      try {
        final box = await Hive.openBox<dynamic>(boxName);
        final map = <String, dynamic>{};
        for (final key in box.keys) {
          map[key.toString()] = box.get(key);
        }
        data[boxName] = map;
        await box.close();
      } catch (e) {
        data[boxName] = <String, dynamic>{};
      }
    }
    data['backupTimestamp'] = DateTime.now().toIso8601String();
    data['appVersion'] = '1.0.0';
    return data;
  }

  Future<DriveBackup> uploadBackup() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Google Drive not authenticated');
    final folderId = await _getOrCreateFolder(api);
    final data = await _collectHiveData();
    final bytes = utf8.encode(jsonEncode(data));
    final file = drive.File()
      ..name = 'familyhub_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json'
      ..parents = [folderId];
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);
    final created = await api.files.create(file, uploadMedia: media);
    return DriveBackup(
      fileId: created.id!,
      name: created.name ?? '',
      createdTime: DateTime.now(),
      sizeBytes: bytes.length,
    );
  }

  Future<void> restoreBackup(String fileId) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Google Drive not authenticated');
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = await media.stream.expand((b) => b).toList();
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    final boxes = {
      'tasksBox': data['tasksBox'],
      'transactionsBox': data['transactionsBox'],
      'chatBox': data['chatBox'],
      'streaksBox': data['streaksBox'],
      'settingsBox': data['settingsBox'],
    };

    for (final entry in boxes.entries) {
      if (entry.value == null) continue;
      try {
        final box = await Hive.openBox<dynamic>(entry.key);
        await box.clear();
        final map = Map<String, dynamic>.from(entry.value as Map);
        for (final kv in map.entries) {
          await box.put(kv.key, kv.value);
        }
        await box.close();
      } catch (e) {
        // Continue restoring other boxes
      }
    }
  }

  Future<List<DriveBackup>> listBackups() async {
    final api = await _getDriveApi();
    if (api == null) return [];
    final folderId = await _getOrCreateFolder(api);
    final result = await api.files.list(
      q: "'$folderId' in parents and mimeType='application/json' and trashed=false",
      spaces: 'drive',
      orderBy: 'createdTime desc',
    );
    return (result.files ?? []).map((f) {
      return DriveBackup(
        fileId: f.id ?? '',
        name: f.name ?? '',
        createdTime: f.createdTime ?? DateTime.now(),
        sizeBytes: int.tryParse(f.size ?? ''),
      );
    }).toList();
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Google Drive not authenticated');
    await api.files.delete(fileId);
  }
}
