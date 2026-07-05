import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';

class MemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isMe;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleConfig = _roleConfig(member.role);
    final statusText = member.isOnline
        ? 'Çevrimiçi'
        : _formatLastSeen(member.lastSeen);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: member.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      member.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: member.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF13131A),
                        width: 2,
                      ),
                      boxShadow: member.isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withAlpha(100),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Siz',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleConfig.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      roleConfig.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: roleConfig.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        member.isOnline
                            ? Icons.circle
                            : Icons.access_time,
                        size: 10,
                        color: member.isOnline
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          color: member.isOnline
                              ? const Color(0xFF10B981)
                              : (const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // More
            const Icon(
              Icons.more_vert,
              color: Color(0x1EFFFFFF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  _RoleConfig _roleConfig(MemberRole role) {
    return switch (role) {
      MemberRole.admin =>
        _RoleConfig(label: 'Yönetici', color: const Color(0xFF6366F1)),
      MemberRole.parent =>
        _RoleConfig(label: 'Ebeveyn', color: const Color(0xFFEC4899)),
      MemberRole.teen =>
        _RoleConfig(label: 'Genç', color: const Color(0xFFF59E0B)),
      MemberRole.child =>
        _RoleConfig(label: 'Çocuk', color: const Color(0xFF10B981)),
      MemberRole.elder =>
        _RoleConfig(label: 'Büyük', color: const Color(0xFF8B5CF6)),
      MemberRole.guest =>
        _RoleConfig(label: 'Misafir', color: const Color(0xFF6B7280)),
      MemberRole.baby =>
        _RoleConfig(label: 'Bebek', color: AppColors.cyan),
    };
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Bilinmiyor';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }
}

class _RoleConfig {
  final String label;
  final Color color;

  _RoleConfig({required this.label, required this.color});
}
