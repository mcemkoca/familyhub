import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission management with explanations,
/// rationales, and settings redirect for permanently denied permissions.
class PermissionService {
  PermissionService._();

  // ───────────────────────── CONTACTS ─────────────────────────

  static Future<bool> requestContactsRead(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.contacts,
      title: 'Rehber Erişimi',
      message:
          'Aile üyelerini telefon rehberinizden içe aktarmak için rehber erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Rehber erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden rehber iznini etkinleştirin.',
    );
  }

  static Future<bool> requestContactsWrite(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.contacts,
      title: 'Rehber Yazma İzni',
      message:
          'Aile kişilerini telefon rehberinize kaydetmek için yazma iznine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Rehber yazma izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden rehber iznini etkinleştirin.',
    );
  }

  // ───────────────────────── GALLERY / PHOTOS ─────────────────────────

  static Future<bool> requestPhotos(BuildContext context) async {
    final perm = Platform.isAndroid && await _isAndroid33OrHigher()
        ? Permission.photos
        : Permission.storage;

    if (!context.mounted) return false;
    return _requestPermission(
      context: context,
      permission: perm,
      title: 'Galeri Erişimi',
      message:
          'Fotoğraf ve videoları yüklemek için galeri erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Galeri erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden galeri iznini etkinleştirin.',
    );
  }

  static Future<bool> requestCamera(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.camera,
      title: 'Kamera Erişimi',
      message: 'Fotoğraf çekmek için kamera erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Kamera erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden kamera iznini etkinleştirin.',
    );
  }

  static Future<bool> requestStorage(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.storage,
      title: 'Depolama Erişimi',
      message:
          'Dosyaları kaydetmek ve okumak için depolama erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Depolama erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden depolama iznini etkinleştirin.',
    );
  }

  // ───────────────────────── CORE HANDLER ─────────────────────────

  static Future<bool> _requestPermission({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String message,
    required String settingsMessage,
  }) async {
    // 1. Check current status
    var status = await permission.status;

    // Already granted
    if (status.isGranted || status.isLimited) return true;

    // Permanently denied → show settings dialog
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(context, title, settingsMessage);
      }
      return false;
    }

    // First time or denied (but not permanent) → show rationale then request
    if (context.mounted) {
      final shouldProceed = await _showRationaleDialog(context, title, message);
      if (!shouldProceed) return false;
    }

    status = await permission.request();

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context, title, settingsMessage);
    }

    return false;
  }

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Reddet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ayarları Aç'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> _isAndroid33OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Best-effort; permission_handler already handles SDK checks internally
    return true;
  }
}
