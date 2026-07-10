import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../domain/entities.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/koca_seed.dart';
import '../../providers/app_providers.dart' show localFamilyMembers;
import '../../widgets/settings/screen_header.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class FamilyPermissionsScreen extends StatefulWidget {
  const FamilyPermissionsScreen({super.key});

  @override
  State<FamilyPermissionsScreen> createState() => _FamilyPermissionsScreenState();
}

class _FamilyPermissionsScreenState extends State<FamilyPermissionsScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _myUserId;
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService.currentUserId;
    _checkAdminAndLoad();
  }

  static const _localFamilyId = 'local_family';

  Future<void> _checkAdminAndLoad() async {
    final client = SupabaseConfig.safeClient;
    final userId = _myUserId;

    if (client != null && userId != null) {
      try {
        final fm = await client
            .from('family_members')
            .select('family_id, role')
            .eq('user_id', userId)
            .maybeSingle();

        final familyId = fm?['family_id'] as String?;
        final role = fm?['role'] as String?;
        if (familyId != null) {
          _familyId = familyId;
          _isAdmin = role == 'admin';
          if (_isAdmin) await _loadMembers(client, familyId);
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('FamilyPermissions cloud error: $e');
      }
    }

    // Yerel mod — bulut ailesi yoksa yerel üyeleri yönet (cihaz sahibi admin).
    _loadLocal();
    setState(() => _isLoading = false);
  }

  void _loadLocal() {
    _familyId = _localFamilyId;
    _isAdmin = true;
    _members = localFamilyMembers();
    final raw = HiveService.getSetting('local_member_perms');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          _memberPermissions[k] =
              (v as Map<String, dynamic>).cast<String, bool>();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveLocalPerms() async {
    await HiveService.setSetting(
        'local_member_perms', jsonEncode(_memberPermissions));
  }

  Future<void> _loadMembers(SupabaseClient client, String familyId) async {
    final response = await client
        .from('family_members')
        .select('''
          user_id,
          role,
          display_name,
          color,
          joined_at,
          permissions,
          profiles:profiles!inner(display_name, avatar_url)
        ''')
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('joined_at', ascending: true);

    final rows = (response as List).cast<Map<String, dynamic>>();

    _members = rows.map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      final displayName = (r['display_name'] as String?) ??
          (profile?['display_name'] as String?) ??
          'İsimsiz';
      final colorHex = r['color'] as String? ?? '#3B82F6';
      final color = _parseColor(colorHex);
      final role = _parseRole(r['role'] as String?);

      return FamilyMember(
        id: r['user_id'] as String,
        name: displayName,
        initial: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        color: color,
        avatarUrl: profile?['avatar_url'] as String?,
        role: role,
        isOnline: false,
        lastSeen: null,
        joinedAt: r['joined_at'] != null
            ? DateTime.tryParse(r['joined_at'] as String)
            : null,
      );
    }).toList();

    // Load permissions for each member
    for (final row in rows) {
      final userId = row['user_id'] as String;
      final perms = row['permissions'] as Map<String, dynamic>?;
      if (perms != null && perms.isNotEmpty) {
        _memberPermissions[userId] = perms.cast<String, bool>();
      }
    }
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

  /// Dropdown seçenekleri — standart rol seti + üyenin mevcut rolü (garanti
  /// eşleşme, aksi halde DropdownButton "exactly one item" assertion'ı atar).
  static List<MemberRole> _roleOptions(MemberRole current) {
    final base = <MemberRole>[
      MemberRole.admin,
      MemberRole.parent,
      MemberRole.teen,
      MemberRole.child,
      MemberRole.elder,
      MemberRole.guest,
    ];
    if (!base.contains(current)) base.add(current);
    return base;
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

  Future<void> _changeRole(String userId, MemberRole newRole) async {
    if (_familyId == null) return;

    // Yerel mod — KocaSeed üyesinin rolünü Hive'da güncelle.
    if (_familyId == _localFamilyId) {
      final idx = int.tryParse(userId.replaceFirst('local_', ''));
      final list = List<Map<String, dynamic>>.from(KocaSeed.localMembers());
      if (idx != null && idx >= 0 && idx < list.length) {
        list[idx] = {...list[idx], 'role': _roleLabel(newRole)};
        await KocaSeed.setMembers(list);
      }
      HapticFeedback.mediumImpact();
      setState(() {
        _members = localFamilyMembers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol güncellendi: ${_roleLabel(newRole)}')),
        );
      }
      return;
    }

    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    try {
      await client
          .from('family_members')
          .update({'role': newRole.name})
          .eq('family_id', _familyId!)
          .eq('user_id', userId);

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol güncellendi: ${_roleLabel(newRole)}')),
        );
      }
      setState(() => _isLoading = true);
      await _loadMembers(client, _familyId!);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol güncellenemedi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updatePermission(String userId, String key, bool value) async {
    if (_familyId == null) return;

    setState(() {
      _memberPermissions.putIfAbsent(userId, () => {});
      _memberPermissions[userId]![key] = value;
    });

    // Yerel mod — Hive'a kaydet.
    if (_familyId == _localFamilyId) {
      await _saveLocalPerms();
      HapticFeedback.mediumImpact();
      return;
    }

    final client = SupabaseConfig.safeClient;
    if (client == null) return;

    try {
      await client
          .from('family_members')
          .update({'permissions': _memberPermissions[userId]})
          .eq('family_id', _familyId!)
          .eq('user_id', userId);

      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yetki güncellenemedi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  final Map<String, Map<String, bool>> _defaultPermissions = {
    'admin': {
      'manage_members': true,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': true,
      'delete_content': true,
    },
    'parent': {
      'manage_members': false,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': false,
      'delete_content': false,
    },
    'member': {
      'manage_members': false,
      'edit_settings': false,
      'view_finance': true,
      'manage_backups': false,
      'delete_content': false,
    },
    'child': {
      'manage_members': false,
      'edit_settings': false,
      'view_finance': false,
      'manage_backups': false,
      'delete_content': false,
    },
  };

  final Map<String, Map<String, bool>> _memberPermissions = {};

  String _permissionDisplay(String key) {
    return switch (key) {
      'manage_members' => 'Üye Yönetimi',
      'edit_settings' => 'Ayarları Düzenle',
      'view_finance' => 'Bütçe Görüntüleme',
      'manage_backups' => 'Yedekleme Yönetimi',
      'delete_content' => 'İçerik Silme',
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: ScreenHeader(
          title: AppLocalizations.of(context).izinlerVeRoller,
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Center(child: Text(AppLocalizations.of(context).buEkranaErisimYetkinizYok)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).izinlerVeRoller,
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0x1EFFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(AppLocalizations.of(context).yoneticiOlarakUyelerinRolleriniVeYetkileriniDuzenleyebilirsiniz,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final member = _members[index];
                      final permissions = _memberPermissions[member.id] ??
                          _defaultPermissions[member.role.name] ??
                          _defaultPermissions['child']!;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x1EFFFFFF),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            leading: CircleAvatar(
                              backgroundColor: member.color.withAlpha(20),
                              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                              child: member.avatarUrl == null
                                  ? Text(member.initial, style: TextStyle(color: member.color))
                                  : null,
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            subtitle: Text(
                              _roleLabel(member.role),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            children: [
                              if (member.id != _myUserId)
                                ListTile(
                                  title: Text(AppLocalizations.of(context).role),
                                  trailing: DropdownButton<String>(
                                    value: member.role.name,
                                    items: _roleOptions(member.role).map((role) {
                                      return DropdownMenuItem(
                                        value: role.name,
                                        child: Text(_roleLabel(role)),
                                      );
                                    }).toList(),
                                    onChanged: (newRole) {
                                      if (newRole != null) {
                                        _changeRole(member.id, _parseRole(newRole));
                                      }
                                    },
                                  ),
                                ),
                              const Divider(),
                              ...permissions.entries.map((entry) {
                                return SwitchListTile(
                                  title: Text(_permissionDisplay(entry.key)),
                                  value: entry.value,
                                  onChanged: member.role == MemberRole.admin
                                      ? null
                                      : (value) => _updatePermission(member.id, entry.key, value),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _members.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}
