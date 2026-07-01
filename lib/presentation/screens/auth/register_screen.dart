import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import '../../providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _familyCodeController = TextEditingController();
  final _familyNameController = TextEditingController();

  bool _hasFamilyCode = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  String _selectedRole = 'anne-baba';

  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  static const _roles = [
    ('anne-baba', '👩‍👧', 'Ebeveyn', Color(0xFFFF6B95)),
    ('buyukanne-buyukbaba', '👴', 'Büyükanne/baba', Color(0xFF4FACFE)),
    ('diger', '❤️', 'Aile Üyesi', Color(0xFF43E97B)),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  Future<void> _register() async {
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final nameError = InputValidator.validateName(name);
    if (nameError != null) { _showError(nameError); return; }
    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) { _showError(emailError); return; }
    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) { _showError(passwordError); return; }
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
        familyName:
            _hasFamilyCode ? null : _familyNameController.text.trim(),
      );
      if (mounted) {
        _showSuccess('Aileniz oluşturuldu! Hoş geldiniz 🎉');
        context.go(AppRoutes.hub);
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (previous, next) {
      if (next == true && mounted) context.go(AppRoutes.hub);
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient top
          Container(
            height: size.height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFFA18CD1), Color(0xFFFBC2EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.7,
            child: Container(color: Colors.white),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button + title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withAlpha(60)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo_full.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'FamilyHub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Ailenizin dijital yuvası',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Scrollable form card
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (_, __) => Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4FACFE).withAlpha(30),
                                  blurRadius: 30,
                                  offset: const Offset(0, -4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Mode toggle
                                  _buildModeToggle(),
                                  const SizedBox(height: 20),

                                  // Role selector
                                  if (!_hasFamilyCode) ...[
                                    const Text(
                                      'Ailedeki Rolünüz',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildRoleSelector(),
                                    const SizedBox(height: 16),
                                  ],

                                  // Name
                                  _buildField(
                                    controller: _nameController,
                                    label: 'Ad Soyad',
                                    emoji: '👤',
                                    action: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),

                                  // Email
                                  _buildField(
                                    controller: _emailController,
                                    label: 'E-posta adresiniz',
                                    emoji: '📧',
                                    keyboardType: TextInputType.emailAddress,
                                    action: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),

                                  // Password
                                  _buildPasswordField(),
                                  const SizedBox(height: 12),

                                  // Family code or name
                                  if (_hasFamilyCode)
                                    _buildField(
                                      controller: _familyCodeController,
                                      label: 'Aile Kodu (Örn: FH-123456)',
                                      emoji: '🔑',
                                      action: TextInputAction.done,
                                    )
                                  else
                                    _buildField(
                                      controller: _familyNameController,
                                      label: 'Aile Adı (Örn: Yılmaz Ailesi)',
                                      emoji: '🏠',
                                      action: TextInputAction.done,
                                    ),
                                  const SizedBox(height: 16),

                                  // Terms
                                  _buildTermsRow(),
                                  const SizedBox(height: 20),

                                  // Submit button
                                  _buildSubmitButton(),
                                  const SizedBox(height: 16),

                                  // Back to login
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => context.pop(),
                                      child: const Text.rich(
                                        TextSpan(
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280)),
                                          children: [
                                            TextSpan(
                                                text: 'Zaten hesabın var mı? '),
                                            TextSpan(
                                              text: 'Giriş Yap →',
                                              style: TextStyle(
                                                color: Color(0xFF4FACFE),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _toggleBtn('🏠 Yeni Aile Kur', !_hasFamilyCode,
              () => setState(() => _hasFamilyCode = false)),
          _toggleBtn('👪 Aileye Katıl', _hasFamilyCode,
              () => setState(() => _hasFamilyCode = true)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFFA18CD1)],
                  )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF4FACFE).withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: _roles.map((role) {
        final (id, emoji, label, color) = role;
        final selected = _selectedRole == id;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? color.withAlpha(25) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : const Color(0xFFE5E7EB),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: selected ? color : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String emoji,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: action,
        onSubmitted: action == TextInputAction.done ? (_) => _register() : null,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '$emoji  ',
          prefixStyle: const TextStyle(fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          floatingLabelStyle:
              const TextStyle(color: Color(0xFF4FACFE), fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Şifre (en az 8 karakter)',
          prefixText: '🔒  ',
          prefixStyle: const TextStyle(fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          floatingLabelStyle:
              const TextStyle(color: Color(0xFF4FACFE), fontSize: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: _acceptedTerms
                  ? const LinearGradient(
                      colors: [Color(0xFF4FACFE), Color(0xFFA18CD1)],
                    )
                  : null,
              color: _acceptedTerms ? null : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptedTerms
                    ? const Color(0xFF4FACFE)
                    : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                children: [
                  TextSpan(text: 'Kullanım koşullarını ve '),
                  TextSpan(
                    text: 'gizlilik politikasını',
                    style: TextStyle(
                        color: Color(0xFF4FACFE),
                        fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' okudum ve kabul ediyorum.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _register,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? const LinearGradient(
                  colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)])
              : const LinearGradient(
                  colors: [
                    Color(0xFF4FACFE),
                    Color(0xFFA18CD1),
                    Color(0xFFFBC2EB),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF4FACFE).withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _hasFamilyCode ? '👪 Aileye Katıl' : '🏠 Aile Kur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
