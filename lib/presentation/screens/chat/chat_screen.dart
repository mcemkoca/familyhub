import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<String?> _getFamilyId() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    final profile = await SupabaseConfig.safeClient
        ?.from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  Future<void> _loadFamilyIdAndListen() async {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null || !mounted) return;

      final messages = await ChatRepository().getMessages(familyId);
      if (!mounted) return;
      ref.read(chatMessagesProvider.notifier).state = messages;

      _messagesSub = ChatRepository().watchMessages(familyId).listen(
        (messages) {
          if (!mounted) return;
          ref.read(chatMessagesProvider.notifier).state = messages;
        },
        onError: (Object error) => _showError('Sohbet yüklenemedi: $error'),
      );
    } catch (e) {
      _showError('Sohbet bağlantısı kurulamadı: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');

      await ChatRepository().sendMessage(
        familyId: familyId,
        content: text.trim(),
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToSender: _replyToMessage?.senderName,
      );
      if (!mounted) return;
      setState(() => _replyToMessage = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showError('Mesaj gönderilemedi: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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

  Future<void> _addReaction(String emoji) async {
    final message = _reactingToMessage;
    if (message == null) return;
    setState(() => _reactingToMessage = null);
    try {
      await ChatRepository().toggleReaction(message.id, emoji);
    } catch (e) {
      _showError('Tepki kaydedilemedi: $e');
    }
  }

  Future<void> _sendPickedMedia({
    required File file,
    required MessageType type,
    required String content,
    int? audioDuration,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');
      final repository = ChatRepository();
      final mediaPath = await repository.uploadMedia(
        familyId: familyId,
        file: file,
      );
      await repository.sendMessage(
        familyId: familyId,
        content: content,
        type: type,
        imageUrl: type == MessageType.image ? mediaPath : null,
        audioUrl: type == MessageType.audio ? mediaPath : null,
        audioDuration: audioDuration,
        videoUrl: type == MessageType.video ? mediaPath : null,
        fileName: fileName,
        fileSize: fileSize,
      );
      if (!mounted) return;
      setState(() => _showAttachmentMenu = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showError('Medya gönderilemedi: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _sendPickedMedia(
      file: File(picked.path),
      type: MessageType.image,
      content: '📷 Fotoğraf',
    );
  }

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _sendPickedMedia(
      file: File(picked.path),
      type: MessageType.image,
      content: '📷 Fotoğraf',
    );
  }

  Future<void> _shareLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni verilmedi');
      }
      final position = await Geolocator.getCurrentPosition();
      final familyId = await _getFamilyId();
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');
      final url = 'https://www.openstreetmap.org/'
          '?mlat=${position.latitude}&mlon=${position.longitude}';
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: '📍 Konumumu paylaştım\n$url',
        type: MessageType.location,
      );
      if (mounted) setState(() => _showAttachmentMenu = false);
    } catch (e) {
      _showError('Konum paylaşılamadı: $e');
    }
  }

  Future<void> _sendVoiceMessage(File file, int durationMs) async {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 9999);
    await _sendPickedMedia(
      file: file,
      type: MessageType.audio,
      content: '🎤 Sesli mesaj',
      audioDuration: durationSeconds,
    );
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final size = await file.length();
    final name = picked.path.split('/').last.split('\\').last;
    await _sendPickedMedia(
      file: file,
      type: MessageType.video,
      content: '🎬 $name',
      fileName: name,
      fileSize: size,
    );
  }

  void _showGifPicker() {
    setState(() => _showAttachmentMenu = false);
    const gifs = [
      'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
      'https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif',
      'https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif',
      'https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif',
      'https://media.giphy.com/media/xT9IgG50Lg7russbDa/giphy.gif',
      'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      'https://media.giphy.com/media/3oEjHFOscgNwdSRRDy/giphy.gif',
      'https://media.giphy.com/media/l0HlvtIPzPdt2usKs/giphy.gif',
      'https://media.giphy.com/media/26BRuo6sLetdllPAQ/giphy.gif',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'GIF Seç',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: gifs.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendGif(gifs[i]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        gifs[i],
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.gif,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendGif(String gifUrl) async {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) throw Exception('Aile bilgisi bulunamadı');
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: '🎭 GIF',
        type: MessageType.gif,
        imageUrl: gifUrl,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showError('GIF gönderilemedi: $e');
    }
  }

  Future<void> _pinMessage(ChatMessage message) async {
    try {
      await ChatRepository().setPinned(message.id, !message.isPinned);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Mesaj sabitleme güncellenemedi: $e');
    }
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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
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
                      final isMe = msg.senderId == AuthService.currentUserId;

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
              onGif: _showGifPicker,
              onVideo: _pickVideo,
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
    if (msg.senderId == AuthService.currentUserId) return false;
    if (index == 0) return true;
    final prev = messages[index - 1];
    return prev.senderId != msg.senderId ||
        !_sameDay(prev.createdAt, msg.createdAt);
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
  final VoidCallback? onGif;
  final VoidCallback? onVideo;

  const _AttachmentMenu({
    required this.onCamera,
    required this.onGallery,
    required this.onLocation,
    required this.onClose,
    this.onGif,
    this.onVideo,
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
                          icon: Icons.gif_box_outlined,
                          color: AppColors.orange,
                          label: 'GIF',
                          onTap: onGif ?? () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.videocam_outlined,
                          color: const Color(0xFF7C3AED),
                          label: 'Video',
                          onTap: onVideo ?? () {},
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

