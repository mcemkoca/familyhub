import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/entities.dart';
import '../../../domain/models/family_info.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';
import '../../../repositories/family_members_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/family/member_card.dart';
import '../../widgets/family/member_action_sheet.dart';
import '../../widgets/family/invite_modal.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  FamilyMember? _selectedMember;
  bool _showActionSheet = false;
  bool _showInvite = false;
  FamilyInfo? _familyInfo;
  String? _familyId;
  @override
  void initState() {
    super.initState();
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    try {
      final service = await FamilyService.create();
      final profileRes = await service.client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      final familyId = profileRes?['family_id'] as String?;
      _familyId = familyId;

      if (familyId != null) {
        final info = await service.getFamilyInfo(familyId);
        if (mounted) {
          setState(() => _familyInfo = info);
        }
      }
    } catch (e) {
      debugPrint('Family info load error: $e');
    }
  }

  bool get _isAdmin {
    final members = ref.read(familyMembersProvider);
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null || members.isEmpty) return false;
    final me = members.firstWhere(
      (m) => m.id == currentUserId,
      orElse: () => members.first,
    );
    return me.role == MemberRole.admin || me.role == MemberRole.parent;
  }

  void _handleRoleChange(MemberRole newRole) async {
    if (_selectedMember == null || _familyId == null) return;

    final members = ref.read(familyMembersProvider);
    final index = members.indexWhere((m) => m.id == _selectedMember!.id);
    if (index == -1) return;

    try {
      await FamilyMembersRepository().updateRole(
        _selectedMember!.id,
        _familyId!,
        newRole.name,
      );

      final updated = FamilyMember(
        id: _selectedMember!.id,
        name: _selectedMember!.name,
        initial: _selectedMember!.initial,
        color: _selectedMember!.color,
        role: newRole,
        isOnline: _selectedMember!.isOnline,
        lastSeen: _selectedMember!.lastSeen,
        joinedAt: _selectedMember!.joinedAt,
      );

      final newList = List<FamilyMember>.from(members);
      newList[index] = updated;
      ref.read(familyMembersProvider.notifier).state = newList;

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedMember!.name} artık ${_roleLabel(newRole)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).fmnRoleUpdateFailed('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleRemove() {
    if (_selectedMember == null) return;
    final members = ref.read(familyMembersProvider);
    final isSelf = _selectedMember!.id == (members.isNotEmpty ? members.first.id : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSelf ? 'Aileden Ayrıl' : 'Üyeyi Çıkar'),
        content: Text(
          isSelf
              ? 'Bu aileden ayrılmak istediğinize emin misiniz?'
              : '${_selectedMember!.name} bu aileden çıkarılacak. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_familyId == null) return;

              try {
                await FamilyMembersRepository().removeMember(
                  _selectedMember!.id,
                  _familyId!,
                );

                final members = ref.read(familyMembersProvider);
                ref.read(familyMembersProvider.notifier).state =
                    members.where((m) => m.id != _selectedMember!.id).toList();

                if (isSelf) {
                  if (mounted && context.mounted) context.go(AppRoutes.login);
                } else {
                  HapticFeedback.heavyImpact();
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_selectedMember!.name} çıkarıldı'),
                      ),
                    );
                  }
                }
                setState(() => _selectedMember = null);
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).famRemoveFailed('$e')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isSelf ? 'Ayrıl' : 'Çıkar'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    final onlineCount = members.where((m) => m.isOnline).length;
    final adminCount = members.where((m) => m.role == MemberRole.admin).length;
    final childCount = members.where((m) => m.role == MemberRole.child || m.role == MemberRole.baby).length;

    // Sort: admin first, then online, then name
    final sortedMembers = List<FamilyMember>.from(members)
      ..sort((a, b) {
        if (a.role == MemberRole.admin && b.role != MemberRole.admin) return -1;
        if (b.role == MemberRole.admin && a.role != MemberRole.admin) return 1;
        if (a.isOnline && !b.isOnline) return -1;
        if (b.isOnline && !a.isOnline) return 1;
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ailem',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} üye Â· Ailem',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Family Info Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: InkWell(
                      onTap: () {
                        if (_familyId != null) {
                          context.push(AppRoutes.familyDetail, extra: _familyId);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                                image: _familyInfo?.photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_familyInfo!.photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _familyInfo?.photoUrl == null
                                  ? const Icon(
                                      Icons.family_restroom,
                                      color: Color(0xFF6366F1),
                                      size: 28,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _familyInfo?.name ?? 'Ailem',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  if (_familyInfo?.description?.isNotEmpty == true)
                                    Text(
                                      _familyInfo!.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Detayları görüntüle ve düzenle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  if (_familyInfo?.foundedDate != null)
                                    Text(
                                      'Kuruluş: ${DateFormat('dd.MM.yyyy').format(_familyInfo!.foundedDate!)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Stats
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _StatItem(
                          icon: Icons.people,
                          value: '${members.length}',
                          label: AppLocalizations.of(context).uye,
                          color: const Color(0xFF6366F1),
                        ),
                        _StatItem(
                          icon: Icons.circle,
                          value: '$onlineCount',
                          label: AppLocalizations.of(context).online,
                          color: const Color(0xFF10B981),
                        ),
                        _StatItem(
                          icon: Icons.shield,
                          value: '$adminCount',
                          label: AppLocalizations.of(context).admin,
                          color: const Color(0xFF6366F1),
                        ),
                        _StatItem(
                          icon: Icons.child_care,
                          value: '$childCount',
                          label: AppLocalizations.of(context).child,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // Members list
                SliverList.builder(
                  itemCount: sortedMembers.length,
                  itemBuilder: (context, index) {
                    final member = sortedMembers[index];
                    return MemberCard(
                      member: member,
                      isMe: member.id == (members.isNotEmpty ? members.first.id : ''),
                      onTap: () => setState(() {
                        _selectedMember = member;
                        _showActionSheet = true;
                      }),
                    );
                  },
                ),
                // Bottom padding
                SliverToBoxAdapter(
                  child: SizedBox(height: safeBottom + 100),
                ),
              ],
            ),
            // Action Sheet
            if (_showActionSheet && _selectedMember != null)
              MemberActionSheet(
                member: _selectedMember!,
                isAdmin: _isAdmin,
                isMe: _selectedMember!.id == (members.isNotEmpty ? members.first.id : ''),
                onClose: () => setState(() => _showActionSheet = false),
                onRoleChange: _handleRoleChange,
                onRemove: _handleRemove,
                onViewProfile: () {
                  setState(() => _showActionSheet = false);
                  context.push(AppRoutes.settings);
                },
                onViewHealth: () {
                  setState(() => _showActionSheet = false);
                  context.push(AppRoutes.healthCard);
                },
                onViewLocation: () {
                  setState(() => _showActionSheet = false);
                  context.push(AppRoutes.location);
                },
              ),
            // Invite Modal
            if (_showInvite)
              InviteModal(
                onClose: () => setState(() => _showInvite = false),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showInvite = true),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(AppLocalizations.of(context).famInvite, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

