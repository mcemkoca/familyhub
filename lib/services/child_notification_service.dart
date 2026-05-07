import 'dart:async';
import '../core/supabase_client.dart';
import 'child_auth_service.dart';
import 'notification_service.dart';

/// Çocuk ↔ Ebeveyn arası cross-bildirim servisi
/// Realtime stream'leri dinleyerek yeni aktivitelerde local notification gösterir.
class ChildNotificationService {
  static final List<StreamSubscription> _subscriptions = [];
  static bool _initialized = false;

  /// Bildirim servisini başlat (çocuk login olduktan sonra çağrılır)
  static Future<void> initialize() async {
    if (_initialized) return;
    await NotificationService.init();
    await NotificationService.requestPermission();
    _startListening();
    _initialized = true;
  }

  static void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }

  static void _startListening() {
    final familyId = ChildAuthService.currentFamilyId;
    final childId = ChildAuthService.currentChildId;
    if (familyId == null || childId == null) return;

    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    // ── 1. Yeni görev atandığında bildirim ──
    _subscriptions.add(
      client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((e) => e['family_id'] == familyId && e['assigned_to'] == childId).toList())
          .listen((data) {
            _handleNewTasks(data);
          }),
    );

    // ── 2. Yeni mesaj geldiğinde bildirim ──
    _subscriptions.add(
      client
          .from('messages')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((e) => e['family_id'] == familyId).toList())
          .listen((data) {
            _handleNewMessages(data);
          }),
    );

    // ── 3. Yeni ödev eklendiğinde bildirim ──
    _subscriptions.add(
      client
          .from('child_homeworks')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((e) => e['child_id'] == childId).toList())
          .listen((data) {
            _handleNewHomeworks(data);
          }),
    );

    // ── 4. Yeni ders eklendiğinde bildirim ──
    _subscriptions.add(
      client
          .from('child_schedules')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((e) => e['child_id'] == childId).toList())
          .listen((data) {
            _handleNewSchedules(data);
          }),
    );

    // ── 5. Yeni gelişim kaydı eklendiğinde bildirim ──
    _subscriptions.add(
      client
          .from('child_development_logs')
          .stream(primaryKey: ['id'])
          .map((data) => data.where((e) => e['child_id'] == childId).toList())
          .listen((data) {
            _handleNewDevLogs(data);
          }),
    );
  }

  // Son bilinen kayıtları takip etmek için (aynı kaydı tekrar bildirme)
  static final Set<String> _knownTaskIds = {};
  static final Set<String> _knownMessageIds = {};
  static final Set<String> _knownHomeworkIds = {};
  static final Set<String> _knownScheduleIds = {};
  static final Set<String> _knownDevLogIds = {};

  static void _handleNewTasks(List<Map<String, dynamic>> data) {
    final childName = ChildAuthService.currentSession?.childName ?? 'Çocuk';
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownTaskIds.contains(id)) continue;
      _knownTaskIds.add(id);

      final status = item['status']?.toString() ?? '';
      if (status == 'completed') {
        // Çocuk tamamladı → ebeveyne bildirim
        NotificationService.showInstantNotification(
          title: '🎉 $childName bir görev tamamladı!',
          body: '"${item['title']}" görevi tamamlandı.',
          payload: 'task:$id',
        );
      } else if (status == 'pending') {
        // Yeni görev atandı → çocuğa bildirim
        NotificationService.showInstantNotification(
          title: '✅ Yeni görevin var!',
          body: '"${item['title']}" görevi sana atandı.',
          payload: 'task:$id',
        );
      }
    }
  }

  static void _handleNewMessages(List<Map<String, dynamic>> data) {
    final childId = ChildAuthService.currentChildId;
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownMessageIds.contains(id)) continue;
      _knownMessageIds.add(id);

      final senderId = item['user_id']?.toString() ?? '';
      // Kendi mesajımı bildirme
      if (senderId == childId) continue;

      final senderName = item['sender_name']?.toString() ?? 'Birisi';
      NotificationService.showInstantNotification(
        title: '💬 $senderName mesaj gönderdi',
        body: item['content']?.toString() ?? '',
        payload: 'chat:$id',
      );
    }
  }

  static void _handleNewHomeworks(List<Map<String, dynamic>> data) {
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownHomeworkIds.contains(id)) continue;
      _knownHomeworkIds.add(id);

      final status = item['status']?.toString() ?? '';
      if (status == 'pending') {
        NotificationService.showInstantNotification(
          title: '📚 Yeni ödevin var!',
          body: '${item['subject']}: ${item['title']}',
          payload: 'homework:$id',
        );
      }
    }
  }

  static void _handleNewSchedules(List<Map<String, dynamic>> data) {
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownScheduleIds.contains(id)) continue;
      _knownScheduleIds.add(id);

      NotificationService.showInstantNotification(
        title: '📅 Ders programın güncellendi',
        body:
            '${item['subject']} eklendi: ${item['start_time']}-${item['end_time']}',
        payload: 'schedule:$id',
      );
    }
  }

  static void _handleNewDevLogs(List<Map<String, dynamic>> data) {
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownDevLogIds.contains(id)) continue;
      _knownDevLogIds.add(id);

      final logType = item['log_type']?.toString() ?? '';
      final typeNames = {
        'height': 'Boy',
        'weight': 'Kilo',
        'mood': 'Ruh hali',
        'milestone': 'Kazanım',
        'note': 'Not',
      };
      NotificationService.showInstantNotification(
        title: '📈 Yeni gelişim kaydı',
        body:
            '${typeNames[logType] ?? logType}: ${item['value']} ${item['unit'] ?? ''}',
        payload: 'devlog:$id',
      );
    }
  }

  /// Manuel bildirim gönder (ebeveyn tarafı için)
  static Future<void> notifyParent({
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationService.showInstantNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Çocuğa özel bildirim gönder
  static Future<void> notifyChild({
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationService.showInstantNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
}
