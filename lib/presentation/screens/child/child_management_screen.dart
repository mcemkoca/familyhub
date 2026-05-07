import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/constants.dart';
import '../../../domain/models/child_account.dart';
import '../../../repositories/child_account_repository.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildManagementScreen extends ConsumerStatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  ConsumerState<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends ConsumerState<ChildManagementScreen> {
  final _repo = ChildAccountRepository();
  List<ChildAccount> _children = [];
  bool _isLoading = true;
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadFamilyAndChildren();
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
        } catch (_) {}
      }

      _familyId = familyId;
      if (familyId != null) {
        final children = await _repo.getChildrenForFamily(familyId);
        setState(() {
          _children = children;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
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
        content: Text('${child.name} adlı çocuk hesabını silmek istediğinize emin misiniz?'),
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
            SnackBar(content: Text(AppLocalizations.of(context).cocukHesabiSilindi)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme başarısız: $e')),
          );
        }
      }
    }
  }

  void _showAddEditChild({ChildAccount? child}) {
    if (_familyId == null || _familyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).aileBilgisiBulunamadiLutfenSayfayiYenileyin),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).cocukHesaplari),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care_outlined,
                        size: 64,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Henüz çocuk hesabı yok',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditChild(),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ListTile(
                        onTap: () => context.push('/child/${child.id}'),
                        leading: CircleAvatar(
                          backgroundColor: child.color,
                          backgroundImage: child.avatarUrl != null
                              ? NetworkImage(child.avatarUrl!)
                              : null,
                          child: child.avatarUrl == null
                              ? Text(
                                  child.initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(child.name),
                        subtitle: Text(
                          '${child.displayRole} • PIN: ${child.isActive ? 'Aktif' : 'Pasif'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showAddEditChild(child: child),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => _deleteChild(child),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _children.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditChild(),
              child: const Icon(Icons.add),
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

      if (widget.child != null) {
        if (_avatarFile != null) {
          finalAvatarUrl = await repo.uploadAvatar(widget.child!.id, _avatarFile!.path);
        }
        await repo.updateChild(
          widget.child!.id,
          name: name,
          role: _role,
          color: _selectedColor,
          avatarUrl: finalAvatarUrl,
          pin: pin.isNotEmpty ? pin : null,
        );
      } else {
        final newChild = await repo.createChild(
          familyId: widget.familyId,
          name: name,
          pin: pin,
          role: _role,
          color: _selectedColor,
          avatarUrl: finalAvatarUrl,
        );
        if (_avatarFile != null) {
          finalAvatarUrl = await repo.uploadAvatar(newChild.id, _avatarFile!.path);
          await repo.updateChild(newChild.id, avatarUrl: finalAvatarUrl);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
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
                      color: AppColors.cobalt,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'İsim',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Rol',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ChildRole>(
            segments: [
              ButtonSegment(
                value: ChildRole.child,
                label: Text(AppLocalizations.of(context).child),
                icon: Icon(Icons.child_care),
              ),
              ButtonSegment(
                value: ChildRole.teen,
                label: Text(AppLocalizations.of(context).genc),
                icon: Icon(Icons.emoji_people),
              ),
              ButtonSegment(
                value: ChildRole.baby,
                label: Text('Bebek'),
                icon: Icon(Icons.crib),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (set) => setState(() => _role = set.first),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Renk',
            style: Theme.of(context).textTheme.titleSmall,
          ),
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
                        ? [BoxShadow(color: color.withAlpha(150), blurRadius: 8)]
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
              labelText: isEdit ? 'Yeni PIN (isteğe bağlı)' : 'PIN (4-6 hane)',
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
              decoration: const InputDecoration(
                labelText: 'PIN Tekrar',
                prefixIcon: Icon(Icons.lock_outline),
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
    );
  }
}
