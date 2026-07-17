import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class ChatRepository with RepositoryErrorHandler {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();
  SupabaseClient get _client {
    final client = AuthService.safeClient;
    if (client == null) throw Exception('Sunucu bağlantısı kurulmadı');
    return client;
  }

  final String _table = 'messages';

  Future<List<ChatMessage>> getMessages(String familyId) async {
    return handleRepositoryCall(() async {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: true);
      return (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    }, 'getMessages');
  }

  Future<ChatMessage> sendMessage({
    required String familyId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSender,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? audioUrl,
    int? audioDuration,
    String? videoUrl,
    String? fileName,
    int? fileSize,
    double? latitude,
    double? longitude,
    // Offline idempotency: aynı client mesajı iki kez insert edilirse
    // uq_messages_client_id unique index tek satırı korur.
    String? clientMessageId,
  }) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final user = AuthService.currentUser;
      final name =
          user?.userMetadata?['display_name']?.toString() ?? 'Kullanıcı';

      final typeStr = switch (type) {
        MessageType.image => 'image',
        MessageType.audio => 'audio',
        MessageType.location => 'location',
        MessageType.event => 'event',
        MessageType.system => 'system',
        MessageType.gif => 'gif',
        MessageType.video => 'video',
        MessageType.file => 'file',
        MessageType.poll => 'poll',
        _ => 'text',
      };

      final response = await _client
          .from(_table)
          .insert({
            'family_id': familyId,
            'user_id': userId,
            'sender_name': name,
            'content': content,
            'type': typeStr,
            'image_url': imageUrl,
            'audio_url': audioUrl,
            'audio_duration': audioDuration,
            'video_url': videoUrl,
            'file_name': fileName,
            'file_size': fileSize,
            'latitude': latitude,
            'longitude': longitude,
            'reply_to_id': replyToId,
            'reply_to_content': replyToContent,
            'reply_to_sender': replyToSender,
            'client_message_id': clientMessageId,
          })
          .select()
          .single();

      return _fromJson(response);
    }, 'sendMessage');
  }

  /// Reaction ekle/kaldır — gerçek backend (message_reactions tablosu).
  /// Aynı (mesaj,kullanıcı,emoji) varsa kaldırır (toggle), yoksa ekler.
  Future<void> toggleReaction({
    required String messageId,
    required String familyId,
    required String emoji,
  }) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');
      final existing = await _client
          .from('message_reactions')
          .select('id')
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji)
          .maybeSingle();
      if (existing != null) {
        await _client
            .from('message_reactions')
            .delete()
            .eq('id', existing['id'] as String);
      } else {
        await _client.from('message_reactions').insert({
          'message_id': messageId,
          'family_id': familyId,
          'user_id': userId,
          'emoji': emoji,
        });
      }
    }, 'toggleReaction');
  }

  /// Sohbeti bu kullanıcı için "okundu" işaretle (conversation-level).
  Future<void> markRead({
    required String familyId,
    required String lastMessageId,
  }) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      await _client.from('chat_read_states').upsert({
        'family_id': familyId,
        'user_id': userId,
        'last_read_message_id': lastMessageId,
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      });
    }, 'markRead');
  }

  /// Mesajı sabitle/kaldır (yalnızca tek aktif pin — diğerlerini temizler).
  Future<void> setPinned({
    required String familyId,
    required String messageId,
    required bool pinned,
  }) async {
    return handleRepositoryCall(() async {
      if (pinned) {
        await _client
            .from(_table)
            .update({'is_pinned': false})
            .eq('family_id', familyId)
            .eq('is_pinned', true);
      }
      await _client
          .from(_table)
          .update({'is_pinned': pinned}).eq('id', messageId);
    }, 'setPinned');
  }

  Future<void> deleteMessage(String id) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).delete().eq('id', id);
    }, 'deleteMessage');
  }

  Future<void> updateMessage(String id, String content) async {
    return handleRepositoryCall(() async {
      await _client.from(_table).update({'content': content}).eq('id', id);
    }, 'updateMessage');
  }

  Stream<List<ChatMessage>> watchMessages(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at')
          .map((data) => data.map((e) => _fromJson(e)).toList());
    } catch (e) {
      debugPrint('ChatRepository.watchMessages error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchMessages]: $e'));
    }
  }

  ChatMessage _fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'text';
    final type = switch (typeStr) {
      'image' => MessageType.image,
      'audio' => MessageType.audio,
      'location' => MessageType.location,
      'event' => MessageType.event,
      'system' => MessageType.system,
      'gif' => MessageType.gif,
      'video' => MessageType.video,
      'file' => MessageType.file,
      _ => MessageType.text,
    };

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['user_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Kullanıcı',
      senderColor: _parseColor(json['sender_color']),
      content: (json['content'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: (json['is_read'] as bool?) ?? false,
      type: type,
      imageUrl: json['image_url']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      audioDuration: json['audio_duration'] as int?,
      replyToId: json['reply_to_id']?.toString(),
      replyToContent: json['reply_to_content']?.toString(),
      replyToSender: json['reply_to_sender']?.toString(),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      readCount: (json['read_count'] as int?) ?? 0,
    );
  }

  // ignore: unused_element
  Color _parseColor(dynamic value) => const Color(0xFF3B82F6);
}
