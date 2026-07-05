import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/permission_service.dart';
import '../../../services/voice_message_service.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text) onSend;
  final Function(File file, int durationMs)? onSendVoice;
  final VoidCallback onAttachment;
  final VoidCallback onEmoji;
  final Function(String)? onTyping;
  final VoidCallback? onCancelReply;
  final String? replyToSender;
  final String? replyToContent;

  const ChatComposer({
    super.key,
    required this.onSend,
    this.onSendVoice,
    required this.onAttachment,
    required this.onEmoji,
    this.onTyping,
    this.onCancelReply,
    this.replyToSender,
    this.replyToContent,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _sendAnimController;
  bool _hasText = false;
  bool _isRecording = false;
  List<double> _amplitudes = [];
  int _recordDuration = 0;
  Timer? _recordTimer;
  StreamSubscription<dynamic>? _amplitudeSub;

  @override
  void initState() {
    super.initState();
    _sendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onTyping?.call(_controller.text);
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _sendAnimController.forward().then((_) => _sendAnimController.reverse());
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _startRecording() async {
    if (_hasText) return;
    final granted = await PermissionService.requestMicrophone(context);
    if (!granted) return;
    try {
      await VoiceMessageService.startRecording();
      setState(() {
        _isRecording = true;
        _amplitudes = [];
        _recordDuration = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordDuration++);
      });
      _amplitudeSub = VoiceMessageService.amplitudeStream.listen((amp) {
        if (mounted && _isRecording) {
          setState(() {
            _amplitudes.add(amp);
            if (_amplitudes.length > 40) _amplitudes.removeAt(0);
          });
        }
      });
    } catch (e) {
      debugPrint('Chat composer init error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final result = await VoiceMessageService.stopRecording();
    setState(() {
      _isRecording = false;
      _amplitudes = [];
      _recordDuration = 0;
    });
    if (result != null && widget.onSendVoice != null) {
      widget.onSendVoice!(result.file, result.durationMs);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    await VoiceMessageService.cancelRecording();
    setState(() {
      _isRecording = false;
      _amplitudes = [];
      _recordDuration = 0;
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _sendAnimController.dispose();
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(
          top: BorderSide(color: Color(0x1EFFFFFF), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyToSender != null && !_isRecording)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0x0DFFFFFF),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.replyToSender!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.replyToContent ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancelReply,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            // Recording UI
            if (_isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordDuration),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: _amplitudes.isEmpty
                            ? const Center(child: Text('Kaydediliyor...'))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _amplitudes.map((amp) {
                                  return Container(
                                    width: 3,
                                    height: 8 + (amp * 24),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelRecording,
                      child: const Text('İptal', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              )
            else
              // Input row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment
                    IconButton(
                      onPressed: widget.onAttachment,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF6366F1),
                        size: 28,
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          border: Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Mesaj yaz...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFE5E7EB),
                                ),
                                onSubmitted: (_) => _handleSend(),
                              ),
                            ),
                            // Emoji
                            IconButton(
                              onPressed: widget.onEmoji,
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Send / Mic
                    AnimatedBuilder(
                      animation: _sendAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 - (_sendAnimController.value * 0.15),
                          child: GestureDetector(
                            onTap: _hasText ? _handleSend : null,
                            onLongPressStart: _hasText ? null : (_) => _startRecording(),
                            onLongPressEnd: _hasText ? null : (_) => _stopRecording(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _hasText
                                    ? const Color(0xFF6366F1)
                                    : const Color(0x1AFFFFFF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _hasText ? Icons.send : Icons.mic_none,
                                color: _hasText ? Colors.white : const Color(0xFF6B7280),
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
