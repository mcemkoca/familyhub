import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/models/child_account.dart';
import '../../../repositories/child_account_repository.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildLoginScreen extends ConsumerStatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  ConsumerState<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends ConsumerState<ChildLoginScreen> {
  final _pinController = TextEditingController();
  final _repo = ChildAccountRepository();
  ChildAccount? _selectedChild;
  List<ChildAccount> _children = [];
  bool _isLoading = false;
  bool _isLoadingChildren = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final userId = _repo.currentUserId;

      // Require parent authentication for child login
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingChildren = false;
          _error = 'Çocuk girişi için önce ebeveyn hesabıyla giriş yapmalısınız.';
        });
        return;
      }

      // Get current user's family
      final response = await _repo.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();

      final familyId = response?['family_id'] as String?;
      if (familyId == null) {
        setState(() {
          _isLoadingChildren = false;
          _error = 'Aile bilgisi bulunamadı. Lütfen önce aile oluşturun.';
        });
        return;
      }

      final children = await _repo.getChildrenForFamily(familyId);
      setState(() {
        _children = children;
        _isLoadingChildren = false;
        if (children.isNotEmpty) _selectedChild = children.first;
      });
    } catch (e) {
      debugPrint('ChildLoginScreen._loadChildren error: $e');
      final isTableMissing = e is PostgrestException &&
          (e.code == 'PGRST205' || e.message.contains('Could not find the table'));
      if (isTableMissing) {
        setState(() {
          _isLoadingChildren = false;
          _error = 'Veritabanı tabloları eksik (child_accounts). Lütfen Supabase migration\'larını uygulayın.';
        });
      } else {
        setState(() {
          _isLoadingChildren = false;
          _error = 'Çocuklar yüklenirken hata oluştu: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (_selectedChild == null) {
      _showError('Lütfen bir çocuk seçin');
      return;
    }

    // Remote lock check
    final child = _selectedChild!;
    if (child.remoteLockEnabled && child.remoteLockUntil != null) {
      if (DateTime.now().isBefore(child.remoteLockUntil!)) {
        _showError(
          'Cihazın uzaktan kilitli.\nNeden: ${child.remoteLockReason ?? 'Belirtilmemiş'}\n'
          'Kilit açılması: ${_formatLockTime(child.remoteLockUntil!)}',
        );
        return;
      }
    }

    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showError('PIN en az 4 haneli olmalı');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ChildAuthService.signIn(childId: child.id, pin: pin);

      if (mounted) {
        context.go(AppRoutes.childDashboard);
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatLockTime(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inMinutes < 1) return 'Birazdan';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk sonra';
    if (diff.inHours < 24) return '${diff.inHours} sa sonra';
    return '${diff.inDays} gün sonra';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).cocukGirisi),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Çocuk Girişi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'İsmini seç ve PINini gir',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.gray,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_isLoadingChildren)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                  ),
                )
              else if (_children.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.gray,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Henüz çocuk hesabı eklenmemiş.\nEbeveyn girişi yaparak ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Çocuk Seç',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: _children.map((child) {
                    final isSelected = _selectedChild?.id == child.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChild = child),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? child.color.withAlpha(30) : null,
                          border: Border.all(
                            color: isSelected
                                ? child.color
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: child.color,
                              radius: 20,
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
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  child.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? child.color : null,
                                  ),
                                ),
                                Text(
                                  child.displayRole,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'PIN Kodu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 16),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      letterSpacing: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray,
                    ),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedChild == null
                        ? null
                        : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
