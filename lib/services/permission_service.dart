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
    if (!context.mounted) return false;
    return _requestPermission(
      permission: Permission.photos,
      context: context,
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

  // ───────────────────────── MICROPHONE ─────────────────────────

  static Future<bool> requestMicrophone(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.microphone,
      title: 'Mikrofon Erişimi',
      message: 'Sesli mesaj göndermek ve acil durum kaydı için mikrofon erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Mikrofon erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden mikrofon iznini etkinleştirin.',
    );
  }

  // ───────────────────────── NOTIFICATIONS ─────────────────────────

  static Future<bool> requestNotifications(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.notification,
      title: 'Bildirim İzni',
      message: 'Aile bildirimleri, acil durumlar ve hatırlatıcılar için bildirim izni gereklidir.',
      settingsMessage:
          'Bildirim izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden bildirim iznini etkinleştirin.',
    );
  }

  // ───────────────────────── SENSORS ─────────────────────────

  static Future<bool> requestActivityRecognition(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.activityRecognition,
      title: 'Hareket Algılama',
      message: 'Sarsma hareketi ve acil durum algılama için sensör erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Hareket algılama izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden fiziksel aktivite iznini etkinleştirin.',
    );
  }

  // ───────────────────────── LOCATION ─────────────────────────

  static Future<bool> requestLocation(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.location,
      title: 'Konum Erişimi',
      message: 'Aile konumlarını paylaşmak ve güvenli bölgeleri izlemek için konum erişimine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Konum erişimi kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler menüsünden konum iznini etkinleştirin.',
    );
  }

  static Future<bool> requestLocationAlways(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.locationAlways,
      title: 'Arka Plan Konum',
      message: 'Aile üyelerinin konumunu sürekli takip etmek ve acil durumda konum paylaşımı için arka plan konum iznine ihtiyaç duyuyoruz.',
      settingsMessage:
          'Arka plan konum izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler > Konum > Her Zaman seçeneğini etkinleştirin.',
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
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1EFFFFFF), width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Color(0xFFE5E7EB))),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Reddet', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1EFFFFFF), width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: Color(0xFFE5E7EB))),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ayarları Aç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

}
