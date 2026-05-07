class ChildSession {
  final String token;
  final DateTime expiresAt;
  final String childName;
  final String childRole;
  final String familyId;
  final String childId;

  const ChildSession({
    required this.token,
    required this.expiresAt,
    required this.childName,
    required this.childRole,
    required this.familyId,
    required this.childId,
  });

  factory ChildSession.fromJson(Map<String, dynamic> json) {
    return ChildSession(
      token: json['session_token'] as String? ?? json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      childName: json['child_name'] as String,
      childRole: json['child_role'] as String,
      familyId: json['family_id'] as String,
      childId: json['child_id'] as String? ?? '',
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'child_name': childName,
        'child_role': childRole,
        'family_id': familyId,
        'child_id': childId,
      };
}
