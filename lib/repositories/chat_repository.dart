import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities.dart';
import '../services/auth_service.dart';

class ChatRepository {
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
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: true);
      return (response as List).map((e) => _fromJson(e)).toList();
    } catch (e) {
      debugPrint('ChatRepository.getMessages error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<ChatMessage> sendMessage({
    required String familyId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToSender,
    MessageType type = MessageType.text,
    String? audioUrl,
    int? audioDuration,
  }) async {
    try {
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
            'audio_url': audioUrl,
            'audio_duration': audioDuration,
            'reply_to_id': replyToId,
            'reply_to_content': replyToContent,
            'reply_to_sender': replyToSender,
          })
          .select()
          .single();

      return _fromJson(response);
    } catch (e) {
      debugPrint('ChatRepository.sendMessage error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> deleteMessage(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      debugPrint('ChatRepository.deleteMessage error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
  }

  Future<void> updateMessage(String id, String content) async {
    try {
      await _client.from(_table).update({'content': content}).eq('id', id);
    } catch (e) {
      debugPrint('ChatRepository.updateMessage error: $e');
      throw Exception('Veritabanı hatası: $e');
    }
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
      return Stream.error(Exception('Veritabanı hatası: $e'));
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
      _ => MessageType.text,
    };

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['user_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Kullanıcı',
      senderColor: _parseColor(json['sender_color']),
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: type,
      imageUrl: json['image_url']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      audioDuration: json['audio_duration'] as int?,
      replyToId: json['reply_to_id']?.toString(),
      replyToContent: json['reply_to_content']?.toString(),
      replyToSender: json['reply_to_sender']?.toString(),
      isPinned: json['is_pinned'] ?? false,
      readCount: json['read_count'] ?? 0,
    );
  }

  // ignore: unused_element
  Color _parseColor(dynamic value) => const Color(0xFF3B82F6);
}
