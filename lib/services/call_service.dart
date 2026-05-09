import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/supabase_client.dart';
import '../domain/models/call_session_model.dart';
import 'auth_service.dart';

class CallService {
  static RTCPeerConnection? _peerConnection;
  static MediaStream? _localStream;
  static StreamSubscription<dynamic>? _incomingSub;
  static StreamSubscription<dynamic>? _signalingSub;
  static final StreamController<CallSession> _incomingController =
      StreamController<CallSession>.broadcast();
  static final StreamController<bool> _remoteJoinedController =
      StreamController<bool>.broadcast();

  static Stream<CallSession> get incomingCallStream =>
      _incomingController.stream;
  static Stream<bool> get remoteUserJoinedStream =>
      _remoteJoinedController.stream;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  static String? _currentSessionId;

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<RTCPeerConnection> _createPeerConnection() async {
    final pc = await createPeerConnection(_iceServers);

    pc.onIceCandidate = (candidate) {
      _sendSignalingMessage('ice_candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onTrack = (event) {
      _remoteJoinedController.add(true);
    };

    pc.onConnectionState = (state) {
      if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _remoteJoinedController.add(true);
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _remoteJoinedController.add(false);
      }
    };

    return pc;
  }

  static Future<void> _getUserMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  static Future<void> _sendSignalingMessage(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final client = SupabaseConfig.safeClient;
    final sessionId = _currentSessionId;
    final userId = AuthService.currentUserId;
    if (client == null || sessionId == null || userId == null) return;

    await client.from('call_signaling').insert({
      'session_id': sessionId,
      'sender_id': userId,
      'type': type,
      'payload': payload,
    });
  }

  static void startListeningIncomingCalls() {
    stopListeningIncomingCalls();

    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    _incomingSub = client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('callee_id', userId)
        .listen(
      (data) {
        for (final row in data) {
          final session = CallSession.fromJson(row);
          if (session.status == CallStatus.ringing) {
            _incomingController.add(session);
          }
        }
      },
      onError: (e) => debugPrint('CallService incoming stream error: $e'),
    );
  }

  static void stopListeningIncomingCalls() {
    _incomingSub?.cancel();
    _incomingSub = null;
  }

  static Future<CallSession?> startCall({
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
  }) async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return null;

    final micGranted = await requestMicrophonePermission();
    if (!micGranted) {
      throw CallException('Mikrofon izni gereklidir');
    }

    // Find family_id
    String? familyId;
    try {
      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      familyId = profile?['family_id'] as String?;
    } catch (_) {}

    if (familyId == null || familyId.isEmpty) {
      throw CallException('Aile bilgisi bulunamadı');
    }

    // Create call session
    final response = await client
        .from('call_sessions')
        .insert({
          'family_id': familyId,
          'caller_id': userId,
          'callee_id': calleeId,
          'agora_channel_name': '',
          'status': 'ringing',
        })
        .select()
        .single();

    final session = CallSession.fromJson(response);
    _currentSessionId = session.id;

    // Setup WebRTC
    await _getUserMedia();
    _peerConnection = await _createPeerConnection();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer via signaling
    await _sendSignalingMessage('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });

    // Listen for answer and ICE candidates
    _listenSignaling(session.id);

    return session.copyWith(
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
    );
  }

  static Future<CallSession?> acceptCall(CallSession session) async {
    final client = SupabaseConfig.safeClient;
    if (client == null) return null;

    final micGranted = await requestMicrophonePermission();
    if (!micGranted) {
      throw CallException('Mikrofon izni gereklidir');
    }

    _currentSessionId = session.id;

    // Setup WebRTC
    await _getUserMedia();
    _peerConnection = await _createPeerConnection();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Listen for offer and ICE candidates
    _listenSignalingForCallee(session.id);

    // Update status
    final response = await client
        .from('call_sessions')
        .update({
          'status': 'connected',
          'callee_joined_at': DateTime.now().toIso8601String(),
        })
        .eq('id', session.id)
        .select()
        .single();

    return CallSession.fromJson(response);
  }

  static void _listenSignaling(String sessionId) {
    _signalingSub?.cancel();
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    _signalingSub = client
        .from('call_signaling')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen(
      (data) async {
        if (_peerConnection == null) return;
        for (final row in data) {
          final senderId = row['sender_id'] as String;
          final type = row['type'] as String;
          final payload = row['payload'] as Map<String, dynamic>;

          // Ignore own messages
          if (senderId == AuthService.currentUserId) continue;

          if (type == 'answer') {
            final answer = RTCSessionDescription(
              payload['sdp'] as String,
              payload['type'] as String,
            );
            await _peerConnection!.setRemoteDescription(answer);
          } else if (type == 'ice_candidate') {
            final candidate = RTCIceCandidate(
              payload['candidate'] as String,
              payload['sdpMid'] as String,
              payload['sdpMLineIndex'] as int,
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      },
      onError: (e) => debugPrint('CallService signaling error: $e'),
    );
  }

  static void _listenSignalingForCallee(String sessionId) {
    _signalingSub?.cancel();
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    _signalingSub = client
        .from('call_signaling')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen(
      (data) async {
        if (_peerConnection == null) return;
        for (final row in data) {
          final senderId = row['sender_id'] as String;
          final type = row['type'] as String;
          final payload = row['payload'] as Map<String, dynamic>;

          // Ignore own messages
          if (senderId == AuthService.currentUserId) continue;

          if (type == 'offer') {
            final offer = RTCSessionDescription(
              payload['sdp'] as String,
              payload['type'] as String,
            );
            await _peerConnection!.setRemoteDescription(offer);

            final answer = await _peerConnection!.createAnswer();
            await _peerConnection!.setLocalDescription(answer);

            await _sendSignalingMessage('answer', {
              'sdp': answer.sdp,
              'type': answer.type,
            });
          } else if (type == 'ice_candidate') {
            final candidate = RTCIceCandidate(
              payload['candidate'] as String,
              payload['sdpMid'] as String,
              payload['sdpMLineIndex'] as int,
            );
            await _peerConnection!.addCandidate(candidate);
          }
        }
      },
      onError: (e) => debugPrint('CallService signaling error: $e'),
    );
  }

  static Future<void> endCall(String sessionId, {bool reject = false}) async {
    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    _signalingSub?.cancel();
    _signalingSub = null;

    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
      _localStream = null;
      await _peerConnection?.close();
      _peerConnection = null;
    } catch (e) {
      // ignore: empty_catches
    }

    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'status': reject ? 'rejected' : 'ended',
      'ended_at': now,
    };

    // Calculate duration
    try {
      final row = await client
          .from('call_sessions')
          .select('caller_joined_at, callee_joined_at, started_at')
          .eq('id', sessionId)
          .single();

      final callerJoined = row['caller_joined_at'] != null
          ? DateTime.parse(row['caller_joined_at'] as String)
          : null;
      final calleeJoined = row['callee_joined_at'] != null
          ? DateTime.parse(row['callee_joined_at'] as String)
          : null;

      if (callerJoined != null && calleeJoined != null) {
        final connectedAt = callerJoined.isAfter(calleeJoined)
            ? callerJoined
            : calleeJoined;
        final duration = DateTime.now().difference(connectedAt).inSeconds;
        updates['duration_seconds'] = duration;
      }
    } catch (_) {}

    await client.from('call_sessions').update(updates).eq('id', sessionId);
    _currentSessionId = null;
  }

  static Future<void> toggleMute(bool muted) async {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !muted;
    });
  }

  static Future<void> toggleSpeaker(bool speakerOn) async {
    // flutter_webrtc'de doğrudan speakerphone API'sı yok.
  }

  static Future<void> dispose() async {
    stopListeningIncomingCalls();
    _signalingSub?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
  }

  static bool get isConfigured => true;
}

class CallException implements Exception {
  final String message;
  CallException(this.message);

  @override
  String toString() => message;
}
