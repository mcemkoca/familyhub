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
      id: map['id'] ?? '',
      fullName: map['display_name'] ?? map['full_name'],
      avatarUrl: map['avatar_url'],
      role: map['role'] ?? 'member',
      familyId: map['family_id'],
      isPremium: map['is_premium'] ?? false,
      premiumExpiry: map['premium_expires_at'] != null
          ? DateTime.tryParse(map['premium_expires_at'].toString())
          : null,
      familyName: map['families']?['name'],
      xp: map['xp'] ?? 0,
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
