import 'dart:convert';
import 'package:familyhub/services/hive_service.dart' show HiveService;
import 'package:familyhub/repositories/chat_repository.dart' show ChatRepository;
import 'package:familyhub/domain/entities.dart' show MessageType;
import 'package:familyhub/core/app_logger.dart' show AppLogger;

/// Offline giden-kutusu (pending mesaj kuyruğu) — saf, test edilebilir çekirdek.
///
/// Ağ yokken gönderilen mesajlar kaybolmamalı (spec FAZ 6). Bu sınıf kalıcılık
/// (Hive) ve backoff mantığını yönetir; ChatOutboxService bunu Hive'a bağlar.
///
/// Idempotency: her mesaj benzersiz [clientMessageId] taşır. Retry aynı ID ile
/// yapılır; backend'deki `uq_messages_client_id` unique index duplicate'i önler.

enum OutboxState { pending, sending, sent, failed }

class OutboxMessage {
  final String clientMessageId;
  final String ownerId; // kullanıcı izolasyonu: kimin kuyruğu
  final String familyId;
  final String content;
  final String type;
  final String? replyToId;
  final int retryCount;
  final int createdAtMs;
  final int nextRetryAtMs;
  final OutboxState state;
  final String? lastError;

  const OutboxMessage({
    required this.clientMessageId,
    required this.ownerId,
    required this.familyId,
    required this.content,
    this.type = 'text',
    this.replyToId,
    this.retryCount = 0,
    required this.createdAtMs,
    this.nextRetryAtMs = 0,
    this.state = OutboxState.pending,
    this.lastError,
  });

  OutboxMessage copyWith({
    int? retryCount,
    int? nextRetryAtMs,
    OutboxState? state,
    String? lastError,
  }) {
    return OutboxMessage(
      clientMessageId: clientMessageId,
      ownerId: ownerId,
      familyId: familyId,
      content: content,
      type: type,
      replyToId: replyToId,
      retryCount: retryCount ?? this.retryCount,
      createdAtMs: createdAtMs,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
      state: state ?? this.state,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientMessageId': clientMessageId,
        'ownerId': ownerId,
        'familyId': familyId,
        'content': content,
        'type': type,
        'replyToId': replyToId,
        'retryCount': retryCount,
        'createdAtMs': createdAtMs,
        'nextRetryAtMs': nextRetryAtMs,
        'state': state.name,
        'lastError': lastError,
      };

  factory OutboxMessage.fromJson(Map<String, dynamic> j) => OutboxMessage(
        clientMessageId: j['clientMessageId'] as String,
        ownerId: j['ownerId'] as String? ?? '',
        familyId: j['familyId'] as String? ?? '',
        content: j['content'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
        replyToId: j['replyToId'] as String?,
        retryCount: (j['retryCount'] as num?)?.toInt() ?? 0,
        createdAtMs: (j['createdAtMs'] as num?)?.toInt() ?? 0,
        nextRetryAtMs: (j['nextRetryAtMs'] as num?)?.toInt() ?? 0,
        state: OutboxState.values.firstWhere(
          (s) => s.name == j['state'],
          orElse: () => OutboxState.pending,
        ),
        lastError: j['lastError'] as String?,
      );

  static String encodeList(List<OutboxMessage> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<OutboxMessage> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OutboxMessage.fromJson(e))
          .toList();
    } catch (_) {
      // Bozuk kalıcı veri uygulamayı çökertmemeli; boş kuyruk döner.
      return const [];
    }
  }
}

/// Kalıcı hata sınıfları — bunlarda SONSUZ retry yapılmaz (spec §6.3).
/// RLS reddi/yetki/validation kalıcıdır; ağ/timeout geçicidir.
bool isPermanentFailure(String? errorText) {
  if (errorText == null) return false;
  final e = errorText.toLowerCase();
  return e.contains('permission denied') ||
      e.contains('row-level security') ||
      e.contains('violates') ||
      e.contains('42501') || // insufficient_privilege
      e.contains('unauthorized') ||
      e.contains('forbidden') ||
      e.contains('invalid input');
}

/// Exponential backoff (sn): 2, 5, 15, 30, 60, üst sınır 60 (spec §6.3).
int backoffSeconds(int retryCount) {
  const steps = [2, 5, 15, 30, 60];
  if (retryCount < 0) return steps.first;
  if (retryCount >= steps.length) return steps.last;
  return steps[retryCount];
}

/// Maksimum retry (bu sayıya ulaşınca kalıcı `failed`).
const int maxOutboxRetries = 6;

// ─────────────────────────────────────────────────────────────────────────────
// Hive'a bağlı kalıcı kuyruk servisi + flush.
// ─────────────────────────────────────────────────────────────────────────────

/// Offline kuyruğun kalıcılık + gönderim (flush) katmanı.
class ChatOutboxService {
  static const _key = 'chat_outbox_v1';
  static bool _flushing = false;

  static List<OutboxMessage> _all() =>
      OutboxMessage.decodeList(HiveService.getSetting(_key));

  static Future<void> _save(List<OutboxMessage> list) =>
      HiveService.setSetting(_key, OutboxMessage.encodeList(list));

  /// Belirli kullanıcının bekleyen mesajları (kullanıcı izolasyonu).
  static List<OutboxMessage> pendingFor(String ownerId) => _all()
      .where((m) => m.ownerId == ownerId && m.state != OutboxState.sent)
      .toList();

  static Future<void> enqueue(OutboxMessage m) async {
    final list = _all();
    // Aynı clientMessageId zaten varsa tekrar ekleme (idempotency).
    if (list.any((e) => e.clientMessageId == m.clientMessageId)) return;
    list.add(m);
    await _save(list);
  }

  static Future<void> remove(String clientMessageId) async {
    final list = _all()..removeWhere((e) => e.clientMessageId == clientMessageId);
    await _save(list);
  }

  /// Bekleyen mesajları göndermeyi dener. Yalnızca [ownerId]'ye ait olanlar —
  /// logout sonrası başka kullanıcının mesajı yeni kullanıcı adına GİTMEZ.
  /// Aynı anda ikinci flush çalışmaz (_flushing guard).
  static Future<void> flush(String ownerId) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final m in pendingFor(ownerId)) {
        if (m.retryCount >= maxOutboxRetries) continue;
        if (m.nextRetryAtMs > nowMs) continue;
        try {
          await ChatRepository().sendMessage(
            familyId: m.familyId,
            content: m.content,
            type: MessageType.text,
            replyToId: m.replyToId,
            clientMessageId: m.clientMessageId,
          );
          await remove(m.clientMessageId); // başarı → kuyruktan çık
        } catch (e) {
          if (isPermanentFailure(e.toString())) {
            // Kalıcı hata → sonsuz retry yapma, failed işaretle.
            await _update(m.copyWith(
                state: OutboxState.failed, lastError: e.toString()));
          } else {
            final next = nowMs + backoffSeconds(m.retryCount) * 1000;
            await _update(m.copyWith(
                retryCount: m.retryCount + 1,
                nextRetryAtMs: next,
                state: OutboxState.pending,
                lastError: e.toString()));
          }
          AppLogger.logBestEffort(e, module: 'chat', operation: 'outboxFlush');
        }
      }
    } finally {
      _flushing = false;
    }
  }

  static Future<void> _update(OutboxMessage m) async {
    final list = _all();
    final i = list.indexWhere((e) => e.clientMessageId == m.clientMessageId);
    if (i >= 0) {
      list[i] = m;
      await _save(list);
    }
  }
}
