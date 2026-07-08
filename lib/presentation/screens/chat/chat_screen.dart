import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
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
import '../../../services/location_service.dart';
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

  Future<void> _shareLocation() async {
    setState(() => _showAttachmentMenu = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Konum alınıyor…'), duration: Duration(seconds: 1)));

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Konum alınamadı. GPS açık olduğundan emin olun.')));
      return;
    }
    // Gerçek adresi çöz (başarısızsa koordinat metnini kullan).
    String label;
    try {
      final addr =
          await LocationService.getAddressFromCoords(pos.latitude, pos.longitude);
      label = (addr != null && addr.fullAddress.isNotEmpty)
          ? addr.fullAddress
          : (addr?.city.isNotEmpty == true
              ? addr!.city
              : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
    } catch (_) {
      label =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    }

    final current = ref.read(chatMessagesProvider);
    final newMsg = ChatMessage(
      id: 'msg${current.length + 1}',
      senderId: 'm1',
      senderName: 'Ben',
      senderColor: AppColors.blue,
      content: '📍 $label',
      createdAt: DateTime.now(),
      type: MessageType.location,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    ref.read(chatMessagesProvider.notifier).state = [...current, newMsg];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final size = await file.length();
    final name = picked.path.split('/').last.split('\\').last;
    final current = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [
      ...current,
      ChatMessage(
        id: 'msg${current.length + 1}',
        senderId: 'm1',
        senderName: 'Ben',
        senderColor: AppColors.blue,
        content: '🎬 $name',
        createdAt: DateTime.now(),
        type: MessageType.video,
        videoUrl: picked.path,
        fileName: name,
        fileSize: size,
      ),
    ];
    setState(() => _showAttachmentMenu = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _votePoll(ChatMessage msg, int optionIndex) {
    final poll = msg.poll;
    if (poll == null) return;
    final updated = poll.toggleVote(optionIndex, 'm1');
    final list = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [
      for (final m in list)
        if (m.id == msg.id) m.copyWith(poll: updated) else m,
    ];
  }

  void _createPoll() {
    setState(() => _showAttachmentMenu = false);
    final questionCtrl = TextEditingController();
    final optionCtrls = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surface = Theme.of(ctx).colorScheme.surface;
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            InputDecoration deco(String hint) => InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: onSurface.withAlpha(90)),
                  filled: true,
                  fillColor: onSurface.withAlpha(12),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                );
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: onSurface.withAlpha(40),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.poll_rounded,
                            color: Color(0xFF8B5CF6), size: 22),
                        const SizedBox(width: 8),
                        Text('Anket Oluştur',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: onSurface)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: questionCtrl,
                      style: TextStyle(color: onSurface),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: deco('Soru (ör. Akşam ne yiyelim?)'),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < optionCtrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionCtrls[i],
                                style: TextStyle(color: onSurface),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: deco('Seçenek ${i + 1}'),
                              ),
                            ),
                            if (optionCtrls.length > 2)
                              IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: onSurface.withAlpha(120)),
                                onPressed: () => setSheet(
                                    () => optionCtrls.removeAt(i)),
                              ),
                          ],
                        ),
                      ),
                    if (optionCtrls.length < 6)
                      TextButton.icon(
                        onPressed: () => setSheet(() =>
                            optionCtrls.add(TextEditingController())),
                        icon: const Icon(Icons.add_rounded,
                            size: 18, color: Color(0xFF8B5CF6)),
                        label: const Text('Seçenek ekle',
                            style: TextStyle(color: Color(0xFF8B5CF6))),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final q = questionCtrl.text.trim();
                          final opts = optionCtrls
                              .map((c) => c.text.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          if (q.isEmpty || opts.length < 2) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Soru ve en az 2 seçenek girin')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _sendPoll(q, opts);
                        },
                        child: const Text('Anketi Gönder',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sendPoll(String question, List<String> options) {
    final current = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [
      ...current,
      ChatMessage(
        id: 'msg${current.length + 1}',
        senderId: 'm1',
        senderName: 'Ben',
        senderColor: AppColors.blue,
        content: question,
        createdAt: DateTime.now(),
        type: MessageType.poll,
        poll: PollData(
          question: question,
          options: options,
          votes: List.generate(options.length, (_) => <String>[]),
        ),
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickFile() async {
    setState(() => _showAttachmentMenu = false);
    try {
      final XFile? picked = await openFile();
      if (picked == null) return;
      final path = picked.path;
      final name = picked.name;
      final size = await picked.length();

      final current = ref.read(chatMessagesProvider);
      ref.read(chatMessagesProvider.notifier).state = [
        ...current,
        ChatMessage(
          id: 'msg${current.length + 1}',
          senderId: 'm1',
          senderName: 'Ben',
          senderColor: AppColors.blue,
          content: '📄 $name',
          createdAt: DateTime.now(),
          type: MessageType.file,
          videoUrl: path, // yerel dosya yolu (ileride Storage'a yüklenebilir)
          fileName: name,
          fileSize: size,
        ),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya seçilemedi')),
        );
      }
    }
  }

  void _showGifPicker() {
    setState(() => _showAttachmentMenu = false);
    // Popular GIF URLs for demo
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
        final sheetBg = Theme.of(ctx).colorScheme.surface;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.onSurface.withAlpha(40),
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
                    crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4,
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
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF9CA3AF),
                          child: const Icon(Icons.gif, size: 32, color: Colors.grey),
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

  void _sendGif(String gifUrl) {
    final current = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [
      ...current,
      ChatMessage(
        id: 'msg${current.length + 1}',
        senderId: 'm1',
        senderName: 'Ben',
        senderColor: AppColors.blue,
        content: '🎭 GIF',
        createdAt: DateTime.now(),
        type: MessageType.gif,
        imageUrl: gifUrl,
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

    ref.listen(chatMessagesProvider, (prev, next) {
      HiveService.saveChatMessages(next);
    });
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    final pinnedMessage = messages.where((m) => m.isPinned).firstOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
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
              color: Color(0xFF6366F1),
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
                                  color: Color(0xFF6366F1),
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
                                onVote: msg.type == MessageType.poll
                                    ? (i) => _votePoll(msg, i)
                                    : null,
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
                    config: const Config(
                      height: 280,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: Color(0xFF13131A),
                        columns: 8,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: Color(0xFF13131A),
                        iconColor: Color(0xFF6B7280),
                        iconColorSelected: Color(0xFF6366F1),
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        backgroundColor: Color(0xFF13131A),
                        buttonColor: Color(0xFF6366F1),
                        buttonIconColor: Colors.white,
                        showBackspaceButton: true,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: Color(0xFF13131A),
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
              onFile: _pickFile,
              onPoll: _createPoll,
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
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: Color(0xFF6366F1)),
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
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onUnpin,
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF6366F1)),
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
  final VoidCallback? onFile;
  final VoidCallback? onPoll;

  const _AttachmentMenu({
    required this.onCamera,
    required this.onGallery,
    required this.onLocation,
    required this.onClose,
    this.onGif,
    this.onVideo,
    this.onFile,
    this.onPoll,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
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
                          color: const Color(0xFF6366F1),
                          label: 'Galeri',
                          onTap: onGallery,
                        ),
                        _AttachmentItem(
                          icon: Icons.location_on,
                          color: const Color(0xFF10B981),
                          label: 'Konum',
                          onTap: onLocation,
                        ),
                        _AttachmentItem(
                          icon: Icons.event,
                          color: const Color(0xFFF59E0B),
                          label: 'Etkinlik',
                          onTap: () => context.push(AppRoutes.calendar),
                        ),
                        _AttachmentItem(
                          icon: Icons.poll,
                          color: const Color(0xFF6366F1),
                          label: 'Anket',
                          onTap: onPoll ?? () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.contact_page,
                          color: const Color(0xFFEC4899),
                          label: 'Kişi',
                          onTap: () => context.push(AppRoutes.family),
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
                        _AttachmentItem(
                          icon: Icons.description,
                          color: const Color(0xFF6B7280),
                          label: 'Dosya',
                          onTap: onFile ?? () {},
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
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppColors.error : const Color(0xFF6366F1),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDanger
              ? AppColors.error
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}



