import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/validation/input_validator.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/localization/locale_service.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  /// Girişte backend'deki dil tercihini uygula — yalnızca kullanıcı henüz
  /// yerel bir dil kararı vermediyse (açık seçimi ASLA ezmez). Best-effort.
  Future<void> _applyBackendLocale() async {
    final loc = await LocaleService.syncFromBackend();
    if (loc != null && mounted) {
      ref.read(localeProvider.notifier).state = loc;
    }
  }

  Future<void> _login() async {
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) { _showError(emailError); return; }
    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) { _showError(passwordError); return; }

    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(email: email, password: password);
      await AuthService.ensureFamily();
      await _applyBackendLocale();
      if (mounted) context.go(AppRoutes.hub);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      await AuthService.ensureFamily();
      await _applyBackendLocale();
      if (mounted) context.go(AppRoutes.hub);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final available = await BiometricService.isAvailable();
    if (!available) { _showError('Biyometrik kimlik doğrulama desteklenmiyor'); return; }
    final success = await BiometricService.authenticate();
    if (success && mounted) {
      if (AuthService.currentUser != null) {
        context.go(AppRoutes.hub);
      } else {
        _showError('Önce e-posta ile giriş yapın, sonra parmak izi aktif olur');
      }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (previous, next) {
      if (next == true && mounted) context.go(AppRoutes.hub);
    });

    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background (top 45%)
          Container(
            height: size.height * 0.48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9A56), Color(0xFFFF6B95), Color(0xFFC850C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Theme-aware bottom background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6,
            child: Container(
              color: isDark ? const Color(0xFF0A0A0F) : Colors.white,
            ),
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top hero section
                  SizedBox(height: size.height * 0.04),
                  _buildHero(),
                  const SizedBox(height: 24),

                  // Sliding card
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (_, _) => Opacity(
                      opacity: _cardOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _cardSlide.value),
                        child: _buildCard(size, isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        // FamilyHub Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo_full.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ailenize Hoş Geldiniz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Birlikte daha güçlüsünüz 💪',
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Size size, bool isDark) {
    final cardColor = isDark ? const Color(0xFF13131A) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B95).withAlpha(30),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).login,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A56), Color(0xFFFF6B95)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('👨‍👩‍👧‍👦 Aile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email field
            _buildField(
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocus: _passwordFocus,
              label: 'E-posta adresiniz',
              emoji: '📧',
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Password field
            _buildPasswordField(isDark: isDark),
            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B95),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(AppLocalizations.of(context).sifremiunuttum1,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),

            // Login button
            _buildGradientButton(
              label: _isLoading ? null : 'Giriş Yap',
              onTap: _isLoading ? null : _login,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A56), Color(0xFFFF6B95), Color(0xFFC850C0)],
              ),
              shadowColor: const Color(0xFFFF6B95).withAlpha(100),
            ),
            const SizedBox(height: 14),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('veya',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),

            // Google sign in
            _buildSocialButton(
              label: AppLocalizations.of(context).googleIleGirisYap,
              icon: const Text('G',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
              onTap: _isLoading
                  ? null
                  : AuthService.isGoogleSignInConfigured
                      ? _signInWithGoogle
                      : () => _showError('Google Sign-In şu an kullanılamıyor.'),
              enabled: AuthService.isGoogleSignInConfigured,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Biometric
            _buildSocialButton(
              label: AppLocalizations.of(context).parmakIziIleGiris,
              icon: const Icon(Icons.fingerprint, size: 20, color: Color(0xFF8B5CF6)),
              onTap: _isLoading ? null : _biometricLogin,
              enabled: true,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Child login
            GestureDetector(
              onTap: _isLoading ? null : () => context.push(AppRoutes.childLogin),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1007) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF7C3A00) : const Color(0xFFFED7AA),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⭐', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Çocuk Girişi (PIN ile)',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Register link
            Center(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.register),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    children: const [
                      TextSpan(text: 'Hesabın yok mu? '),
                      TextSpan(
                        text: 'Aile Kur →',
                        style: TextStyle(
                          color: Color(0xFFC850C0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String emoji,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool isDark = false,
  }) {
    final fieldBg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0x1EFFFFFF) : const Color(0xFFE5E7EB);
    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: action,
        onSubmitted: (_) {
          if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
        },
        decoration: InputDecoration(
          labelText: label,
          prefixText: '$emoji  ',
          prefixStyle: const TextStyle(fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          floatingLabelStyle:
              const TextStyle(color: Color(0xFFFF6B95), fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordField({bool isDark = false}) {
    final fieldBg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0x1EFFFFFF) : const Color(0xFFE5E7EB);
    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _login(),
        decoration: InputDecoration(
          labelText: 'Şifreniz',
          prefixText: '🔒  ',
          prefixStyle: const TextStyle(fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          floatingLabelStyle:
              const TextStyle(color: Color(0xFFFF6B95), fontSize: 12),
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

  Widget _buildGradientButton({
    required String? label,
    required VoidCallback? onTap,
    required Gradient gradient,
    required Color shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? const LinearGradient(colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)])
              : gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null
              ? []
              : [BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: label == null
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
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

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback? onTap,
    required bool enabled,
    bool isDark = false,
  }) {
    final btnBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = isDark ? const Color(0x1EFFFFFF) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 20 : 8),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
