import 'dart:async';
import '../core/supabase_client.dart';
import 'child_auth_service.dart';
import 'localization/locale_service.dart';
import 'notification_service.dart';

/// Çocuk ↔ Ebeveyn arası cross-bildirim servisi
/// Realtime stream'leri dinleyerek yeni aktivitelerde local notification gösterir.
class ChildNotificationService {
  static final List<StreamSubscription<dynamic>> _subscriptions = [];
  static bool _initialized = false;

  static String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  static String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

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
    final childName = ChildAuthService.currentSession?.childName ?? _text(const {
      'tr': 'Çocuk', 'en': 'Child', 'nl': 'Kind', 'fr': 'Enfant',
    });
    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      if (_knownTaskIds.contains(id)) continue;
      _knownTaskIds.add(id);

      final status = item['status']?.toString() ?? '';
      if (status == 'completed') {
        // Çocuk tamamladı → ebeveyne bildirim
        NotificationService.showInstantNotification(
          title: _text({
            'tr': '🎉 $childName bir görev tamamladı!',
            'en': '🎉 $childName completed a task!',
            'nl': '🎉 $childName heeft een taak voltooid!',
            'fr': '🎉 $childName a terminé une tâche !',
          }),
          body: _text({
            'tr': '"${item['title']}" görevi tamamlandı.',
            'en': 'The task “${item['title']}” was completed.',
            'nl': 'De taak ‘${item['title']}’ is voltooid.',
            'fr': 'La tâche « ${item['title']} » est terminée.',
          }),
          payload: 'task:$id',
        );
      } else if (status == 'pending') {
        // Yeni görev atandı → çocuğa bildirim
        NotificationService.showInstantNotification(
          title: _text(const {
            'tr': '✅ Yeni görevin var!', 'en': '✅ You have a new task!',
            'nl': '✅ Je hebt een nieuwe taak!', 'fr': '✅ Tu as une nouvelle tâche !',
          }),
          body: _text({
            'tr': '"${item['title']}" görevi sana atandı.',
            'en': 'The task “${item['title']}” was assigned to you.',
            'nl': 'De taak ‘${item['title']}’ is aan jou toegewezen.',
            'fr': 'La tâche « ${item['title']} » t’a été attribuée.',
          }),
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

      final senderName = item['sender_name']?.toString() ?? _text(const {
        'tr': 'Birisi', 'en': 'Someone', 'nl': 'Iemand', 'fr': 'Quelqu’un',
      });
      NotificationService.showInstantNotification(
        title: _text({
          'tr': '💬 $senderName mesaj gönderdi',
          'en': '💬 $senderName sent a message',
          'nl': '💬 $senderName heeft een bericht gestuurd',
          'fr': '💬 $senderName a envoyé un message',
        }),
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
          title: _text(const {
            'tr': '📚 Yeni ödevin var!', 'en': '📚 You have new homework!',
            'nl': '📚 Je hebt nieuw huiswerk!', 'fr': '📚 Tu as un nouveau devoir !',
          }),
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
        title: _text(const {
          'tr': '📅 Ders programın güncellendi',
          'en': '📅 Your class schedule was updated',
          'nl': '📅 Je lesrooster is bijgewerkt',
          'fr': '📅 Ton emploi du temps a été mis à jour',
        }),
        body: _text({
          'tr': '${item['subject']} eklendi: ${item['start_time']}-${item['end_time']}',
          'en': '${item['subject']} was added: ${item['start_time']}–${item['end_time']}',
          'nl': '${item['subject']} is toegevoegd: ${item['start_time']}–${item['end_time']}',
          'fr': '${item['subject']} a été ajouté : ${item['start_time']}–${item['end_time']}',
        }),
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
      final typeNames = <String, Map<String, String>>{
        'height': {'tr': 'Boy', 'en': 'Height', 'nl': 'Lengte', 'fr': 'Taille'},
        'weight': {'tr': 'Kilo', 'en': 'Weight', 'nl': 'Gewicht', 'fr': 'Poids'},
        'mood': {'tr': 'Ruh hali', 'en': 'Mood', 'nl': 'Stemming', 'fr': 'Humeur'},
        'milestone': {'tr': 'Kazanım', 'en': 'Milestone', 'nl': 'Mijlpaal', 'fr': 'Étape importante'},
        'note': {'tr': 'Not', 'en': 'Note', 'nl': 'Notitie', 'fr': 'Note'},
      };
      NotificationService.showInstantNotification(
        title: _text(const {
          'tr': '📈 Yeni gelişim kaydı', 'en': '📈 New development record',
          'nl': '📈 Nieuwe ontwikkelingsregistratie', 'fr': '📈 Nouveau suivi du développement',
        }),
        body:
            '${typeNames[logType] == null ? logType : _text(typeNames[logType]!)}: ${item['value']} ${item['unit'] ?? ''}',
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
