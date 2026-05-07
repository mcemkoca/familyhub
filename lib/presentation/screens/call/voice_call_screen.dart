import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/models/call_session_model.dart';
import '../../../services/call_service.dart';
import '../../../core/supabase_client.dart';

enum VoiceCallMode {
  outgoing,
  incoming,
  connected,
  ending,
}

class VoiceCallScreen extends StatefulWidget {
  final CallSession? session;
  final VoiceCallMode initialMode;

  const VoiceCallScreen({
    super.key,
    this.session,
    this.initialMode = VoiceCallMode.outgoing,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  VoiceCallMode _mode = VoiceCallMode.outgoing;
  CallSession? _session;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _remoteJoined = false;
  Timer? _durationTimer;
  int _durationSeconds = 0;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _remoteUserSubscription;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _session = widget.session;

    if (_mode == VoiceCallMode.incoming) {
      HapticFeedback.heavyImpact();
    }

    _listenRemoteUser();
    _listenSessionStatus();
  }

  void _listenRemoteUser() {
    _remoteUserSubscription = CallService.remoteUserJoinedStream.listen(
      (joined) {
        if (!mounted) return;
        setState(() => _remoteJoined = joined);
        if (joined && _mode != VoiceCallMode.connected) {
          _transitionToConnected();
        }
      },
    );
  }

  void _listenSessionStatus() {
    if (_session == null) return;
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    _statusSubscription = client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', _session!.id)
        .listen(
      (data) {
        if (data.isEmpty || !mounted) return;
        final updated = CallSession.fromJson(data.first);
        final status = updated.status;

        if (status == CallStatus.rejected ||
            status == CallStatus.ended ||
            status == CallStatus.missed) {
          _endAndPop(status == CallStatus.rejected
              ? 'Arama reddedildi'
              : 'Arama sonlandırıldı');
        } else if (status == CallStatus.connected &&
            _mode != VoiceCallMode.connected) {
          _transitionToConnected();
        }
      },
      onError: (_) {},
    );
  }

  void _transitionToConnected() {
    if (!mounted) return;
    setState(() => _mode = VoiceCallMode.connected);
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _durationSeconds++);
      }
    });
  }

  void _endAndPop(String? message) {
    _durationTimer?.cancel();
    _statusSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    if (mounted) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _acceptCall() async {
    if (_session == null) return;
    try {
      final accepted = await CallService.acceptCall(_session!);
      if (accepted != null && mounted) {
        setState(() {
          _session = accepted;
          _mode = VoiceCallMode.connected;
        });
        _transitionToConnected();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama kabul edilemedi: $e')),
        );
      }
    }
  }

  Future<void> _rejectCall() async {
    if (_session == null) return;
    await CallService.endCall(_session!.id, reject: true);
    _endAndPop(null);
  }

  Future<void> _endCall() async {
    if (_session == null) return;
    await CallService.endCall(_session!.id);
    _endAndPop(null);
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await CallService.toggleMute(_isMuted);
    if (mounted) setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await CallService.toggleSpeaker(_isSpeakerOn);
    if (mounted) setState(() {});
  }

  String get _displayName {
    if (_mode == VoiceCallMode.outgoing) {
      return _session?.calleeName ?? 'Aile Üyesi';
    }
    return _session?.callerName ?? 'Aile Üyesi';
  }

  String? get _avatarUrl {
    if (_mode == VoiceCallMode.outgoing) {
      return _session?.calleeAvatar;
    }
    return _session?.callerAvatar;
  }

  String get _statusText {
    switch (_mode) {
      case VoiceCallMode.outgoing:
        return _remoteJoined ? 'Bağlanıyor...' : 'Çalıyor...';
      case VoiceCallMode.incoming:
        return 'Gelen Arama';
      case VoiceCallMode.connected:
        return _formatDuration(_durationSeconds);
      case VoiceCallMode.ending:
        return 'Sonlandırılıyor...';
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    // Ensure call is ended if user navigates away unexpectedly
    if (_session != null &&
        (_mode == VoiceCallMode.outgoing || _mode == VoiceCallMode.connected)) {
      CallService.endCall(_session!.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Avatar
            _buildAvatar(),
            const SizedBox(height: 24),
            // Name
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Status
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 16,
                color: _mode == VoiceCallMode.connected
                    ? AppColors.green
                    : Colors.white70,
              ),
            ),
            const Spacer(),
            // Controls
            _buildControls(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_avatarUrl!),
        backgroundColor: AppColors.darkCard,
      );
    }
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.cobalt,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_mode == VoiceCallMode.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _roundButton(
            icon: Icons.call_end,
            color: AppColors.error,
            label: 'Reddet',
            onTap: _rejectCall,
          ),
          _roundButton(
            icon: Icons.call,
            color: AppColors.green,
            label: 'Kabul Et',
            onTap: _acceptCall,
          ),
        ],
      );
    }

    if (_mode == VoiceCallMode.outgoing) {
      return _roundButton(
        icon: Icons.call_end,
        color: AppColors.error,
        label: 'İptal Et',
        size: 72,
        onTap: _endCall,
      );
    }

    // Connected
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: _isMuted ? AppColors.error : Colors.white24,
          iconColor: _isMuted ? Colors.white : Colors.white,
          label: _isMuted ? 'Sessiz' : 'Sesi Aç',
          onTap: _toggleMute,
        ),
        _roundButton(
          icon: Icons.call_end,
          color: AppColors.error,
          label: 'Kapat',
          size: 72,
          onTap: _endCall,
        ),
        _roundButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          color: _isSpeakerOn ? AppColors.cobalt : Colors.white24,
          iconColor: _isSpeakerOn ? Colors.white : Colors.white,
          label: _isSpeakerOn ? 'Hoparlör' : 'Kulaklık',
          onTap: _toggleSpeaker,
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    double size = 64,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: size * 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
