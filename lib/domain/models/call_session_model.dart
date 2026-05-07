enum CallStatus {
  ringing,
  connected,
  ended,
  rejected,
  missed,
  busy,
}

class CallSession {
  final String id;
  final String familyId;
  final String callerId;
  final String calleeId;
  final String agoraChannelName;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final DateTime? callerJoinedAt;
  final DateTime? calleeJoinedAt;
  final DateTime createdAt;

  // UI için ek alanlar (veritabanında yok)
  final String? callerName;
  final String? callerAvatar;
  final String? calleeName;
  final String? calleeAvatar;

  CallSession({
    required this.id,
    required this.familyId,
    required this.callerId,
    required this.calleeId,
    required this.agoraChannelName,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.callerJoinedAt,
    this.calleeJoinedAt,
    required this.createdAt,
    this.callerName,
    this.callerAvatar,
    this.calleeName,
    this.calleeAvatar,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      callerId: json['caller_id'] as String,
      calleeId: json['callee_id'] as String,
      agoraChannelName: json['agora_channel_name'] as String,
      status: CallStatus.values.byName(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      callerJoinedAt: json['caller_joined_at'] != null
          ? DateTime.parse(json['caller_joined_at'] as String)
          : null,
      calleeJoinedAt: json['callee_joined_at'] != null
          ? DateTime.parse(json['callee_joined_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      callerName: json['caller_name'] as String?,
      callerAvatar: json['caller_avatar'] as String?,
      calleeName: json['callee_name'] as String?,
      calleeAvatar: json['callee_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'caller_id': callerId,
      'callee_id': calleeId,
      'agora_channel_name': agoraChannelName,
      'status': status.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'caller_joined_at': callerJoinedAt?.toIso8601String(),
      'callee_joined_at': calleeJoinedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallSession copyWith({
    String? id,
    String? familyId,
    String? callerId,
    String? calleeId,
    String? agoraChannelName,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    DateTime? callerJoinedAt,
    DateTime? calleeJoinedAt,
    DateTime? createdAt,
    String? callerName,
    String? callerAvatar,
    String? calleeName,
    String? calleeAvatar,
  }) {
    return CallSession(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      callerJoinedAt: callerJoinedAt ?? this.callerJoinedAt,
      calleeJoinedAt: calleeJoinedAt ?? this.calleeJoinedAt,
      createdAt: createdAt ?? this.createdAt,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      calleeName: calleeName ?? this.calleeName,
      calleeAvatar: calleeAvatar ?? this.calleeAvatar,
    );
  }
}
