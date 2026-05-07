import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import 'notification_service.dart';

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show local notification when app is in background/terminated
  await NotificationService.showInstantNotification(
    title: message.notification?.title ?? 'FamilyHub',
    body: message.notification?.body ?? '',
    payload: message.data['route'],
  );
}

/// Firebase Cloud Messaging service for push notifications.
class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static String? _token;

  static String? get token => _token;

  /// Initialize FCM, request permissions, and sync token to Supabase.
  static Future<void> initialize() async {
    // Register background handler before any other FCM calls
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _token = await _messaging.getToken();
    await _syncTokenToSupabase();

    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _syncTokenToSupabase();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundTap(initialMessage);
    }
  }

  static Future<void> _syncTokenToSupabase() async {
    final userId = SupabaseConfig.safeClient?.auth.currentUser?.id;
    if (userId == null || _token == null) return;
    await SupabaseConfig.safeClient!.from('profiles').update({
      'fcm_token': _token,
      'fcm_token_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    NotificationService.showInstantNotification(
      title: notification.title ?? 'FamilyHub',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }

  static void _handleBackgroundTap(RemoteMessage message) {
    final payload = message.data['route'] as String?;
    if (payload != null) {
      NotificationService.setOnTapCallback((_) {});
    }
  }

  /// Subscribe to a topic (e.g., family-wide broadcasts).
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
