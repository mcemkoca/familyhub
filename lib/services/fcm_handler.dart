import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/routes.dart';

/// FCM (Firebase Cloud Messaging) payload'larini parse edip
/// dogru ekrana yonlendiren handler.
///
/// Kullanim (main.dart'ta):
///   FirebaseMessaging.onMessageOpenedApp.listen(FcmHandler.onMessage);
///   FirebaseMessaging.onBackgroundMessage(FcmHandler.onBackgroundMessage);
class FcmHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
    final sender = data['sender_name'] as String? ?? 'Aile';
    final body = data['body'] as String?;

    return switch (type) {
      'chat_message' => FcmNotificationContent(
          title: '$sender mesaj gönderdi',
          body: body ?? 'Yeni mesajiniz var',
          iconEmoji: '\u{1F4AC}'),
      'location_alert' => FcmNotificationContent(
          title: 'Konum Uyarisi',
          body: body ?? '$sender güvenli bölgeden çikti',
          iconEmoji: '\u{1F4CD}'),
      'safe_zone' => FcmNotificationContent(
          title: 'Güvenli Bölge',
          body: body ?? '$sender güvenli bölgeye ulaşti',
          iconEmoji: '✅'),
      'sos_alert' => FcmNotificationContent(
          title: 'ACİL DURUM',
          body: body ?? '$sender acil yardim istiyor!',
          iconEmoji: '\u{1F198}'),
      'task_reminder' => FcmNotificationContent(
          title: 'Görev Hatirlatici',
          body: body ?? 'Bekleyen göreviniz var',
          iconEmoji: '✅'),
      'shopping_update' => FcmNotificationContent(
          title: 'Alisveris Listesi',
          body: body ?? 'Listeye yeni ürün eklendi',
          iconEmoji: '\u{1F6D2}'),
      'budget_alert' => FcmNotificationContent(
          title: 'Bütçe Uyarisi',
          body: body ?? 'Aylik bütçenizin %%90\'ina ulastiniz',
          iconEmoji: '\u{1F4B0}'),
      'education_tip' => FcmNotificationContent(
          title: 'Günün Aktivitesi',
          body: body ?? 'Çocugunuz için aktivite hazir',
          iconEmoji: '\u{1F393}'),
      'streak_reminder' => FcmNotificationContent(
          title: 'Seri Devam Ediyor!',
          body: body ?? 'Bugünkü görevinizi yapmayi unutmayin',
          iconEmoji: '\u{1F525}'),
      _ => FcmNotificationContent(
          title: 'FamilyHub',
          body: body ?? 'Yeni bildiriminiz var',
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
