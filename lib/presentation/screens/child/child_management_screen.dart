import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/constants.dart';
import '../../../domain/models/child_account.dart';
import '../../../repositories/child_account_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../widgets/screen_background.dart';

class ChildManagementScreen extends ConsumerStatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  ConsumerState<ChildManagementScreen> createState() =>
      _ChildManagementScreenState();
}

class _ChildManagementScreenState extends ConsumerState<ChildManagementScreen> {
  final _repo = ChildAccountRepository();
  List<ChildAccount> _children = [];
  bool _isLoading = true;
  String? _familyId;
  StreamSubscription<List<ChildAccount>>? _childrenSub;

  @override
  void initState() {
    super.initState();
    _loadFamilyAndChildren();
  }

  @override
  void dispose() {
    _childrenSub?.cancel();
    super.dispose();
  }

  /// Cloud aile için realtime abonelik — başka cihazda/üyede çocuk eklenince
  /// bu ekran anında güncellenir.
  void _subscribeRealtime(String familyId) {
    if (familyId == ChildAccountRepository.localFamilyId) return;
    _childrenSub?.cancel();
    _childrenSub = _repo.watchChildren(familyId).listen((children) {
      if (mounted) setState(() => _children = children);
    }, onError: (_) {});
  }

  Future<void> _loadFamilyAndChildren() async {
    try {
      final userId = _repo.currentUserId;
      if (userId == null || userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Try families table first (created_by lookup)
      String? familyId;
      try {
        final familyResponse = await _repo.client
            .from('families')
            .select('id')
            .eq('created_by', userId)
            .maybeSingle();
        familyId = familyResponse?['id'] as String?;
      } catch (_) {
        try {
          final memberResponse = await _repo.client
              .from('family_members')
              .select('family_id')
              .eq('user_id', userId)
              .maybeSingle();
          familyId = memberResponse?['family_id'] as String?;
        } catch (e) {
          debugPrint('Child management error: $e');
        }
      }

      // Gerçek aile yoksa (giriş/migration eksik) yerel aileye düş — çocuk
      // hesapları tek cihazda Hive'da gerçek olarak çalışır.
      familyId ??= ChildAccountRepository.localFamilyId;
      _familyId = familyId;
      final children = await _repo.getChildrenForFamily(familyId);
      setState(() {
        _children = children;
        _isLoading = false;
      });
      _subscribeRealtime(familyId);
    } catch (e) {
      debugPrint('ChildManagementScreen._loadFamilyAndChildren error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChild(ChildAccount child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).cocukHesabiniSil),
        content: Text(
          AppLocalizations.of(context).childDeleteConfirm(child.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteChild(child.id);
        setState(() => _children.removeWhere((c) => c.id == child.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).cocukHesabiSilindi),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).cmDeleteFailed('$e')),
            ),
          );
        }
      }
    }
  }

  void _showAddEditChild({ChildAccount? child}) {
    if (_familyId == null || _familyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).aileBilgisiBulunamadiLutfenSayfayiYenileyin,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ChildFormSheet(
        familyId: _familyId!,
        child: child,
        onSaved: _loadFamilyAndChildren,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.child_care_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).cocukHesaplari,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE5E7EB),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ScreenBackground(
        asset: 'assets/images/backgrounds/child_bg.png',
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : _children.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.child_care_outlined,
                        size: 32,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).henuzCocukHesabiYok,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).cmTapToAddMember,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditChild(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context).cocukEkle),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0x1EFFFFFF),
                        width: 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      onTap: () => context.push('/child/${child.id}'),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: child.color,
                          shape: BoxShape.circle,
                        ),
                        child: child.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  child.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 46,
                                  height: 46,
                                  // Kırık/erişilemeyen görselde baş harfe düş.
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      child.initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  child.initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                      title: Text(
                        child.name,
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${child.displayRole} · ${child.isActive ? 'Aktif' : 'Pasif'}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF6366F1),
                            ),
                            onPressed: () => _showAddEditChild(child: child),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            onPressed: () => _deleteChild(child),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _children.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditChild(),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _ChildFormSheet extends StatefulWidget {
  final String familyId;
  final ChildAccount? child;
  final VoidCallback onSaved;

  const _ChildFormSheet({
    required this.familyId,
    this.child,
    required this.onSaved,
  });

  @override
  State<_ChildFormSheet> createState() => _ChildFormSheetState();
}

class _ChildFormSheetState extends State<_ChildFormSheet> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  ChildRole _role = ChildRole.child;
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;
  File? _avatarFile;
  String? _avatarUrl;
  // İzinler
  bool _canApproveTasks = false;
  bool _canSendMessages = true;
  bool _canViewBudget = false;
  int _dailyScreenTime = 120;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _nameController.text = widget.child!.name;
      _role = widget.child!.role;
      _selectedColor = widget.child!.color;
      _avatarUrl = widget.child!.avatarUrl;
      _canApproveTasks = widget.child!.canApproveTasks;
      _canSendMessages = widget.child!.canSendMessages;
      _canViewBudget = widget.child!.canViewBudget;
      _dailyScreenTime = widget.child!.dailyScreenTimeMinutes;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (widget.familyId.isEmpty) {
      _showError('Aile bilgisi eksik. Lütfen sayfayı yenileyin.');
      return;
    }

    if (name.length < 2) {
      _showError('İsim en az 2 karakter olmalı');
      return;
    }

    if (widget.child == null && pin.length < 4) {
      _showError('PIN en az 4 haneli olmalı');
      return;
    }

    if (widget.child == null && pin != confirmPin) {
      _showError('PIN\'ler eşleşmiyor');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ChildAccountRepository();
      String? finalAvatarUrl = _avatarUrl;

      // Yerel çocukta bulut yükleme yerine dosya yolunu kullan (tek cihaz).
      Future<String?> resolveAvatar(String childId) async {
        if (_avatarFile == null) return finalAvatarUrl;
        if (childId.startsWith('local_')) return _avatarFile!.path;
        try {
          return await repo.uploadAvatar(childId, _avatarFile!.path);
        } catch (_) {
          return _avatarFile!.path; // yükleme başarısızsa yerel yol
        }
      }

      if (widget.child != null) {
        finalAvatarUrl = await resolveAvatar(widget.child!.id);
        await repo.updateChild(
          widget.child!.id,
          name: name,
          role: _role,
          color: _selectedColor,
          avatarUrl: finalAvatarUrl,
          pin: pin.isNotEmpty ? pin : null,
          canApproveTasks: _canApproveTasks,
          canSendMessages: _canSendMessages,
          canViewBudget: _canViewBudget,
          dailyScreenTimeMinutes: _dailyScreenTime,
        );
      } else {
        final newChild = await repo.createChild(
          familyId: widget.familyId,
          name: name,
          pin: pin,
          role: _role,
          color: _selectedColor,
          avatarUrl: finalAvatarUrl,
          canApproveTasks: _canApproveTasks,
          canSendMessages: _canSendMessages,
          canViewBudget: _canViewBudget,
          dailyScreenTimeMinutes: _dailyScreenTime,
        );
        final resolved = await resolveAvatar(newChild.id);
        if (resolved != null && resolved != finalAvatarUrl) {
          await repo.updateChild(newChild.id, avatarUrl: resolved);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) _showError('Kaydetme başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.child != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isEdit ? 'Çocuk Hesabını Düzenle' : 'Yeni Çocuk Hesabı',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        image: _avatarFile != null
                            ? DecorationImage(
                                image: FileImage(_avatarFile!),
                                fit: BoxFit.cover,
                              )
                            : (_avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: (_avatarFile == null && _avatarUrl == null)
                          ? Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).isim,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Rol', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ChildRole>(
              segments: [
                ButtonSegment(
                  value: ChildRole.child,
                  label: Text(AppLocalizations.of(context).child),
                  icon: const Icon(Icons.child_care),
                ),
                ButtonSegment(
                  value: ChildRole.teen,
                  label: Text(AppLocalizations.of(context).genc),
                  icon: const Icon(Icons.emoji_people),
                ),
                ButtonSegment(
                  value: ChildRole.baby,
                  label: Text(AppLocalizations.of(context).cmBaby),
                  icon: const Icon(Icons.crib),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (set) => setState(() => _role = set.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context).childPermissions,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).cmCanMessage),
              value: _canSendMessages,
              onChanged: (v) => setState(() => _canSendMessages = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).cmCanApproveTask),
              value: _canApproveTasks,
              onChanged: (v) => setState(() => _canApproveTasks = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).cmCanSeeBudget),
              value: _canViewBudget,
              onChanged: (v) => setState(() => _canViewBudget = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).cmDailyScreenTime),
                const Spacer(),
                Text(
                  '$_dailyScreenTime dk',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: _dailyScreenTime.toDouble().clamp(0, 480),
              min: 0,
              max: 480,
              divisions: 16,
              label: '$_dailyScreenTime dk',
              onChanged: (v) => setState(() => _dailyScreenTime = v.round()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Renk', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withAlpha(150),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: isEdit
                    ? 'Yeni PIN (isteğe bağlı)'
                    : 'PIN (4-6 hane)',
                prefixIcon: const Icon(Icons.lock_outline),
                counterText: '',
              ),
            ),
            if (!isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).cmPinRepeat,
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Güncelle' : 'Oluştur'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
