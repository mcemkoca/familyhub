import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  int _step = 0; // 0 = email, 1 = security questions, 2 = new password, 3 = success
  String _email = '';
  String? _question1;
  String? _question2;

  final _emailController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;



  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final error = InputValidator.validateEmail(email);
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final questions = await AuthService.getSecurityQuestionsByEmail(email);
      if (questions == null) {
        _showError('Bu e-posta adresiyle kayıtlı bir hesap bulunamadı');
        return;
      }
      _email = email;
      _question1 = questions['security_question_1'] as String?;
      _question2 = questions['security_question_2'] as String?;

      // If user has not set security questions, skip to reset email
      if (_question1 == null ||
          _question1!.isEmpty ||
          _question2 == null ||
          _question2!.isEmpty) {
        await _sendResetEmail();
        return;
      }

      setState(() => _step = 1);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAnswers() async {
    final ans1 = _answer1Controller.text.trim();
    final ans2 = _answer2Controller.text.trim();

    if (ans1.isEmpty || ans2.isEmpty) {
      _showError('Her iki güvenlik sorusunu da cevaplayın');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final valid = await AuthService.verifySecurityAnswers(
        _email,
        ans1,
        ans2,
      );
      if (!valid) {
        _showError('Güvenlik sorularının cevapları hatalı');
        return;
      }
      setState(() => _step = 2);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.isEmpty || confirm.isEmpty) {
      _showError('Tüm alanları doldurun');
      return;
    }

    final validation = InputValidator.validatePassword(newPass);
    if (validation != null) {
      _showError(validation);
      return;
    }

    if (newPass != confirm) {
      _showError('Şifreler eşleşmiyor');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPasswordForEmailWithVerification(_email, newPass);
      setState(() => _step = 3);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(_email);
      if (mounted) {
        _showSuccess('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go(AppRoutes.login);
        });
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
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
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5E7EB)),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(
            color: Color(0xFFE5E7EB),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(isDark, accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, Color accentColor) {
    switch (_step) {
      case 0:
        return _buildEmailStep(isDark, accentColor);
      case 1:
        return _buildSecurityQuestionsStep(isDark, accentColor);
      case 2:
        return _buildNewPasswordStep(isDark, accentColor);
      case 3:
        return _buildSuccessStep(isDark, accentColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey('email_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_reset, color: accentColor, size: 32),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Şifrenizi mi unuttunuz?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Hesabınıza ait e-posta adresini girin. Güvenlik sorularınız varsa onları cevaplayıp şifrenizi değiştirebilirsiniz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitEmail(),
          decoration: InputDecoration(
            labelText: 'E-posta Adresi',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(
                color: Color(0x1EFFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Devam Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(AppLocalizations.of(context).girisEkraninaDon),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityQuestionsStep(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey('security_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, color: Color(0xFF10B981), size: 32),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Güvenlik Doğrulaması',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Hesabınızı korumak için lütfen kayıtlı güvenlik sorularınızı cevaplayın.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: const Color(0x1EFFFFFF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _question1 ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _answer1Controller,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Cevabınızı yazın',
                  filled: true,
                  fillColor: const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0x1EFFFFFF),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: const Color(0x1EFFFFFF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _question2 ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _answer2Controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyAnswers(),
                decoration: InputDecoration(
                  hintText: 'Cevabınızı yazın',
                  filled: true,
                  fillColor: const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0x1EFFFFFF),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Doğrula ve Devam Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey('password_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline, color: accentColor, size: 32),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Yeni Şifre Belirle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Güvenlik doğrulamanız başarılı. Lütfen yeni şifrenizi belirleyin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Yeni Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            helperText: 'En az 8 karakter, büyük/küçük harf, rakam ve özel karakter',
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(
                color: Color(0x1EFFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _changePassword(),
          decoration: InputDecoration(
            labelText: 'Yeni Şifre (Tekrar)',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(
                color: Color(0x1EFFFFFF),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Şifremi Değiştir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey('success_step'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          'Şifreniz Güncellendi!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Yeni şifrenizle giriş yapabilirsiniz. Hesabınızın güvenliği için güvenlik sorularınızı düzenli olarak güncellemenizi öneririz.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: const Text(
              'Giriş Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}


