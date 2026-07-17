import 'dart:async';
import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities.dart';
import '../../../services/auth_service.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final void Function(int optionIndex)? onVote;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSender = true,
    this.onReply,
    this.onReact,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
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
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF6366F1)
                        : const Color(0x1AFFFFFF),
                    border: isMe ? null : Border.all(color: const Color(0x1EFFFFFF), width: 0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? const Color(0xFF6366F1).withAlpha(50)
                            : Colors.black.withAlpha(20),
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
                        _LocationPreview(
                            content: message.content,
                            latitude: message.latitude,
                            longitude: message.longitude)
                      else if (message.type == MessageType.audio)
                        _AudioMessagePlayer(
                          audioUrl: message.audioUrl,
                          durationSeconds: message.audioDuration ?? 0,
                          isMe: isMe,
                        )
                      else if (message.type == MessageType.image && message.imageUrl != null)
                        _ImagePreview(imageUrl: message.imageUrl!, isMe: isMe)
                      else if (message.type == MessageType.gif && message.imageUrl != null)
                        _GifPreview(gifUrl: message.imageUrl!, isMe: isMe)
                      else if (message.type == MessageType.video)
                        _VideoPreview(
                          videoUrl: message.videoUrl ?? message.imageUrl,
                          fileName: message.fileName ?? '🎬 Video',
                          isMe: isMe,
                        )
                      else if (message.type == MessageType.file)
                        _FilePreview(
                          fileName: message.fileName ?? 'Dosya',
                          fileSize: message.fileSize,
                          isMe: isMe,
                        )
                      else if (message.type == MessageType.poll &&
                          message.poll != null)
                        _PollCard(
                          poll: message.poll!,
                          isMe: isMe,
                          currentUserId: AuthService.currentUserId ?? '',
                          onVote: onVote,
                        )
                      else
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: isMe
                                ? Colors.white.withAlpha(220)
                                : Theme.of(context).colorScheme.onSurface,
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
                                  ? Colors.white.withAlpha(120)
                                  : Theme.of(context).colorScheme.onSurface.withAlpha(120),
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
            ? const Color(0xFF6366F1).withAlpha(40)
            : (isDark
                  ? const Color(0xFF0A0A0F).withAlpha(80)
                  : Colors.white.withAlpha(80)),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToSender,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
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
                  : (const Color(0xFF6B7280)),
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
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x1EFFFFFF),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  int _currentPosition = 0;
  StreamSubscription<dynamic>? _positionSub;
  StreamSubscription<dynamic>? _completeSub;

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
                  : const Color(0xFF6366F1).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
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
                    : const Color(0xFF6366F1).withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.durationSeconds > 0
                    ? (displayDuration / widget.durationSeconds).clamp(0.0, 1.0)
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
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
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF)),
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
  final double? latitude;
  final double? longitude;

  const _LocationPreview(
      {required this.content, this.latitude, this.longitude});

  Future<void> _openMap() async {
    if (latitude == null || longitude == null) return;
    final geo = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    final web = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasCoords ? _openMap : null,
          child: Container(
            height: 100,
            width: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.location_on, size: 40, color: Color(0xFF6366F1)),
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasCoords
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6366F1).withAlpha(120),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasCoords ? 'Haritada Göster' : 'Konum',
                      style: const TextStyle(
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

// ─── Image Preview ────────────────────────────────────────────────────────────
class _ImagePreview extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  const _ImagePreview({required this.imageUrl, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isNetwork
          ? Image.network(imageUrl, width: 220, height: 160, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder('📷'))
          : Image.asset(imageUrl, width: 220, height: 160, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder('📷')),
    );
  }

  Widget _placeholder(String label) => Container(
        width: 220, height: 120, color: Colors.black26,
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 20))),
      );
}

// ─── GIF Preview ─────────────────────────────────────────────────────────────
class _GifPreview extends StatelessWidget {
  final String gifUrl;
  final bool isMe;
  const _GifPreview({required this.gifUrl, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(gifUrl, width: 220, height: 160, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 220, height: 120, color: Colors.black26,
              child: Center(child: Text(AppLocalizations.of(context).chatGif, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
          child: Text(AppLocalizations.of(context).chatGif, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─── Video Preview ────────────────────────────────────────────────────────────
class _VideoPreview extends StatelessWidget {
  final String? videoUrl;
  final String fileName;
  final bool isMe;
  const _VideoPreview({this.videoUrl, required this.fileName, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, height: 120,
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
          Positioned(
            bottom: 8, left: 8, right: 8,
            child: Text(fileName, style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── File Preview ─────────────────────────────────────────────────────────────
class _FilePreview extends StatelessWidget {
  final String fileName;
  final int? fileSize;
  final bool isMe;
  const _FilePreview({required this.fileName, this.fileSize, required this.isMe});

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Icons.audio_file;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.video_file;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : const Color(0xFF6366F1).withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_fileIcon(fileName), size: 28, color: isMe ? Colors.white : const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fileName, style: TextStyle(color: isMe ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              if (fileSize != null)
                Text(_formatSize(fileSize), style: TextStyle(color: isMe ? Colors.white70 : null, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sohbet içi anket kartı — dokununca oy verir, yüzde çubuklarını gösterir.
class _PollCard extends StatelessWidget {
  final PollData poll;
  final bool isMe;
  final String currentUserId;
  final void Function(int optionIndex)? onVote;

  const _PollCard({
    required this.poll,
    required this.isMe,
    required this.currentUserId,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final total = poll.totalVotes;
    final voted = poll.hasVoted(currentUserId);
    final onColor = isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final accent = isMe ? Colors.white : const Color(0xFF8B5CF6);

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).chatPoll,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: accent)),
            ],
          ),
          const SizedBox(height: 6),
          Text(poll.question,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: onColor)),
          const SizedBox(height: 10),
          for (int i = 0; i < poll.options.length; i++)
            _option(context, i, total, voted, onColor, accent),
          const SizedBox(height: 2),
          Text(
            total == 0 ? 'Henüz oy yok' : '$total oy',
            style: TextStyle(
                fontSize: 11,
                color: onColor.withAlpha(150),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, int i, int total, bool voted,
      Color onColor, Color accent) {
    final count = poll.votes[i].length;
    final pct = total == 0 ? 0.0 : count / total;
    final mine = poll.votes[i].contains(currentUserId);
    final fill = isMe ? Colors.white.withAlpha(40) : accent.withAlpha(38);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onVote == null ? null : () => onVote!(i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: voted ? pct.clamp(0.0, 1.0) : 0.0,
                  child: Container(color: fill),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mine ? accent : onColor.withAlpha(45),
                    width: mine ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mine
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: mine ? accent : onColor.withAlpha(120),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(poll.options[i],
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  mine ? FontWeight.w700 : FontWeight.w500,
                              color: onColor)),
                    ),
                    if (voted) ...[
                      const SizedBox(width: 8),
                      Text('${(pct * 100).round()}%',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: onColor.withAlpha(200))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
