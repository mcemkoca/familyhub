import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/constants.dart';
import '../../../../core/validation/input_validator.dart';
import '../../../../services/auth_service.dart';

class AccountStep extends StatefulWidget {
  final Function(String name, String email, String password, String? familyId, String userId) onAccountCreated;

  const AccountStep({super.key, required this.onAccountCreated});

  @override
  State<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<AccountStep> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _familyCodeController = TextEditingController();
  final _familyNameController = TextEditingController();
  bool _hasFamilyCode = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  Future<void> _createAccount() async {
    HapticFeedback.mediumImpact();

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
      final result = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        familyName: _hasFamilyCode ? null : _familyNameController.text.trim(),
      );

      widget.onAccountCreated(
        name,
        email,
        password,
        result.familyId,
        result.response.user!.id,
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
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
    _emailController.dispose();
    _passwordController.dispose();
    _familyCodeController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesap ve Aile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 4),
            const Text(
            'FamilyHub hesabınızı oluşturun',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          // Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(12),
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
                            ? (const Color(0xFF0A0A0F))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Yeni Aile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: !_hasFamilyCode ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
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
                            ? (const Color(0xFF0A0A0F))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Aileye Katıl',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _hasFamilyCode ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Ad Soyad',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'E-posta',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
            helperText: 'En az 8 karakter, büyük/küçük harf, rakam ve özel karakter',
          ),
          const SizedBox(height: 16),
          if (_hasFamilyCode)
            _buildTextField(
              controller: _familyCodeController,
              label: 'Aile Kodu',
              icon: Icons.key_outlined,
              hintText: 'Örn: FH-123456',
            )
          else
            _buildTextField(
              controller: _familyNameController,
              label: 'Aile Adı',
              icon: Icons.home_outlined,
              hintText: 'Örn: Yılmaz Ailesi',
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                activeColor: const Color(0xFF6366F1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: const Text(
                    'Kullanım koşullarını ve gizlilik politikasını okudum ve kabul ediyorum.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Hesap Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hintText,
    String? helperText,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFF13131A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
