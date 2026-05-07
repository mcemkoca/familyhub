import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final VoidCallback? onReply;
  final VoidCallback? onReact;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSender = true,
    this.onReply,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // Sender name
        if (!isMe && showSender)
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 2),
            child: Text(
              message.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: message.senderColor,
              ),
            ),
          ),
        // Reply preview
        if (message.replyToId != null)
          _ReplyPreview(
            replyToSender: message.replyToSender ?? '',
            replyToContent: message.replyToContent ?? '',
            isMe: isMe,
          ),
        // Message row
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              _Avatar(color: message.senderColor, name: message.senderName),
            if (!isMe) const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onLongPress: onReact,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.cobalt
                        : (isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? AppColors.cobalt.withAlpha(30)
                            : Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location message
                      if (message.type == MessageType.location)
                        _LocationPreview(content: message.content)
                      else if (message.type == MessageType.audio)
                        _AudioMessagePlayer(
                          audioUrl: message.audioUrl,
                          durationSeconds: message.audioDuration ?? 0,
                          isMe: isMe,
                        )
                      else
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: isMe
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.dark),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Time & ticks
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe
                                  ? Colors.white.withAlpha(180)
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightGray),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _ReadStatus(readCount: message.readCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Reactions
        if (message.reactions.isNotEmpty)
          _ReactionsRow(reactions: message.reactions, isMe: isMe),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Avatar extends StatelessWidget {
  final Color color;
  final String name;

  const _Avatar({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final String replyToSender;
  final String replyToContent;
  final bool isMe;

  const _ReplyPreview({
    required this.replyToSender,
    required this.replyToContent,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 0 : 44,
        right: isMe ? 8 : 0,
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.cobalt.withAlpha(40)
            : (isDark
                  ? AppColors.darkBackground.withAlpha(80)
                  : Colors.white.withAlpha(80)),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AppColors.cobalt, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToSender,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cobalt,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyToContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe
                  ? Colors.white.withAlpha(180)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadStatus extends StatelessWidget {
  final int readCount;

  const _ReadStatus({required this.readCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          readCount > 0 ? Icons.done_all : Icons.done,
          size: 14,
          color: Colors.white.withAlpha(200),
        ),
        if (readCount > 1)
          Container(
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$readCount',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final List<MessageReaction> reactions;
  final bool isMe;

  const _ReactionsRow({required this.reactions, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 44,
        right: isMe ? 8 : 0,
        bottom: 8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((r) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  '${r.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String? audioUrl;
  final int durationSeconds;
  final bool isMe;

  const _AudioMessagePlayer({
    this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int _currentPosition = 0;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos.inSeconds);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (widget.audioUrl == null) return;
      final source = widget.audioUrl!.startsWith('http')
          ? UrlSource(widget.audioUrl!)
          : DeviceFileSource(widget.audioUrl!);
      await _player.play(source);
      setState(() => _isPlaying = true);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayDuration = _isPlaying
        ? _currentPosition
        : widget.durationSeconds;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withAlpha(30)
                  : AppColors.cobalt.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe ? Colors.white : AppColors.cobalt,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withAlpha(80)
                    : AppColors.cobalt.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.durationSeconds > 0
                    ? (displayDuration / widget.durationSeconds).clamp(0.0, 1.0)
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isMe ? Colors.white : AppColors.cobalt,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(displayDuration),
              style: TextStyle(
                fontSize: 11,
                color: widget.isMe
                    ? Colors.white.withAlpha(180)
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightGray),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationPreview extends StatelessWidget {
  final String content;

  const _LocationPreview({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.map, size: 40, color: Color(0xFFBAE6FD)),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cobalt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Haritada Göster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}
