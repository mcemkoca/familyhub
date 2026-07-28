import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/routes.dart';
import 'localization/locale_service.dart';

/// FCM (Firebase Cloud Messaging) payload'larini parse edip
/// dogru ekrana yonlendiren handler.
///
/// Kullanim (main.dart'ta):
///   FirebaseMessaging.onMessageOpenedApp.listen(FcmHandler.onMessage);
///   FirebaseMessaging.onBackgroundMessage(FcmHandler.onBackgroundMessage);
class FcmHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  static String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

  static const _typeRoutes = <String, String>{
    'chat_message': AppRoutes.chat,
    'location_alert': AppRoutes.familyMap,
    'safe_zone': AppRoutes.familyMap,
    'shopping_update': AppRoutes.shopping,
    'budget_alert': AppRoutes.budget,
    'task_reminder': AppRoutes.tasks,
    'education_tip': AppRoutes.education,
    'kitchen_plan': AppRoutes.kitchen,
    'sos_alert': AppRoutes.emergency,
    'child_activity': AppRoutes.childManagement,
    'gallery_upload': AppRoutes.gallery,
    'streak_reminder': AppRoutes.streak,
  };

  static void navigate(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final route = routeFrom(data);
    context.push(route);
  }

  static String routeFrom(Map<String, dynamic> data) {
    final explicit = data['route'] as String?;
    if (explicit != null && explicit.startsWith('/')) return explicit;
    final type = data['type'] as String?;
    return _typeRoutes[type] ?? AppRoutes.hub;
  }

  static FcmNotificationContent contentFrom(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final sender = data['sender_name'] as String? ?? _text(const {
      'tr': 'Aile', 'en': 'Family', 'nl': 'Gezin', 'fr': 'Famille',
    });
    final body = data['body'] as String?;

    return switch (type) {
      'chat_message' => FcmNotificationContent(
          title: _text({'tr': '$sender mesaj gönderdi', 'en': '$sender sent a message', 'nl': '$sender heeft een bericht gestuurd', 'fr': '$sender a envoyé un message'}),
          body: body ?? _text(const {'tr': 'Yeni mesajınız var', 'en': 'You have a new message', 'nl': 'Je hebt een nieuw bericht', 'fr': 'Vous avez un nouveau message'}),
          iconEmoji: '\u{1F4AC}'),
      'location_alert' => FcmNotificationContent(
          title: _text(const {'tr': 'Konum Uyarısı', 'en': 'Location Alert', 'nl': 'Locatiemelding', 'fr': 'Alerte de localisation'}),
          body: body ?? _text({'tr': '$sender güvenli bölgeden çıktı', 'en': '$sender left the safe zone', 'nl': '$sender heeft de veilige zone verlaten', 'fr': '$sender a quitté la zone sécurisée'}),
          iconEmoji: '\u{1F4CD}'),
      'safe_zone' => FcmNotificationContent(
          title: _text(const {'tr': 'Güvenli Bölge', 'en': 'Safe Zone', 'nl': 'Veilige zone', 'fr': 'Zone sécurisée'}),
          body: body ?? _text({'tr': '$sender güvenli bölgeye ulaştı', 'en': '$sender arrived in the safe zone', 'nl': '$sender is in de veilige zone aangekomen', 'fr': '$sender est arrivé dans la zone sécurisée'}),
          iconEmoji: '✅'),
      'sos_alert' => FcmNotificationContent(
          title: _text(const {'tr': 'ACİL DURUM', 'en': 'EMERGENCY', 'nl': 'NOODGEVAL', 'fr': 'URGENCE'}),
          body: body ?? _text({'tr': '$sender acil yardım istiyor!', 'en': '$sender needs emergency help!', 'nl': '$sender heeft dringend hulp nodig!', 'fr': '$sender demande une aide urgente !'}),
          iconEmoji: '\u{1F198}'),
      'task_reminder' => FcmNotificationContent(
          title: _text(const {'tr': 'Görev Hatırlatıcı', 'en': 'Task Reminder', 'nl': 'Taakherinnering', 'fr': 'Rappel de tâche'}),
          body: body ?? _text(const {'tr': 'Bekleyen göreviniz var', 'en': 'You have a pending task', 'nl': 'Je hebt een openstaande taak', 'fr': 'Vous avez une tâche en attente'}),
          iconEmoji: '✅'),
      'shopping_update' => FcmNotificationContent(
          title: _text(const {'tr': 'Alışveriş Listesi', 'en': 'Shopping List', 'nl': 'Boodschappenlijst', 'fr': 'Liste de courses'}),
          body: body ?? _text(const {'tr': 'Listeye yeni ürün eklendi', 'en': 'A new item was added to the list', 'nl': 'Er is een nieuw artikel aan de lijst toegevoegd', 'fr': 'Un nouvel article a été ajouté à la liste'}),
          iconEmoji: '\u{1F6D2}'),
      'budget_alert' => FcmNotificationContent(
          title: _text(const {'tr': 'Bütçe Uyarısı', 'en': 'Budget Alert', 'nl': 'Budgetmelding', 'fr': 'Alerte budget'}),
          body: body ?? _text(const {'tr': 'Aylık bütçenizin %90’ına ulaştınız', 'en': 'You have reached 90% of your monthly budget', 'nl': 'Je hebt 90% van je maandbudget bereikt', 'fr': 'Vous avez atteint 90 % de votre budget mensuel'}),
          iconEmoji: '\u{1F4B0}'),
      'education_tip' => FcmNotificationContent(
          title: _text(const {'tr': 'Günün Aktivitesi', 'en': 'Activity of the Day', 'nl': 'Activiteit van de dag', 'fr': 'Activité du jour'}),
          body: body ?? _text(const {'tr': 'Çocuğunuz için bir aktivite hazır', 'en': 'An activity is ready for your child', 'nl': 'Er staat een activiteit klaar voor je kind', 'fr': 'Une activité est prête pour votre enfant'}),
          iconEmoji: '\u{1F393}'),
      'streak_reminder' => FcmNotificationContent(
          title: _text(const {'tr': 'Seri Devam Ediyor!', 'en': 'Your Streak Continues!', 'nl': 'Je reeks gaat door!', 'fr': 'Votre série continue !'}),
          body: body ?? _text(const {'tr': 'Bugünkü görevinizi yapmayı unutmayın', 'en': 'Do not forget today’s task', 'nl': 'Vergeet de taak van vandaag niet', 'fr': 'N’oubliez pas la tâche du jour'}),
          iconEmoji: '\u{1F525}'),
      _ => FcmNotificationContent(
          title: 'FamilyHub',
          body: body ?? _text(const {'tr': 'Yeni bildiriminiz var', 'en': 'You have a new notification', 'nl': 'Je hebt een nieuwe melding', 'fr': 'Vous avez une nouvelle notification'}),
          iconEmoji: '\u{1F3E0}'),
    };
  }
}

class FcmNotificationContent {
  final String title;
  final String body;
  final String iconEmoji;
  const FcmNotificationContent(
      {required this.title, required this.body, required this.iconEmoji});
}
