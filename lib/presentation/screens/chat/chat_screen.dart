import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/entities.dart';
import '../../providers/app_providers.dart';
import '../../../repositories/chat_repository.dart';
import '../../../services/hive_service.dart';
import '../../../services/auth_service.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_composer.dart';
import '../../widgets/chat/reaction_picker.dart';
import '../call/call_contact_list_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  bool _showAttachmentMenu = false;
  ChatMessage? _replyToMessage;
  ChatMessage? _reactingToMessage;
  final _focusNode = FocusNode();
  StreamSubscription<List<ChatMessage>>? _messagesSub;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
    _loadFamilyIdAndListen();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyIdAndListen() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      final profile = await SupabaseConfig.safeClient
          ?.from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      final familyId = profile?['family_id'] as String?;
      if (familyId == null) return;

      _messagesSub = ChatRepository().watchMessages(familyId).listen((messages) {
        ref.read(chatMessagesProvider.notifier).state = messages;
      });
    } catch (e) {
      debugPrint('ChatScreen _loadFamilyIdAndListen error: $e');
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;

      final profile = await SupabaseConfig.safeClient
          ?.from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      final familyId = profile?['family_id'] as String?;
      if (familyId == null) return;

      await ChatRepository().sendMessage(
        familyId: familyId,
        content: text.trim(),
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToSender: _replyToMessage?.senderName,
      );
      _replyToMessage = null;
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('ChatScreen _sendMessage error: $e');
      // Fallback to local provider
      final current = ref.read(chatMessagesProvider);
      final userId = AuthService.currentUserId ?? 'unknown';
      final userName = AuthService.currentUser?.userMetadata?['display_name'] as String? ?? 'Ben';
      final newMsg = ChatMessage(
        id: 'msg${current.length + 1}',
        senderId: userId,
        senderName: userName,
        senderColor: AppColors.blue,
        content: text.trim(),
        createdAt: DateTime.now(),
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToSender: _replyToMessage?.senderName,
      );
      ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
      _replyToMessage = null;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addReaction(String emoji) {
    if (_reactingToMessage == null) return;

    final current = ref.read(chatMessagesProvider);
    final index = current.indexWhere((m) => m.id == _reactingToMessage!.id);
    if (index == -1) return;

    final msg = current[index];
    final reactions = List<MessageReaction>.from(msg.reactions);
    final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

    if (existingIndex != -1) {
      final existing = reactions[existingIndex];
      if (existing.userIds.contains('m1')) {
        // Remove my reaction
        final newUserIds = List<String>.from(existing.userIds)..remove('m1');
        if (newUserIds.isEmpty) {
          reactions.removeAt(existingIndex);
        } else {
          reactions[existingIndex] = MessageReaction(
            emoji: emoji,
            userIds: newUserIds,
          );
        }
      } else {
        // Add my reaction
        reactions[existingIndex] = MessageReaction(
          emoji: emoji,
          userIds: [...existing.userIds, 'm1'],
        );
      }
    } else {
      reactions.add(MessageReaction(emoji: emoji, userIds: ['m1']));
    }

    final updated = msg.copyWith(reactions: reactions);
    final newList = List<ChatMessage>.from(current);
    newList[index] = updated;

    ref.read(chatMessagesProvider.notifier).state = newList;
    _reactingToMessage = null;
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final current = ref.read(chatMessagesProvider);
    final newMsg = ChatMessage(
      id: 'msg${current.length + 1}',
      senderId: '',
      senderName: 'Ben',
      senderColor: AppColors.blue,
      content: '📷 Fotoğraf',
      createdAt: DateTime.now(),
      type: MessageType.image,
      imageUrl: picked.path,
    );

    ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
    setState(() => _showAttachmentMenu = false);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final current = ref.read(chatMessagesProvider);
    final newMsg = ChatMessage(
      id: 'msg${current.length + 1}',
      senderId: '',
      senderName: 'Ben',
      senderColor: AppColors.blue,
      content: '📷 Fotoğraf',
      createdAt: DateTime.now(),
      type: MessageType.image,
      imageUrl: picked.path,
    );

    ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
    setState(() => _showAttachmentMenu = false);
  }

  void _shareLocation() {
    final current = ref.read(chatMessagesProvider);
    final newMsg = ChatMessage(
      id: 'msg${current.length + 1}',
      senderId: '',
      senderName: 'Ben',
      senderColor: AppColors.blue,
      content: 'Yoldayım, eve 10 dakika.',
      createdAt: DateTime.now(),
      type: MessageType.location,
    );

    ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
    setState(() => _showAttachmentMenu = false);
  }

  Future<void> _sendVoiceMessage(File file, int durationMs) async {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 9999);
    final current = ref.read(chatMessagesProvider);
    final newMsg = ChatMessage(
      id: 'msg${current.length + 1}',
      senderId: 'm1',
      senderName: 'Ben',
      senderColor: AppColors.blue,
      content: '🎤 Sesli mesaj',
      createdAt: DateTime.now(),
      type: MessageType.audio,
      audioUrl: file.path,
      audioDuration: durationSeconds,
    );

    ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _pinMessage(ChatMessage message) {
    final current = ref.read(chatMessagesProvider);
    final newList = current.map((m) {
      return m.copyWith(isPinned: m.id == message.id);
    }).toList();
    ref.read(chatMessagesProvider.notifier).state = newList;
    HapticFeedback.mediumImpact();
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    if (messageDay == today) return 'Bugün';
    if (messageDay == yesterday) return 'Dün';
    return DateFormat('d MMMM', 'tr_TR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(chatMessagesProvider, (prev, next) {
      HiveService.saveChatMessages(next);
    });
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    final pinnedMessage = messages.where((m) => m.isPinned).firstOrNull;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.hub),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aile Sohbeti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${ref.watch(familyMembersProvider).length} üye',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.mood),
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: AppColors.purple,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CallContactListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.phone_outlined),
          ),
          IconButton(
            onPressed: () => _showChatMenu(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Pinned message
              if (pinnedMessage != null)
                _PinnedMessageBar(
                  message: pinnedMessage,
                  onUnpin: () => _pinMessage(
                    pinnedMessage.copyWith(isPinned: false),
                  ),
                ),
              // Messages
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showEmojiPicker = false;
                      _showAttachmentMenu = false;
                    });
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == 'm1';

                      // Day separator
                      final showDay = index == 0 ||
                          !_sameDay(
                            msg.createdAt,
                            messages[index - 1].createdAt,
                          );

                      return Column(
                        children: [
                          if (showDay)
                            _DaySeparator(label: _dayLabel(msg.createdAt)),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Dismissible(
                              key: ValueKey(msg.id),
                              direction: isMe
                                  ? DismissDirection.endToStart
                                  : DismissDirection.startToEnd,
                              onDismissed: (_) => setState(
                                () => _replyToMessage = msg,
                              ),
                              background: Container(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.reply,
                                  color: AppColors.cobalt,
                                ),
                              ),
                              child: ChatBubble(
                                message: msg,
                                isMe: isMe,
                                showSender: _showSender(msg, messages, index),
                                onReply: () => setState(
                                  () => _replyToMessage = msg,
                                ),
                                onReact: () => setState(
                                  () => _reactingToMessage = msg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Composer
              ChatComposer(
                onSend: _sendMessage,
                onSendVoice: _sendVoiceMessage,
                onAttachment: () {
                  setState(() {
                    _showAttachmentMenu = !_showAttachmentMenu;
                    _showEmojiPicker = false;
                  });
                },
                onEmoji: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                    _showAttachmentMenu = false;
                  });
                  if (_showEmojiPicker) {
                    FocusScope.of(context).unfocus();
                  }
                },
                onCancelReply: () => setState(() => _replyToMessage = null),
                replyToSender: _replyToMessage?.senderName,
                replyToContent: _replyToMessage?.content,
              ),
              // Emoji picker
              if (_showEmojiPicker)
                SizedBox(
                  height: 280,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      // Not using this approach, we use the composer text field
                    },
                    config: Config(
                      height: 280,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        columns: 8,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        iconColor: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                        iconColorSelected: AppColors.cobalt,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        buttonColor: AppColors.cobalt,
                        buttonIconColor: Colors.white,
                        showBackspaceButton: true,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              // Bottom safe area
              SizedBox(height: safeBottom + 8),
            ],
          ),
          // Attachment menu overlay
          if (_showAttachmentMenu)
            _AttachmentMenu(
              onCamera: _takePhoto,
              onGallery: _pickImage,
              onLocation: _shareLocation,
              onClose: () => setState(() => _showAttachmentMenu = false),
            ),
          // Reaction picker overlay
          if (_reactingToMessage != null)
            ReactionPicker(
              onClose: () => setState(() => _reactingToMessage = null),
              onSelect: _addReaction,
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _showSender(ChatMessage msg, List<ChatMessage> messages, int index) {
    if (msg.senderId == 'm1') return false;
    if (index == 0) return true;
    final prev = messages[index - 1];
    return prev.senderId != msg.senderId ||
        !_sameDay(prev.createdAt, msg.createdAt);
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _MenuItem(
                  icon: Icons.search,
                  label: 'Mesajlarda Ara',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirim Ayarları',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.archive_outlined,
                  label: 'Sohbeti Arşivle',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.delete_outline,
                  label: 'Sohbeti Temizle',
                  isDanger: true,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DaySeparator extends StatelessWidget {
  final String label;

  const _DaySeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withAlpha(180)
              : Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
          ),
        ),
      ),
    );
  }
}

class _PinnedMessageBar extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onUnpin;

  const _PinnedMessageBar({required this.message, required this.onUnpin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cobalt.withAlpha(30)
            : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cobalt.withAlpha(isDark ? 50 : 40),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: AppColors.cobalt),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cobalt,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onUnpin,
            icon: const Icon(Icons.close, size: 18, color: AppColors.cobalt),
          ),
        ],
      ),
    );
  }
}

class _AttachmentMenu extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onLocation;
  final VoidCallback onClose;

  const _AttachmentMenu({
    required this.onCamera,
    required this.onGallery,
    required this.onLocation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(40),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _AttachmentItem(
                          icon: Icons.camera_alt,
                          color: AppColors.error,
                          label: 'Kamera',
                          onTap: onCamera,
                        ),
                        _AttachmentItem(
                          icon: Icons.photo,
                          color: AppColors.purple,
                          label: 'Galeri',
                          onTap: onGallery,
                        ),
                        _AttachmentItem(
                          icon: Icons.location_on,
                          color: AppColors.success,
                          label: 'Konum',
                          onTap: onLocation,
                        ),
                        _AttachmentItem(
                          icon: Icons.event,
                          color: AppColors.warning,
                          label: 'Etkinlik',
                          onTap: () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.poll,
                          color: AppColors.cobalt,
                          label: 'Anket',
                          onTap: () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.contact_page,
                          color: AppColors.pink,
                          label: 'Kişi',
                          onTap: () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.mic,
                          color: AppColors.orange,
                          label: 'Ses',
                          onTap: () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.description,
                          color: AppColors.slate,
                          label: 'Dosya',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppColors.error : AppColors.cobalt,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDanger
              ? AppColors.error
              : (isDark ? AppColors.darkTextPrimary : AppColors.dark),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
