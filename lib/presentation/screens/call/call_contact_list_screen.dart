import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../../repositories/family_members_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/call_service.dart';
import '../../../services/permission_service.dart';
import 'voice_call_screen.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CallContactListScreen extends StatefulWidget {
  const CallContactListScreen({super.key});

  @override
  State<CallContactListScreen> createState() => _CallContactListScreenState();
}

class _CallContactListScreenState extends State<CallContactListScreen> {
  final _repo = FamilyMembersRepository();
  List<FamilyMember> _members = [];
  List<FamilyMember> _filtered = [];
  bool _isLoading = true;
  String? _currentUserId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      _currentUserId = AuthService.currentUserId;
      final members = await _repo.getMembers();
      // Exclude current user from callable list
      final others = members.where((m) => m.id != _currentUserId).toList();
      setState(() {
        _members = others;
        _filtered = others;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CallContactListScreen._loadMembers error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _members
          : _members.where((m) => m.name.toLowerCase().contains(q)).toList();
    });
  }

  bool _canCall(FamilyMember member) {
    return member.role == MemberRole.admin ||
        member.role == MemberRole.parent ||
        member.role == MemberRole.elder;
  }

  Future<void> _startCall(FamilyMember member) async {
    if (!CallService.isConfigured) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(AppLocalizations.of(context).aramaHazirlaniyor),
            content: const Text(
              'Sesli arama özelliği şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
        );
      }
      return;
    }

    final micGranted = await PermissionService.requestMicrophone(context);
    if (!micGranted) return;

    HapticFeedback.mediumImpact();
    try {
      final session = await CallService.startCall(
        calleeId: member.id,
        calleeName: member.name,
        calleeAvatar: member.avatarUrl,
      );
      if (session != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              session: session,
              initialMode: VoiceCallMode.outgoing,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama başlatılamadı: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        title: const Text('Aile Rehberi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Aile üyesi ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF13131A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final member = _filtered[index];
                          final callable = _canCall(member);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: member.color,
                              backgroundImage: member.avatarUrl != null
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? Text(
                                      member.initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(member.name),
                            subtitle: Text(_roleLabel(member.role)),
                            trailing: callable
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.phone,
                                      color: Color(0xFF6366F1),
                                    ),
                                    onPressed: () => _startCall(member),
                                  )
                                : const Chip(
                                    label: Text(
                                      'Aranamaz',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    backgroundColor: Color(0xFF13131A),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 16),
          Text(
            'Henüz aranabilecek aile üyesi yok',
            style: TextStyle(
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(MemberRole role) {
    return switch (role) {
      MemberRole.admin => 'Yönetici',
      MemberRole.parent => 'Ebeveyn',
      MemberRole.elder => 'Büyük',
      MemberRole.teen => 'Genç',
      MemberRole.child => 'Çocuk',
      MemberRole.baby => 'Bebek',
      MemberRole.guest => 'Misafir',
    };
  }
}
