import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/child_auth_service.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _featuresController;
  late AnimationController _glowController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _featuresOpacity;
  late Animation<double> _glowPulse;

  static const _featurePills = [
    ('🏠', 'Aile Merkezi'),
    ('🍽️', 'Mutfak'),
    ('📚', 'Eğitim'),
    ('📍', 'Konum'),
    ('💬', 'Sohbet'),
    ('💳', 'Bütçe'),
  ];

  @override
  void initState() {
    super.initState();

    // Phase 1: Logo (0–1.4s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Phase 2: Text (1.0–2.2s)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Phase 3: Feature pills (2.0–3.5s)
    _featuresController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _featuresOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeOut),
    );

    // Phase 4: Glow pulse (3.0–5.0s)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowPulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimationSequence();
    _navigateAfterDelay();
  }

  Future<void> _startAnimationSequence() async {
    // Logo pop-in
    _logoController.forward();

    // Text slide-up after 1s
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _textController.forward();

    // Feature pills after 2s
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _featuresController.forward();

    // Glow pulse after 3s
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _glowController.repeat(reverse: true);
  }

  Future<void> _navigateAfterDelay() async {
    // 5 second intro
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    // Wait for Supabase init
    var attempts = 0;
    while (SupabaseConfig.safeClient == null && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      if (!mounted) return;
    }

    try {
      await AuthService.restoreSession();

      final childSessionRestored = await ChildAuthService.restoreSession();
      if (childSessionRestored && ChildAuthService.isChildMode) {
        if (mounted) context.go(AppRoutes.childDashboard);
        return;
      }

      final isAuth = AuthService.currentUser != null;
      if (isAuth) {
        if (mounted) context.go(AppRoutes.hub);
        return;
      }

      final onboardingDone = HiveService.getOnboardingCompleted();
      ref.read(onboardingCompletedProvider.notifier).state = onboardingDone;

      if (!onboardingDone) {
        if (mounted) context.go(AppRoutes.onboarding);
      } else {
        if (mounted) context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _featuresController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF9A56),
              Color(0xFFFF6B95),
              Color(0xFFC850C0),
              Color(0xFF6C63FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -60,
              right: -60,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Opacity(
                  opacity: 0.15 * _glowPulse.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Opacity(
                  opacity: 0.10 * _glowPulse.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App name + tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withAlpha(50)),
                              ),
                              child: const Text(
                                'Ailenizin kalbi burada atıyor ❤️',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Feature pills
                  AnimatedBuilder(
                    animation: _featuresController,
                    builder: (_, __) => Opacity(
                      opacity: _featuresOpacity.value,
                      child: _buildFeaturePills(),
                    ),
                  ),

                  const Spacer(),

                  // Bottom family illustration row
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: _buildFamilyRow(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Loading dots
                  _LoadingDots(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) => Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha((40 + 30 * _glowPulse.value).round()),
              blurRadius: 40,
              spreadRadius: 8,
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
    );
  }

  Widget _buildFeaturePills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: _featurePills.map((pill) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withAlpha(50), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pill.$1,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  pill.$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFamilyRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _FloatingMember('👩', 'Anne', Color(0xFFF093FB)),
        SizedBox(width: 12),
        _FloatingMember('👨', 'Baba', Color(0xFF4FACFE)),
        SizedBox(width: 12),
        _FloatingMember('👧', 'Çocuk', Color(0xFF43E97B)),
        SizedBox(width: 12),
        _FloatingMember('👦', 'Çocuk', Color(0xFFFDA085)),
      ],
    );
  }
}

class _FloatingMember extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _FloatingMember(this.emoji, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withAlpha(60),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
          ),
          child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2))
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((opacity * 255).round()),
              ),
            );
          }),
        );
      },
    );
  }
}
