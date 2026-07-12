import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';

class MemberActionSheet extends StatelessWidget {
  final FamilyMember member;
  final bool isAdmin;
  final bool isMe;
  final VoidCallback onClose;
  final Function(MemberRole) onRoleChange;
  final VoidCallback onRemove;
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewHealth;
  final VoidCallback? onViewLocation;

  const MemberActionSheet({
    super.key,
    required this.member,
    required this.isAdmin,
    required this.isMe,
    required this.onClose,
    required this.onRoleChange,
    required this.onRemove,
    this.onViewProfile,
    this.onViewHealth,
    this.onViewLocation,
  });

  static const _roles = [
    MemberRole.admin,
    MemberRole.parent,
    MemberRole.teen,
    MemberRole.child,
    MemberRole.elder,
    MemberRole.guest,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(40),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF13131A),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x1EFFFFFF)
                            : const Color(0x1EFFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Preview
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: member.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          member.initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roleLabel(member.role),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Actions
                    _ActionButton(
                      icon: Icons.person_outline,
                      label: AppLocalizations.of(context).masViewProfile,
                      onTap: onViewProfile ?? onClose,
                    ),
                    _ActionButton(
                      icon: Icons.health_and_safety_outlined,
                      label: AppLocalizations.of(context).masHealthCard,
                      iconColor: const Color(0xFF10B981),
                      onTap: onViewHealth ?? onClose,
                    ),
                    _ActionButton(
                      icon: Icons.location_on_outlined,
                      label: AppLocalizations.of(context).masLiveLocation,
                      iconColor: const Color(0xFF6366F1),
                      onTap: onViewLocation ?? onClose,
                    ),
                    // Role change (admin only, not self)
                    if (isAdmin && !isMe) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: isDark
                            ? const Color(0x1EFFFFFF)
                            : const Color(0x1EFFFFFF),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ROL DEĞİŞTİR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._roles.map((role) {
                        final isSelected = member.role == role;
                        return _RoleOption(
                          role: role,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onRoleChange(role);
                            onClose();
                          },
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x1EFFFFFF),
                    ),
                    const SizedBox(height: 8),
                    // Remove / Leave
                    if (isMe)
                      _ActionButton(
                        icon: Icons.exit_to_app,
                        label: AppLocalizations.of(context).masLeaveFamily,
                        iconColor: AppColors.error,
                        onTap: () {
                          onClose();
                          onRemove();
                        },
                      )
                    else if (isAdmin)
                      _ActionButton(
                        icon: Icons.person_remove_outlined,
                        label: AppLocalizations.of(context).masRemoveMember,
                        iconColor: AppColors.error,
                        onTap: () {
                          onClose();
                          onRemove();
                        },
                      ),
                    const SizedBox(height: 8),
                    // Cancel
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF0A0A0F)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: isDark
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF6B7280),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(MemberRole role) {
    return switch (role) {
      MemberRole.admin => 'Yönetici',
      MemberRole.parent => 'Ebeveyn',
      MemberRole.teen => 'Genç',
      MemberRole.child => 'Çocuk',
      MemberRole.elder => 'Büyük',
      MemberRole.guest => 'Misafir',
      MemberRole.baby => 'Bebek',
    };
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF6366F1),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: iconColor == AppColors.error
              ? AppColors.error
              : (const Color(0xFFE5E7EB)),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 36,
    );
  }
}

class _RoleOption extends StatelessWidget {
  final MemberRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      MemberRole.admin => 'Yönetici',
      MemberRole.parent => 'Ebeveyn',
      MemberRole.teen => 'Genç',
      MemberRole.child => 'Çocuk',
      MemberRole.elder => 'Büyük',
      MemberRole.guest => 'Misafir',
      MemberRole.baby => 'Bebek',
    };
    final color = switch (role) {
      MemberRole.admin => const Color(0xFF6366F1),
      MemberRole.parent => const Color(0xFFEC4899),
      MemberRole.teen => const Color(0xFFF59E0B),
      MemberRole.child => const Color(0xFF10B981),
      MemberRole.elder => const Color(0xFF8B5CF6),
      MemberRole.guest => const Color(0xFF6B7280),
      MemberRole.baby => AppColors.cyan,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _roleIcon(role),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF6366F1), size: 20),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(MemberRole role) {
    return switch (role) {
      MemberRole.admin => Icons.shield_outlined,
      MemberRole.parent => Icons.people_outline,
      MemberRole.teen => Icons.person_outline,
      MemberRole.child => Icons.child_care_outlined,
      MemberRole.elder => Icons.elderly_outlined,
      MemberRole.guest => Icons.person_outline,
      MemberRole.baby => Icons.baby_changing_station_outlined,
    };
  }
}
