import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/design/app_shadows.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _familyCodeController = TextEditingController();
  final _familyNameController = TextEditingController();
  bool _hasFamilyCode = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  Future<void> _register() async {
    HapticFeedback.mediumImpact();

    // Validate inputs
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final nameError = InputValidator.validateName(name);
    if (nameError != null) {
      _showError(nameError);
      return;
    }

    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (!_acceptedTerms) {
      _showError('Devam etmek için kullanım koşullarını kabul etmelisiniz');
      return;
    }

    if (_hasFamilyCode && _familyCodeController.text.trim().isEmpty) {
      _showError('Lütfen aile kodunu girin');
      return;
    }

    if (!_hasFamilyCode && _familyNameController.text.trim().isEmpty) {
      _showError('Lütfen aile adını girin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        familyName: _hasFamilyCode ? null : _familyNameController.text.trim(),
      );

      if (mounted) {
        _showSuccess('Hesabınız oluşturuldu!');
        // Auto-login after registration
        context.go(AppRoutes.hub);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _familyCodeController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (previous, next) {
      if (next == true && mounted) {
        context.go(AppRoutes.hub);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).kayitOl),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _hasFamilyCode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_hasFamilyCode
                                ? (isDark ? AppColors.darkBackground : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.small - 4),
                            boxShadow: !_hasFamilyCode
                                ? AppShadows.lightSm
                                : null,
                          ),
                          child: Text(
                            'Yeni Aile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_hasFamilyCode
                                  ? accentColor
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.gray),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _hasFamilyCode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _hasFamilyCode
                                ? (isDark ? AppColors.darkBackground : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.small - 4),
                            boxShadow: _hasFamilyCode
                                ? AppShadows.lightSm
                                : null,
                          ),
                          child: Text(
                            'Aileye Katıl',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _hasFamilyCode
                                  ? accentColor
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.gray),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'En az 8 karakter, büyük/küçük harf, rakam ve özel karakter',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_hasFamilyCode)
                TextField(
                  controller: _familyCodeController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: 'Aile Kodu',
                    prefixIcon: Icon(Icons.key_outlined),
                    hintText: 'Örn: FH-123456',
                  ),
                )
              else
                TextField(
                  controller: _familyNameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: 'Aile Adı',
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Örn: Yılmaz Ailesi',
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    activeColor: accentColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                          ),
                          children: [
                            const TextSpan(text: 'Kullanım koşullarını ve '),
                            TextSpan(
                              text: 'gizlilik politikasını',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' okudum ve kabul ediyorum.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
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
                      : Text(
                          _hasFamilyCode ? 'Aileye Katıl' : 'Hesap Oluştur',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Zaten hesabın var mı? Giriş Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
