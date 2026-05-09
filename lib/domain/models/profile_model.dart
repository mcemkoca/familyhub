class ProfileModel {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String role; // 'admin' | 'member' | 'child'
  final String? familyId;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final String? familyName;
  final int xp;
  final List<String> badges;

  ProfileModel({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.role,
    this.familyId,
    required this.isPremium,
    this.premiumExpiry,
    this.familyName,
    this.xp = 0,
    this.badges = const [],
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: (map['id'] as String?) ?? '',
      fullName: (map['display_name'] as String?) ?? (map['full_name'] as String?),
      avatarUrl: map['avatar_url'] as String?,
      role: (map['role'] as String?) ?? 'member',
      familyId: map['family_id'] as String?,
      isPremium: (map['is_premium'] as bool?) ?? false,
      premiumExpiry: map['premium_expires_at'] != null
          ? DateTime.tryParse(map['premium_expires_at'].toString())
          : null,
      familyName: (map['families'] as Map<String, dynamic>?)?['name'] as String?,
      xp: (map['xp'] as int?) ?? 0,
      badges: (map['badges'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  String get displayName => fullName ?? 'Kullanıcı';

  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Aile Yöneticisi';
      case 'member':
      case 'parent':
        return 'Aile Üyesi';
      case 'child':
        return 'Çocuk Hesabı';
      default:
        return 'Üye';
    }
  }

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiry == null) return true;
    return premiumExpiry!.isAfter(DateTime.now());
  }
}
