import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_logger.dart';
import 'auth_service.dart';

/// Aile sohbeti için typing + presence (online) durumu.
///
/// Supabase Realtime **broadcast** (typing) ve **presence** (online) kullanır.
/// Bu veriler DB'ye KALICI yazılmaz (ephemeral) — spec §18 gereği typing
/// database'e yazılmamalı. Kanal `chat-presence:{familyId}` ile aileye izole.
class ChatPresenceService {
  ChatPresenceService(this.familyId);
  final String familyId;

  RealtimeChannel? _channel;
  Timer? _typingStopTimer;

  final _typingCtrl = StreamController<List<TypingUser>>.broadcast();
  final _onlineCtrl = StreamController<Set<String>>.broadcast();

  /// "X yazıyor" için aktif kullanıcılar (kendisi hariç).
  Stream<List<TypingUser>> get typingUsers => _typingCtrl.stream;

  /// Online kullanıcı ID kümesi.
  Stream<Set<String>> get onlineUsers => _onlineCtrl.stream;

  final Map<String, TypingUser> _typing = {};
  final Map<String, Timer> _typingExpiry = {};

  String? get _myId => AuthService.currentUserId;

  void connect(String displayName) {
    final client = AuthService.safeClient;
    if (client == null) return;
    try {
      final channel = client.channel('chat-presence:$familyId',
          opts: const RealtimeChannelConfig(self: false));

      channel.onBroadcast(
        event: 'typing',
        callback: (payload) => _onTyping(payload),
      );

      channel.onPresenceSync((_) {
        final states = channel.presenceState();
        final ids = <String>{};
        for (final s in states) {
          for (final p in s.presences) {
            final id = p.payload['user_id'] as String?;
            if (id != null) ids.add(id);
          }
        }
        if (!_onlineCtrl.isClosed) _onlineCtrl.add(ids);
      });

      channel.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          final myId = _myId;
          if (myId != null) {
            await channel.track({'user_id': myId, 'display_name': displayName});
          }
        } else if (error != null) {
          AppLogger.logBestEffort(error,
              module: 'chat', operation: 'presenceSubscribe');
        }
      });
      _channel = channel;
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'presenceConnect', stackTrace: st);
    }
  }

  /// Kullanıcı yazmaya başladığında çağrılır (composer onChanged).
  /// Debounce: 3 sn içinde tekrar yazılmazsa "durdu" yayınlanır.
  void notifyTyping(String displayName) {
    final ch = _channel;
    final myId = _myId;
    if (ch == null || myId == null) return;
    ch.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': myId, 'display_name': displayName, 'typing': true},
    );
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 3), () {
      ch.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': myId, 'display_name': displayName, 'typing': false},
      );
    });
  }

  void _onTyping(Map<String, dynamic> payload) {
    final id = payload['user_id'] as String?;
    if (id == null || id == _myId) return; // kendi typing'imi gösterme
    final name = payload['display_name'] as String? ?? '';
    final isTyping = payload['typing'] as bool? ?? false;

    _typingExpiry[id]?.cancel();
    if (isTyping) {
      _typing[id] = TypingUser(userId: id, displayName: name);
      // Güvenlik ağı: "durdu" event'i kaybolursa 5 sn sonra otomatik temizle.
      _typingExpiry[id] = Timer(const Duration(seconds: 5), () {
        _typing.remove(id);
        _emitTyping();
      });
    } else {
      _typing.remove(id);
    }
    _emitTyping();
  }

  void _emitTyping() {
    if (!_typingCtrl.isClosed) _typingCtrl.add(_typing.values.toList());
  }

  Future<void> dispose() async {
    _typingStopTimer?.cancel();
    for (final t in _typingExpiry.values) {
      t.cancel();
    }
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await ch.unsubscribe();
      } catch (_) {}
    }
    await _typingCtrl.close();
    await _onlineCtrl.close();
  }
}

class TypingUser {
  final String userId;
  final String displayName;
  const TypingUser({required this.userId, required this.displayName});
}
