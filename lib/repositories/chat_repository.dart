import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/chat_reaction_codec.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class ChatRepository with RepositoryErrorHandler {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  static const _mediaBucket = 'chat-media';
  static const _signedUrlDuration = 60 * 60 * 24 * 7;

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
      return Future.wait(
        (response as List)
            .cast<Map<String, dynamic>>()
            .map(_fromJson),
      );
    }, 'getMessages');
  }

  Future<String> uploadMedia({
    required String familyId,
    required File file,
  }) async {
    return handleRepositoryCall(() async {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final extension = file.path.contains('.')
          ? file.path.split('.').last.toLowerCase().replaceAll(
                RegExp('[^a-z0-9]'),
                '',
              )
          : 'bin';
      final path = '$familyId/$userId/${const Uuid().v4()}.$extension';
      await _client.storage
          .from(_mediaBucket)
          .uploadBinary(path, await file.readAsBytes());
      return path;
    }, 'uploadMedia');
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
        _ => 'text',
      };

      final response = await _client.from(_table).insert({
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
        'reply_to_id': replyToId,
        'reply_to_content': replyToContent,
        'reply_to_sender': replyToSender,
      }).select().single();

      return _fromJson(response);
    }, 'sendMessage');
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

  Future<void> toggleReaction(String messageId, String emoji) async {
    return handleRepositoryCall(() async {
      await _client.rpc(
        'toggle_message_reaction',
        params: {'p_message_id': messageId, 'p_emoji': emoji},
      );
    }, 'toggleReaction');
  }

  Future<void> setPinned(String messageId, bool pinned) async {
    return handleRepositoryCall(() async {
      await _client.rpc(
        'set_message_pinned',
        params: {'p_message_id': messageId, 'p_pinned': pinned},
      );
    }, 'setPinned');
  }

  Stream<List<ChatMessage>> watchMessages(String familyId) {
    try {
      return _client
          .from(_table)
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at')
          .asyncMap(
            (data) => Future.wait(
              data.map((row) => _fromJson(row)),
            ),
          );
    } catch (e) {
      debugPrint('ChatRepository.watchMessages error: $e');
      return Stream.error(
        RepositoryException('Beklenmeyen hata [watchMessages]: $e'),
      );
    }
  }

  Future<ChatMessage> _fromJson(Map<String, dynamic> json) async {
    final typeStr = json['type']?.toString() ?? 'text';
    final type = switch (typeStr) {
      'image' => MessageType.image,
      'audio' => MessageType.audio,
      'location' => MessageType.location,
      'event' || 'event_share' => MessageType.event,
      'system' || 'announcement' => MessageType.system,
      'gif' => MessageType.gif,
      'video' => MessageType.video,
      'file' => MessageType.file,
      _ => MessageType.text,
    };

    final reactions = parseMessageReactions(json['reactions']);

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['user_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Kullanıcı',
      senderColor: _parseColor(json['sender_color']),
      content: (json['content'] ?? json['text'])?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: (json['is_read'] as bool?) ?? false,
      type: type,
      imageUrl: await _signedMediaUrl(json['image_url']?.toString()),
      audioUrl: await _signedMediaUrl(json['audio_url']?.toString()),
      audioDuration: json['audio_duration'] as int?,
      videoUrl: await _signedMediaUrl(json['video_url']?.toString()),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] as int?,
      reactions: reactions,
      replyToId: (json['reply_to_id'] ?? json['reply_to'])?.toString(),
      replyToContent: json['reply_to_content']?.toString(),
      replyToSender: json['reply_to_sender']?.toString(),
      isPinned: (json['is_pinned'] ?? json['pinned']) as bool? ?? false,
      readCount: (json['read_count'] as int?) ?? 0,
    );
  }

  Future<String?> _signedMediaUrl(String? value) async {
    if (value == null || value.isEmpty || value.startsWith('http')) {
      return value;
    }
    try {
      return await _client.storage
          .from(_mediaBucket)
          .createSignedUrl(value, _signedUrlDuration);
    } catch (e) {
      debugPrint('ChatRepository media URL error: $e');
      return null;
    }
  }

  Color _parseColor(dynamic value) => const Color(0xFF3B82F6);
}
