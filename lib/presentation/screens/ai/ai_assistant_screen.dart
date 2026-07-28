import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../services/ai/ai_assistant_service.dart';
import '../../../features/familyhub_ai/domain/ai_suggestion.dart';
import '../../../features/familyhub_ai/data/ai_suggestion_repository.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<AssistantAction> actions;
  final DateTime timestamp;
  final bool hasErrors;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions = const [],
    this.hasErrors = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <_ChatMessage>[];
  bool _isLoading = false;

  /// Öneriye dokununca DOĞRUDAN göndermez — input'a aktarır, imleci sona alır
  /// ve klavyeyi açar; kullanıcı düzenleyip gönderir.
  void _fillInput(String text) {
    HapticFeedback.selectionClick();
    _controller.text = text;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _focusNode.requestFocus();
    setState(() {});
  }

  // Sistem önerileri — STABLE id (sys_N). Metin içerik olduğundan TR kalır.
  static const _systemSuggestions = <AISuggestion>[
    AISuggestion(id: 'sys_0', isSystem: true, text: 'Bu hafta 4 kişilik ekonomik yemek planı yap, eksik malzemeleri alışveriş listeme ekle, bütçeyi 60 euro altında tut.'),
    AISuggestion(id: 'sys_1', isSystem: true, text: 'Pazartesi akşamı için kolay bir tarif öner ve malzemeleri listeye ekle.'),
    AISuggestion(id: 'sys_2', isSystem: true, text: 'Bu ayki harcamalarımı analiz et ve tasarruf önerileri sun.'),
    AISuggestion(id: 'sys_3', isSystem: true, text: 'Yarın için sağlıklı kahvaltı seçenekleri öner.'),
  ];

  final _sugRepo = AISuggestionRepository.instance;

  /// Sistem + özel önerileri birleştirip çözer (gizli çıkar, pinned öne).
  List<AISuggestion> _resolvedSuggestions() => AISuggestionResolver.resolve(
        system: _systemSuggestions,
        custom: _sugRepo.customSuggestions(),
        hiddenSystemIds: _sugRepo.hiddenSystemIds(),
        pinnedIds: _sugRepo.pinnedIds(),
      );

  /// Öneri uzun basıldığında yönetim menüsü (sabitle/düzenle/sil/gizle).
  Future<void> _suggestionMenu(AISuggestion s) async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(s.isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
                color: const Color(0xFF8B5CF6)),
            title: Text(s.isPinned ? t.fhaUnpin : t.fhaPin,
                style: const TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              await _sugRepo.togglePin(s.id);
              setState(() {});
            },
          ),
          if (!s.isSystem) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFF10B981)),
              title: Text(t.fhaEditSuggestion,
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _suggestionDialog(existing: s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              title: Text(t.fhaDeleteSuggestion,
                  style: const TextStyle(color: Color(0xFFF87171))),
              onTap: () async {
                Navigator.pop(ctx);
                await _sugRepo.deleteCustom(s.id);
                setState(() {});
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined,
                  color: Color(0xFF9CA3AF)),
              title: Text(t.fhaHideSuggestion,
                  style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _sugRepo.hideSystem(s.id);
                setState(() {});
              },
            ),
        ]),
      ),
    );
  }

  /// Özel öneri ekle/düzenle dialogu.
  Future<void> _suggestionDialog({AISuggestion? existing}) async {
    final t = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: existing?.text ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            existing == null ? t.fhaAddSuggestion : t.fhaEditSuggestion,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t.fhaSuggestionHint,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.fhaCancel,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.fhaConfirm),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    if (existing == null) {
      await _sugRepo.addCustom(text);
    } else {
      await _sugRepo.editCustom(existing.id, text);
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  void _addWelcome() {
    _messages.add(_ChatMessage(
      text: 'Merhaba! Ben FamilyHub AI Asistanınım.\n\nYemek planı yapabilir, alışveriş listenizi düzenleyebilir ve bütçenizi takip edebilirim. Tek komutla birden fazla işlemi birlikte yapabilirim.',
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _controller.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final result = await AIAssistantService.instance.processCommand(trimmed);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(
        text: result.assistantReply,
        isUser: false,
        actions: result.actions,
        hasErrors: result.hasErrors,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).aiaTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(AppLocalizations.of(context).aiaSub, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingIndicator();
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          // Öneriler input'un HEMEN ÜSTÜNDE (klavye açıkken de görünür,
          // mesajları örtmez). Yalnızca input boşken göster — dağıtmaz.
          if (_controller.text.trim().isEmpty && !_isLoading)
            _buildSuggestionChips(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = _resolvedSuggestions();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: suggestions.length + 1, // +1 = "özel öneri ekle"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // Son öğe: özel öneri ekle chip'i.
          if (i == suggestions.length) {
            return GestureDetector(
              onTap: () => _suggestionDialog(),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x1A8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x338B5CF6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context).fhaAddSuggestion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8B5CF6))),
                  ],
                ),
              ),
            );
          }
          final s = suggestions[i];
          return GestureDetector(
            onTap: () => _fillInput(s.text),
            onLongPress: () => _suggestionMenu(s),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: s.isPinned
                        ? const Color(0x558B5CF6)
                        : const Color(0x1EFFFFFF),
                    width: s.isPinned ? 1 : 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (s.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin,
                            size: 11, color: Color(0xFF8B5CF6)),
                      ),
                    if (!s.isSystem)
                      const Icon(Icons.person_outline,
                          size: 11, color: Color(0xFF10B981)),
                  ]),
                  Expanded(
                    child: Text(
                      s.text,
                      maxLines: s.isPinned || !s.isSystem ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!msg.isUser)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isUser ? const Color(0xFF6366F1) : const Color(0xFF13131A),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: msg.isUser ? null : Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isUser ? Colors.white : const Color(0xFFE5E7EB),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (msg.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...msg.actions.map((a) => _buildActionCard(a)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(AssistantAction action) {
    return Container(
      margin: const EdgeInsets.only(left: 36, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: action.success ? const Color(0xFF10B981).withAlpha(20) : const Color(0xFFEF4444).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: action.success ? const Color(0xFF10B981).withAlpha(60) : const Color(0xFFEF4444).withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            action.success ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: action.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: action.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                if (action.detail != null)
                  Text(
                    action.detail!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
            ),
            child: const SizedBox(width: 40, height: 16, child: _TypingDots()),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(top: BorderSide(color: Color(0x1EFFFFFF), width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    // Yazdıkça öneri panelinin görünürlüğü güncellensin.
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).aiaHint,
                      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _isLoading ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    color: _isLoading ? const Color(0xFF374151) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (1 - (value * 2 - 1).abs()).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Color.fromARGB((opacity * 255).round(), 99, 102, 241),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
