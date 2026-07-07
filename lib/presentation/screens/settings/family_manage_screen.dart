import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/entities.dart';
import '../../../services/auth_service.dart';
import '../../providers/app_providers.dart' show localFamilyMembers;

import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilyManageScreen extends ConsumerStatefulWidget {
  const FamilyManageScreen({super.key});

  @override
  ConsumerState<FamilyManageScreen> createState() => _FamilyManageScreenState();
}

class _FamilyManageScreenState extends ConsumerState<FamilyManageScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  String? _familyId;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService.currentUserId;
    _loadFamilyAndMembers();
  }

  Future<void> _loadFamilyAndMembers() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.safeClient;
      final userId = AuthService.currentUserId;
      if (client == null || userId == null) {
        setState(() {
          _members = localFamilyMembers();
          _isLoading = false;
        });
        return;
      }

      final fm = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      final familyId = fm?['family_id'] as String?;
      _familyId = familyId;

      if (familyId == null) {
        setState(() {
          _members = localFamilyMembers();
          _isLoading = false;
        });
        return;
      }

      final futures = await Future.wait([
        client
            .from('family_members')
            .select('''
              family_id,
              user_id,
              role,
              display_name,
              color,
              joined_at,
              last_active_at,
              is_active,
              profiles:profiles!inner(display_name, avatar_url, email)
            ''')
            .eq('family_id', familyId)
            .eq('is_active', true)
            .order('joined_at', ascending: true),
        client
            .from('child_accounts')
            .select('id, name, avatar_url, age, family_id')
            .eq('family_id', familyId),
      ]);

      final adultRows = (futures[0] as List).cast<Map<String, dynamic>>();
      final childRows = (futures[1] as List).cast<Map<String, dynamic>>();

      final adults = adultRows.map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        final displayName = (r['display_name'] as String?) ??
            (profile?['display_name'] as String?) ??
            'İsimsiz';
        final colorHex = r['color'] as String? ?? '#3B82F6';
        final color = _parseColor(colorHex);
        final role = _parseRole(r['role'] as String?);
        final lastActive = r['last_active_at'] != null
            ? DateTime.tryParse(r['last_active_at'] as String)
            : null;
        final isOnline = lastActive != null &&
            DateTime.now().difference(lastActive).inMinutes < 5;

        return FamilyMember(
          id: r['user_id'] as String,
          name: displayName,
          initial: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          color: color,
          avatarUrl: profile?['avatar_url'] as String?,
          role: role,
          isOnline: isOnline,
          lastSeen: lastActive,
          joinedAt: r['joined_at'] != null
              ? DateTime.tryParse(r['joined_at'] as String)
              : null,
        );
      }).toList();

      final children = childRows.map((r) {
        final name = (r['name'] as String?) ?? 'İsimsiz Çocuk';
        return FamilyMember(
          id: r['id'] as String,
          name: name,
          initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
          color: AppColors.orange,
          avatarUrl: r['avatar_url'] as String?,
          role: MemberRole.child,
          isOnline: false,
          lastSeen: null,
          joinedAt: null,
        );
      }).toList();

      final combined = [...adults, ...children];
      setState(() {
        // Supabase boş dönerse (RLS/çevrimdışı) yerel aile üyelerine düş.
        _members = combined.isEmpty ? localFamilyMembers() : combined;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('FamilyManageScreen error: $e');
      setState(() {
        _members = localFamilyMembers();
        _isLoading = false;
      });
    }
  }

  bool get _isAdmin {
    final me = _members.firstWhere(
      (m) => m.id == _myUserId,
      orElse: () => const FamilyMember(
        id: '', name: '', initial: '', color: Colors.blue, role: MemberRole.guest,
      ),
    );
    return me.role == MemberRole.admin || me.role == MemberRole.parent;
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  static MemberRole _parseRole(String? role) {
    return MemberRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => MemberRole.guest,
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

  Color _roleColor(MemberRole role) {
    return switch (role) {
      MemberRole.admin => const Color(0xFF6366F1),
      MemberRole.parent => const Color(0xFF8B5CF6),
      MemberRole.teen => AppColors.blue,
      MemberRole.child => AppColors.orange,
      MemberRole.elder => const Color(0xFF6B7280),
      MemberRole.guest => const Color(0xFF6B7280),
      MemberRole.baby => const Color(0xFFEC4899),
    };
  }

  Future<void> _changeRole(FamilyMember member, MemberRole newRole) async {
    if (_familyId == null) return;
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      await client
          .from('family_members')
          .update({'role': newRole.name})
          .eq('family_id', _familyId!)
          .eq('user_id', member.id);

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} artık ${_roleLabel(newRole)}')),
        );
      }
      await _loadFamilyAndMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol güncellenemedi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeMember(FamilyMember member) async {
    if (_familyId == null) return;
    final isSelf = member.id == _myUserId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSelf ? 'Aileden Ayrıl' : 'Üyeyi Çıkar'),
        content: Text(
          isSelf
              ? 'Bu aileden ayrılmak istediğinize emin misiniz?'
              : '${member.name} bu aileden çıkarılacak. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isSelf ? 'Ayrıl' : 'Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      await client
          .from('family_members')
          .delete()
          .eq('family_id', _familyId!)
          .eq('user_id', member.id);

      if (isSelf && mounted) {
        context.go(AppRoutes.login);
        return;
      }

      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} çıkarıldı')),
        );
      }
      await _loadFamilyAndMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showRolePicker(FamilyMember member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${member.name} — Rol Seç',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...MemberRole.values.map(
                (role) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _roleColor(role).withAlpha(25),
                    child: Icon(Icons.person, color: _roleColor(role), size: 18),
                  ),
                  title: Text(_roleLabel(role)),
                  trailing: member.role == role
                      ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeRole(member, role);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberActions(FamilyMember member) {
    final isSelf = member.id == _myUserId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x1EFFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: _AvatarCircle(member: member, size: 40),
                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_roleLabel(member.role)),
              ),
              const Divider(),
              if (_isAdmin || isSelf)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                  title: Text(AppLocalizations.of(context).roluDegistir),
                  onTap: () {
                    Navigator.pop(context);
                    _showRolePicker(member);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF10B981)),
                title: Text(AppLocalizations.of(context).konumunuGor),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.location);
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety, color: Color(0xFF8B5CF6)),
                title: Text(AppLocalizations.of(context).healthCard),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.healthCard);
                },
              ),
              if (_isAdmin || isSelf)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.error),
                  title: Text(isSelf ? 'Aileden Ayrıl' : 'Üyeyi Çıkar'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMember(member);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final adults = _members.where((m) => m.role != MemberRole.child).toList()
      ..sort((a, b) {
        if (a.role == MemberRole.admin && b.role != MemberRole.admin) return -1;
        if (b.role == MemberRole.admin && a.role != MemberRole.admin) return 1;
        if (a.isOnline && !b.isOnline) return -1;
        if (b.isOnline && !a.isOnline) return 1;
        return a.name.compareTo(b.name);
      });

    final children = _members.where((m) => m.role == MemberRole.child).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: 'Aile Yönetimi',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_members.length} Üye',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (adults.isNotEmpty) ...[
                          const Text(
                            'Ebeveynler ve Yetişkinler',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...adults.map(
                            (m) => _MemberTile(
                              member: m,
                              isMe: m.id == _myUserId,
                              isAdmin: _isAdmin,
                              onTap: () => _showMemberActions(m),
                            ),
                          ),
                        ],
                        if (children.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Çocuklar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...children.map(
                            (m) => _MemberTile(
                              member: m,
                              isMe: m.id == _myUserId,
                              isAdmin: _isAdmin,
                              onTap: () => _showMemberActions(m),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.inviteCode),
                            icon: const Icon(Icons.person_add, color: Colors.white),
                            label: const Text(
                              'Yeni Üye Davet Et',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.childManagement),
                            icon: const Icon(Icons.child_care, color: Colors.white),
                            label: const Text(
                              'Çocuk Hesabı Ekle',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String? _formatLastSeen(DateTime? dt) {
  if (dt == null) return null;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  return '${diff.inDays} gün önce';
}

class _AvatarCircle extends StatelessWidget {
  final FamilyMember member;
  final double size;

  const _AvatarCircle({required this.member, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.color,
        borderRadius: BorderRadius.circular(size * 0.3),
        image: member.avatarUrl != null
            ? DecorationImage(image: NetworkImage(member.avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: member.avatarUrl == null
          ? Center(
              child: Text(
                member.initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.35,
                ),
              ),
            )
          : null,
    );
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMember member;
  final bool isMe;
  final bool isAdmin;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    String roleLabel() {
      return switch (member.role) {
        MemberRole.admin => 'Yönetici',
        MemberRole.parent => 'Ebeveyn',
        MemberRole.teen => 'Genç',
        MemberRole.child => 'Çocuk',
        MemberRole.elder => 'Büyük',
        MemberRole.guest => 'Misafir',
        MemberRole.baby => 'Bebek',
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1EFFFFFF),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  _AvatarCircle(member: member),
                  if (member.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF13131A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        if (isMe)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sen',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${roleLabel()} · ${member.isOnline ? 'Çevrimiçi' : (_formatLastSeen(member.lastSeen) ?? 'Çevrimdışı')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
