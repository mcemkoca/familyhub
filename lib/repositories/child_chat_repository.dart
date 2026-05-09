import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';
import '../domain/entities.dart';
import '../services/child_auth_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ChildChatRepository with RepositoryErrorHandler {
  static final ChildChatRepository _instance = ChildChatRepository._internal();
  factory ChildChatRepository() => _instance;
  ChildChatRepository._internal();
  SupabaseClient get _client => SupabaseConfig.safeClient!;

  String? get _familyId => ChildAuthService.currentFamilyId;
  String? get _childId => ChildAuthService.currentChildId;
  String? get _childName => ChildAuthService.currentSession?.childName;

  void _checkSession() {
    if (_familyId == null || _childId == null) {
      throw Exception('Çocuk oturumu bulunamadı');
    }
  }

  Future<List<ChatMessage>> getMessages() async {
    _checkSession();
    try {
      final response = await _client
          .from('messages')
          .select('*')
          .eq('family_id', _familyId!)
          .order('created_at', ascending: true);
      final list = (response as List).map((e) => _fromJson(e as Map<String, dynamic>)).toList();
      await HiveService.saveChatMessages(list);
      return list;
    } catch (_) {
      return HiveService.getChatMessages();
    }
  }

  Future<ChatMessage> sendMessage(String content) async {
    return handleRepositoryCall(() async {
      _checkSession();
      final response = await _client
          .from('messages')
          .insert({
            'family_id': _familyId!,
            'user_id': _childId!,
            'sender_name': _childName ?? 'Çocuk',
            'content': content,
            'type': 'text',
            'sender_type': 'child',
          })
          .select()
          .single();

      await ChildAuthService.logActivity(
        'message_sent',
        details: {'content_length': content.length},
      );

      await NotificationService.showInstantNotification(
        title: '💬 Mesaj gönderildi',
        body: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      );

      return _fromJson(response);
    }, 'sendMessage');
  }

  Stream<List<ChatMessage>> watchMessages() {
    try {
      final familyId = _familyId;
      if (familyId == null) {
        return Stream.value([]);
      }
      return _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at')
          .map((data) => data.map((e) => _fromJson(e)).toList());
    } catch (e) {
      debugPrint('ChildChatRepository.watchMessages error: $e');
      return Stream.error(RepositoryException('Beklenmeyen hata [watchMessages]: $e'));
    }
  }

  ChatMessage _fromJson(Map<String, dynamic> json) {
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
      type: MessageType.text,
      replyToId: json['reply_to_id']?.toString(),
      replyToContent: json['reply_to_content']?.toString(),
      replyToSender: json['reply_to_sender']?.toString(),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      readCount: (json['read_count'] as int?) ?? 0,
    );
  }

  Color _parseColor(dynamic value) => const Color(0xFF10B981);
}
