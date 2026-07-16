import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive permission management with explanations,
/// rationales, and settings redirect for permanently denied permissions.
class PermissionService {
  PermissionService._();

  static String _t(
    BuildContext context, {
    required String tr,
    required String en,
    required String nl,
    required String fr,
  }) => switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'nl' => nl,
        'fr' => fr,
        _ => tr,
      };

  // ───────────────────────── CONTACTS ─────────────────────────

  static Future<bool> requestContactsRead(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.contacts,
      title: _t(context, tr: 'Rehber Erişimi', en: 'Contacts Access', nl: 'Toegang tot contacten', fr: 'Accès aux contacts'),
      message: _t(context, tr: 'Aile üyelerini telefon rehberinizden içe aktarmak için rehber erişimine ihtiyaç duyuyoruz.', en: 'Contacts access is needed to import family members from your phone.', nl: 'Toegang tot contacten is nodig om gezinsleden uit je telefoon te importeren.', fr: 'L’accès aux contacts est nécessaire pour importer les membres de votre famille depuis votre téléphone.'),
      settingsMessage: _settingsMessage(context, 'contacts'),
    );
  }

  static Future<bool> requestContactsWrite(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.contacts,
      title: _t(context, tr: 'Rehber Yazma İzni', en: 'Save Contacts', nl: 'Contacten opslaan', fr: 'Enregistrer des contacts'),
      message: _t(context, tr: 'Aile kişilerini telefon rehberinize kaydetmek için yazma iznine ihtiyaç duyuyoruz.', en: 'Permission is needed to save family contacts to your phone.', nl: 'Toestemming is nodig om gezinscontacten op je telefoon op te slaan.', fr: 'Une autorisation est nécessaire pour enregistrer les contacts familiaux sur votre téléphone.'),
      settingsMessage: _settingsMessage(context, 'contacts'),
    );
  }

  // ───────────────────────── GALLERY / PHOTOS ─────────────────────────

  static Future<bool> requestPhotos(BuildContext context) async {
    if (!context.mounted) return false;
    return _requestPermission(
      permission: Permission.photos,
      context: context,
      title: _t(context, tr: 'Galeri Erişimi', en: 'Gallery Access', nl: 'Toegang tot galerij', fr: 'Accès à la galerie'),
      message: _t(context, tr: 'Fotoğraf ve videoları yüklemek için galeri erişimine ihtiyaç duyuyoruz.', en: 'Gallery access is needed to upload photos and videos.', nl: 'Toegang tot de galerij is nodig om foto’s en video’s te uploaden.', fr: 'L’accès à la galerie est nécessaire pour importer des photos et des vidéos.'),
      settingsMessage: _settingsMessage(context, 'gallery'),
    );
  }

  static Future<bool> requestCamera(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.camera,
      title: _t(context, tr: 'Kamera Erişimi', en: 'Camera Access', nl: 'Toegang tot camera', fr: 'Accès à la caméra'),
      message: _t(context, tr: 'Fotoğraf çekmek için kamera erişimine ihtiyaç duyuyoruz.', en: 'Camera access is needed to take photos.', nl: 'Toegang tot de camera is nodig om foto’s te maken.', fr: 'L’accès à la caméra est nécessaire pour prendre des photos.'),
      settingsMessage: _settingsMessage(context, 'camera'),
    );
  }

  static Future<bool> requestStorage(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.storage,
      title: _t(context, tr: 'Depolama Erişimi', en: 'Storage Access', nl: 'Toegang tot opslag', fr: 'Accès au stockage'),
      message: _t(context, tr: 'Dosyaları kaydetmek ve okumak için depolama erişimine ihtiyaç duyuyoruz.', en: 'Storage access is needed to save and read files.', nl: 'Toegang tot opslag is nodig om bestanden op te slaan en te lezen.', fr: 'L’accès au stockage est nécessaire pour enregistrer et lire des fichiers.'),
      settingsMessage: _settingsMessage(context, 'storage'),
    );
  }

  // ───────────────────────── MICROPHONE ─────────────────────────

  static Future<bool> requestMicrophone(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.microphone,
      title: _t(context, tr: 'Mikrofon Erişimi', en: 'Microphone Access', nl: 'Toegang tot microfoon', fr: 'Accès au microphone'),
      message: _t(context, tr: 'Sesli mesaj göndermek ve acil durum kaydı için mikrofon erişimine ihtiyaç duyuyoruz.', en: 'Microphone access is needed for voice messages and emergency recording.', nl: 'Toegang tot de microfoon is nodig voor spraakberichten en noodopnamen.', fr: 'L’accès au microphone est nécessaire pour les messages vocaux et les enregistrements d’urgence.'),
      settingsMessage: _settingsMessage(context, 'microphone'),
    );
  }

  // ───────────────────────── NOTIFICATIONS ─────────────────────────

  static Future<bool> requestNotifications(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.notification,
      title: _t(context, tr: 'Bildirim İzni', en: 'Notification Permission', nl: 'Meldingstoestemming', fr: 'Autorisation des notifications'),
      message: _t(context, tr: 'Aile bildirimleri, acil durumlar ve hatırlatıcılar için bildirim izni gereklidir.', en: 'Notification permission is required for family updates, emergencies, and reminders.', nl: 'Meldingstoestemming is nodig voor gezinsupdates, noodgevallen en herinneringen.', fr: 'L’autorisation des notifications est nécessaire pour les actualités familiales, les urgences et les rappels.'),
      settingsMessage: _settingsMessage(context, 'notifications'),
    );
  }

  // ───────────────────────── SENSORS ─────────────────────────

  static Future<bool> requestActivityRecognition(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.activityRecognition,
      title: _t(context, tr: 'Hareket Algılama', en: 'Motion Detection', nl: 'Bewegingsdetectie', fr: 'Détection de mouvement'),
      message: _t(context, tr: 'Sarsma hareketi ve acil durum algılama için sensör erişimine ihtiyaç duyuyoruz.', en: 'Sensor access is needed for shake gestures and emergency detection.', nl: 'Sensortoegang is nodig voor schudbewegingen en nooddetectie.', fr: 'L’accès aux capteurs est nécessaire pour les gestes de secousse et la détection d’urgence.'),
      settingsMessage: _settingsMessage(context, 'activity'),
    );
  }

  // ───────────────────────── LOCATION ─────────────────────────

  static Future<bool> requestLocation(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.location,
      title: _t(context, tr: 'Konum Erişimi', en: 'Location Access', nl: 'Toegang tot locatie', fr: 'Accès à la localisation'),
      message: _t(context, tr: 'Aile konumlarını paylaşmak ve güvenli bölgeleri izlemek için konum erişimine ihtiyaç duyuyoruz.', en: 'Location access is needed to share family locations and monitor safe zones.', nl: 'Locatietoegang is nodig om gezinslocaties te delen en veilige zones te bewaken.', fr: 'L’accès à la localisation est nécessaire pour partager les positions familiales et surveiller les zones sécurisées.'),
      settingsMessage: _settingsMessage(context, 'location'),
    );
  }

  static Future<bool> requestLocationAlways(BuildContext context) async {
    return _requestPermission(
      context: context,
      permission: Permission.locationAlways,
      title: _t(context, tr: 'Arka Plan Konumu', en: 'Background Location', nl: 'Locatie op de achtergrond', fr: 'Localisation en arrière-plan'),
      message: _t(context, tr: 'Aile üyelerinin konumunu sürekli takip etmek ve acil durumda konum paylaşımı için arka plan konum iznine ihtiyaç duyuyoruz.', en: 'Background location is needed for continuous family tracking and emergency location sharing.', nl: 'Locatie op de achtergrond is nodig voor continue gezinslocatie en het delen van locaties bij noodgevallen.', fr: 'La localisation en arrière-plan est nécessaire au suivi continu de la famille et au partage de position en cas d’urgence.'),
      settingsMessage: _settingsMessage(context, 'background_location'),
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

  static String _settingsMessage(BuildContext context, String permission) {
    final label = switch (permission) {
      'contacts' => _t(context, tr: 'rehber', en: 'contacts', nl: 'contacten', fr: 'contacts'),
      'gallery' => _t(context, tr: 'galeri', en: 'gallery', nl: 'galerij', fr: 'galerie'),
      'camera' => _t(context, tr: 'kamera', en: 'camera', nl: 'camera', fr: 'caméra'),
      'storage' => _t(context, tr: 'depolama', en: 'storage', nl: 'opslag', fr: 'stockage'),
      'microphone' => _t(context, tr: 'mikrofon', en: 'microphone', nl: 'microfoon', fr: 'microphone'),
      'notifications' => _t(context, tr: 'bildirim', en: 'notification', nl: 'meldingen', fr: 'notifications'),
      'activity' => _t(context, tr: 'fiziksel aktivite', en: 'physical activity', nl: 'fysieke activiteit', fr: 'activité physique'),
      'background_location' => _t(context, tr: 'arka plan konumu', en: 'background location', nl: 'locatie op de achtergrond', fr: 'localisation en arrière-plan'),
      _ => _t(context, tr: 'konum', en: 'location', nl: 'locatie', fr: 'localisation'),
    };
    return _t(
      context,
      tr: '$label izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler bölümünden etkinleştirin.',
      en: '$label permission was permanently denied. Enable it under Settings > Apps > FamilyHub > Permissions.',
      nl: 'Toestemming voor $label is permanent geweigerd. Schakel deze in via Instellingen > Apps > FamilyHub > Toestemmingen.',
      fr: 'L’autorisation de $label a été définitivement refusée. Activez-la dans Réglages > Applications > FamilyHub > Autorisations.',
    );
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
            child: Text(_t(context, tr: 'Reddet', en: 'Deny', nl: 'Weigeren', fr: 'Refuser'), style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_t(context, tr: 'İzin Ver', en: 'Allow', nl: 'Toestaan', fr: 'Autoriser')),
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
            child: Text(_t(context, tr: 'Kapat', en: 'Close', nl: 'Sluiten', fr: 'Fermer'), style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(_t(context, tr: 'Ayarları Aç', en: 'Open Settings', nl: 'Instellingen openen', fr: 'Ouvrir les réglages')),
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
