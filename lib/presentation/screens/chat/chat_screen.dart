import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/app_logger.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/entities.dart';
import '../../../services/chat_storage_service.dart';
import '../../../services/chat_presence_service.dart';
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
  // Merkezi: her handler'da tekrar profile sorgusu yapmamak için önbellek.
  String? _familyId;
  String? get _myId => AuthService.currentUserId;
  ChatPresenceService? _presence;
  List<TypingUser> _typingUsers = const [];

  String get _myDisplayName =>
      AuthService.currentUser?.userMetadata?['display_name']?.toString() ??
      'Kullanıcı';

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
    _presence?.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyIdAndListen() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      // Üyelik family_members'ta (profiles'ta family_id yok — canlı şema).
      final row = await SupabaseConfig.safeClient
          ?.from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      final familyId = row?['family_id'] as String?;
      if (familyId == null) return;
      _familyId = familyId;

      // Typing + presence (ephemeral, DB'ye yazılmaz).
      final presence = ChatPresenceService(familyId);
      presence.typingUsers.listen((users) {
        if (mounted) setState(() => _typingUsers = users);
      });
      presence.connect(_myDisplayName);
      _presence = presence;

      _messagesSub = ChatRepository().watchMessages(familyId).listen(
        (messages) {
          ref.read(chatMessagesProvider.notifier).state = messages;
          _markLatestRead(familyId, messages);
        },
        onError: (Object e) => AppLogger.logBestEffort(e,
            module: 'chat', operation: 'watchMessages'),
      );
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'loadFamilyIdAndListen', stackTrace: st);
    }
  }

  String? _lastMarkedReadId;

  /// Sohbet açıkken gelen son mesajı kullanıcı için "okundu" işaretler
  /// (chat_read_states). Debounce: aynı mesaj ID'si iki kez yazılmaz ve
  /// kullanıcının kendi mesajı okundu tetiklemez (spec §16).
  void _markLatestRead(String familyId, List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.id.isEmpty || last.id == _lastMarkedReadId) return;
    if (last.senderId == _myId) return; // kendi mesajım okundu sayılmaz
    _lastMarkedReadId = last.id;
    // Ekran foreground'da (bu widget mounted) olduğu için okundu sayılır.
    ChatRepository()
        .markRead(familyId: familyId, lastMessageId: last.id)
        .catchError((Object e) => AppLogger.logBestEffort(e,
            module: 'chat', operation: 'markRead'));
  }

  /// familyId'yi (önbellekten veya profilden) döndürür; yoksa null.
  Future<String?> _resolveFamilyId() async {
    if (_familyId != null) return _familyId;
    final userId = _myId;
    if (userId == null) return null;
    final row = await SupabaseConfig.safeClient
        ?.from('family_members')
        .select('family_id')
        .eq('user_id', userId)
        .maybeSingle();
    _familyId = row?['family_id'] as String?;
    return _familyId;
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);

    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatNoFamily)));
      return;
    }

    final reply = _replyToMessage;
    try {
      // Mesaj yalnızca backend onayladıktan sonra listede görünür (realtime
      // stream ile gelir). Sahte "gönderildi" YOK.
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: text.trim(),
        replyToId: reply?.id,
        replyToContent: reply?.content,
        replyToSender: reply?.senderName,
      );
      _replyToMessage = null;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      // Backend başarısız → sahte local mesaj EKLEME. Hatayı göster, metni geri
      // ver, kullanıcı tekrar denesin.
      AppLogger.logError(e,
          module: 'chat', operation: 'sendMessage', stackTrace: st);
      messenger.showSnackBar(SnackBar(
        content: Text(t.chatSendFailed),
        backgroundColor: const Color(0xFFB42318),
        action: SnackBarAction(
          label: t.retry,
          textColor: Colors.white,
          onPressed: () => _sendMessage(text),
        ),
      ));
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

  void _addReaction(String emoji) async {
    final target = _reactingToMessage;
    if (target == null) return;
    _reactingToMessage = null;
    setState(() {});

    final familyId = await _resolveFamilyId();
    if (familyId == null) return;
    try {
      // Gerçek backend toggle (message_reactions). Realtime ile geri yansır.
      await ChatRepository().toggleReaction(
        messageId: target.id,
        familyId: familyId,
        emoji: emoji,
      );
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'toggleReaction', stackTrace: st);
    }
  }

  /// Yerel dosyayı önce `chat-media` bucket'ına yükler, sonra gerçek mesaj
  /// olarak backend'e insert eder. picked.path ASLA mesaj URL'si yapılmaz.
  Future<void> _sendMedia({
    required File file,
    required String kind, // image | audio | video | file
    required MessageType type,
    required String content,
    int? audioDuration,
    String? fileName,
    int? fileSize,
  }) async {
    setState(() => _showAttachmentMenu = false);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatNoFamily)));
      return;
    }
    messenger.showSnackBar(SnackBar(
        content: Text(t.chatUploading),
        duration: const Duration(seconds: 1)));
    try {
      final url = await ChatStorageService.uploadMedia(
        familyId: familyId,
        file: file,
        kind: kind,
      );
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: content,
        type: type,
        imageUrl: type == MessageType.image ? url : null,
        audioUrl: type == MessageType.audio ? url : null,
        audioDuration: audioDuration,
        videoUrl:
            (type == MessageType.video || type == MessageType.file) ? url : null,
        fileName: fileName,
        fileSize: fileSize,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'sendMedia', stackTrace: st);
      messenger.showSnackBar(SnackBar(
        content: Text(t.chatUploadFailed),
        backgroundColor: const Color(0xFFB42318),
      ));
    }
  }

  Future<void> _pickImage() async {
    final photoLabel = '📷 ${AppLocalizations.of(context).chatPhoto}';
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
    if (picked == null) return;
    await _sendMedia(
      file: File(picked.path),
      kind: 'image',
      type: MessageType.image,
      content: photoLabel,
    );
  }

  Future<void> _takePhoto() async {
    final photoLabel = '📷 ${AppLocalizations.of(context).chatPhoto}';
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 70, maxWidth: 1600);
    if (picked == null) return;
    await _sendMedia(
      file: File(picked.path),
      kind: 'image',
      type: MessageType.image,
      content: photoLabel,
    );
  }

  Future<void> _shareLocation() async {
    setState(() => _showAttachmentMenu = false);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final locationUnavailable = t.locationUnavailable;
    messenger.showSnackBar(SnackBar(
        content: Text(t.chatGettingLocation), duration: const Duration(seconds: 1)));

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      messenger.showSnackBar(SnackBar(content: Text(locationUnavailable)));
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

    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatNoFamily)));
      return;
    }
    try {
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: '📍 $label',
        type: MessageType.location,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'shareLocation', stackTrace: st);
      messenger.showSnackBar(SnackBar(content: Text(t.chatSendFailed)));
    }
  }

  Future<void> _sendVoiceMessage(File file, int durationMs) async {
    final durationSeconds = (durationMs / 1000).round().clamp(1, 9999);
    await _sendMedia(
      file: file,
      kind: 'audio',
      type: MessageType.audio,
      content: '🎤 ${AppLocalizations.of(context).chatVoiceMessage}',
      audioDuration: durationSeconds,
    );
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final size = await file.length();
    final name = picked.path.split('/').last.split('\\').last;
    // 50 MB storage limiti — büyük videoda açık hata (sessiz başarısızlık yok).
    if (size > 50 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).chatFileTooLarge)),
      );
      return;
    }
    await _sendMedia(
      file: file,
      kind: 'video',
      type: MessageType.video,
      content: '🎬 $name',
      fileName: name,
      fileSize: size,
    );
  }

  void _votePoll(ChatMessage msg, int optionIndex) async {
    final poll = msg.poll;
    final myId = _myId;
    if (poll == null || myId == null) return;
    // Not: Anket kalıcılığı henüz backend'e bağlı değil (poll tablosu yok);
    // oy yalnızca yerel gösterilir. Gerçek oy verilene kadar 'm1' yerine
    // gerçek kullanıcı ID'si kullanılır (yanlış "benim oyum" işareti olmaz).
    final updated = poll.toggleVote(optionIndex, myId);
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
                        Text(AppLocalizations.of(context).chatCreatePoll,
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
                      decoration: deco(AppLocalizations.of(context).chatPollQuestion),
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
                                decoration: deco(AppLocalizations.of(context).chatOption(i + 1)),
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
                        label: Text(AppLocalizations.of(context).chatAddOption,
                            style: const TextStyle(color: Color(0xFF8B5CF6))),
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
                        child: Text(AppLocalizations.of(context).chatSendPoll,
                            style: const TextStyle(
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

  Future<void> _sendPoll(String question, List<String> options) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatNoFamily)));
      return;
    }
    try {
      // Anket mesajı + kalıcı anket kaydı (chat_polls, migration 068).
      await ChatRepository().createPoll(
        familyId: familyId,
        question: question,
        options: options,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'sendPoll', stackTrace: st);
      messenger.showSnackBar(SnackBar(content: Text(t.chatSendFailed)));
    }
  }

  Future<void> _pickFile() async {
    setState(() => _showAttachmentMenu = false);
    final t = AppLocalizations.of(context);
    try {
      final XFile? picked = await openFile();
      if (picked == null) return;
      final size = await picked.length();
      if (size > 50 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.chatFileTooLarge)));
        return;
      }
      // Storage'a yükle → imzalı URL. Yerel yol ASLA gönderilmez.
      await _sendMedia(
        file: File(picked.path),
        kind: 'file',
        type: MessageType.file,
        content: '📄 ${picked.name}',
        fileName: picked.name,
        fileSize: size,
      );
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'pickFile', stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.chatFileFailed)));
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context).chatPickGif,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

  Future<void> _sendGif(String gifUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final familyId = await _resolveFamilyId();
    if (familyId == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatNoFamily)));
      return;
    }
    // GIF uzak HTTPS URL'sidir (yerel yol değil) → gerçek mesaj olarak gider,
    // diğer cihazlarda açılır.
    try {
      await ChatRepository().sendMessage(
        familyId: familyId,
        content: '🎭 GIF',
        type: MessageType.gif,
        imageUrl: gifUrl,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'sendGif', stackTrace: st);
      messenger.showSnackBar(SnackBar(content: Text(t.chatSendFailed)));
    }
  }

  void _pinMessage(ChatMessage message) async {
    HapticFeedback.mediumImpact();
    final familyId = await _resolveFamilyId();
    if (familyId == null) return;
    try {
      // Gerçek backend (tek aktif pin). Realtime ile diğer üyelere yansır.
      await ChatRepository().setPinned(
        familyId: familyId,
        messageId: message.id,
        pinned: !message.isPinned,
      );
    } catch (e, st) {
      AppLogger.logError(e,
          module: 'chat', operation: 'pinMessage', stackTrace: st);
    }
  }

  /// Arama sonucundan mesaja yaklaşık konumla kaydırır (best-effort).
  void _scrollToMessage(ChatMessage target) {
    final list = ref.read(chatMessagesProvider);
    final idx = list.indexWhere((m) => m.id == target.id);
    if (idx < 0 || !_scrollController.hasClients) return;
    final frac = list.isEmpty ? 1.0 : idx / list.length;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent * frac,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  /// "Sohbeti temizle" — GÜVENLİ model: yalnızca BU cihazdaki yerel kopyayı
  /// temizler. Aile mesajları backend'de ve diğer üyelerde korunur. Normal
  /// kullanıcının tüm aile geçmişini silmesine izin verilmez (denetim §16).
  Future<void> _clearChatForMe() async {
    final nav = Navigator.of(context);
    final t = AppLocalizations.of(context);
    nav.pop(); // menüyü kapat
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chatClearChat),
        content: Text(t.chatClearForMeDesc),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.chatClearChat)),
        ],
      ),
    );
    if (confirmed != true) return;
    await HiveService.saveChatMessages(const []);
    // Not: realtime stream aktifse mesajlar tekrar yüklenir; bu bilinçli —
    // aile geçmişi silinmez, yalnızca yerel önbellek tazelenir.
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.chatCleared)));
    }
  }

  String _typingLabel(BuildContext context, List<TypingUser> users) {
    final t = AppLocalizations.of(context);
    if (users.length == 1) return t.chatTypingOne(users.first.displayName);
    if (users.length == 2) {
      return t.chatTypingTwo(users[0].displayName, users[1].displayName);
    }
    return t.chatTypingMany;
  }

  String _dayLabel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    if (messageDay == today) return AppLocalizations.of(context).chatToday;
    if (messageDay == yesterday) return AppLocalizations.of(context).chatYesterday;
    return DateFormat('d MMMM', Localizations.localeOf(context).toString()).format(dt);
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
                  Text(
                    AppLocalizations.of(context).chtFamilyChat,
                    style: const TextStyle(
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
                      // Backend UUID'si ile karşılaştır — 'm1' sabiti gerçek
                      // mesajlarda asla eşleşmiyordu, tüm mesajlar yanlış tarafta
                      // görünüyordu.
                      final isMe = msg.senderId == _myId;

                      // Day separator
                      final showDay = index == 0 ||
                          !_sameDay(
                            msg.createdAt,
                            messages[index - 1].createdAt,
                          );

                      return Column(
                        children: [
                          if (showDay)
                            _DaySeparator(label: _dayLabel(context, msg.createdAt)),
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
              // "X yazıyor…" satırı (typing indicator)
              if (_typingUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _typingLabel(context, _typingUsers),
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(160),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Composer
              ChatComposer(
                onSend: _sendMessage,
                onTyping: (_) => _presence?.notifyTyping(_myDisplayName),
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
    if (msg.senderId == _myId) return false;
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
                  label: AppLocalizations.of(context).chatSearchMessages,
                  onTap: () {
                    Navigator.pop(context);
                    showSearch(
                      context: context,
                      delegate: _ChatSearchDelegate(
                        ref.read(chatMessagesProvider),
                        onJump: (m) => _scrollToMessage(m),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: AppLocalizations.of(context).bildirimAyarlari,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.notificationSettings);
                  },
                ),
                // "Sohbeti Arşivle" kaldırıldı: tek aile grup sohbeti için
                // arşiv kullanıcı-bazlı backend state gerektirir (chat_user_states);
                // gerçek davranış hazır olana kadar sahte buton göstermiyoruz.
                _MenuItem(
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context).chatClearChat,
                  isDanger: true,
                  onTap: () => _clearChatForMe(),
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
                          label: AppLocalizations.of(context).chatCamera,
                          onTap: onCamera,
                        ),
                        _AttachmentItem(
                          icon: Icons.photo,
                          color: const Color(0xFF6366F1),
                          label: AppLocalizations.of(context).chatGallery,
                          onTap: onGallery,
                        ),
                        _AttachmentItem(
                          icon: Icons.location_on,
                          color: const Color(0xFF10B981),
                          label: AppLocalizations.of(context).chatLocation,
                          onTap: onLocation,
                        ),
                        _AttachmentItem(
                          icon: Icons.event,
                          color: const Color(0xFFF59E0B),
                          label: AppLocalizations.of(context).chatEvent,
                          onTap: () => context.push(AppRoutes.calendar),
                        ),
                        _AttachmentItem(
                          icon: Icons.poll,
                          color: const Color(0xFF6366F1),
                          label: AppLocalizations.of(context).chatPoll,
                          onTap: onPoll ?? () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.contact_page,
                          color: const Color(0xFFEC4899),
                          label: AppLocalizations.of(context).kisi,
                          onTap: () => context.push(AppRoutes.family),
                        ),
                        _AttachmentItem(
                          icon: Icons.gif_box_outlined,
                          color: AppColors.orange,
                          label: AppLocalizations.of(context).chatGif,
                          onTap: onGif ?? () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.videocam_outlined,
                          color: const Color(0xFF7C3AED),
                          label: AppLocalizations.of(context).chatVideo,
                          onTap: onVideo ?? () {},
                        ),
                        _AttachmentItem(
                          icon: Icons.description,
                          color: const Color(0xFF6B7280),
                          label: AppLocalizations.of(context).chatFile,
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



/// Sohbet içi gerçek arama — yüklü mesajlar üzerinde büyük/küçük harf ve
/// aksan duyarsız (tr/fr/nl/en karakterleri) filtre. Aile izolasyonu zaten
/// mesaj listesinin kendisiyle sağlanır (yalnızca kendi ailenin mesajları).
class _ChatSearchDelegate extends SearchDelegate<ChatMessage?> {
  final List<ChatMessage> messages;
  final void Function(ChatMessage) onJump;
  _ChatSearchDelegate(this.messages, {required this.onJump});

  String _norm(String s) => s.toLowerCase();

  List<ChatMessage> _results() {
    final q = _norm(query.trim());
    if (q.isEmpty) return const [];
    return messages.where((m) => _norm(m.content).contains(q)).toList().reversed.toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _results();
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (results.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).chatNoResults));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final m = results[i];
        return ListTile(
          leading: const Icon(Icons.message_outlined),
          title: Text(m.senderName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(m.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () {
            close(context, m);
            onJump(m);
          },
        );
      },
    );
  }
}
