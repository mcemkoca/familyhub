import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';

/// Sade, tek-logo açılış ekranı — uygulamanın koyu premium temasıyla tutarlı.
/// Ortada tek marka logosu + hafif parıltı + yükleniyor noktaları.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _logoScale = Tween<double>(begin: 0.7, end: 1.0)
      .animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
  late final Animation<double> _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
  late final Animation<double> _glowPulse = Tween<double>(begin: 0.6, end: 1.0)
      .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _logoController.forward();
    _glowController.repeat(reverse: true);
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Supabase init'i bekle (genelde hızlı; en çok ~3 sn).
    var attempts = 0;
    while (SupabaseConfig.safeClient == null && attempts < 30) {
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

      if (AuthService.currentUser != null) {
        await AuthService.ensureFamily();
        if (mounted) context.go(AppRoutes.hub);
        return;
      }

      final onboardingDone = HiveService.getOnboardingCompleted();
      ref.read(onboardingCompletedProvider.notifier).state = onboardingDone;
      if (mounted) {
        context.go(onboardingDone ? AppRoutes.login : AppRoutes.onboarding);
      }
    } catch (e) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_logoController, _glowController]),
              builder: (_, _) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF)
                              .withAlpha((60 + 60 * _glowPulse.value).round()),
                          blurRadius: 44,
                          spreadRadius: 6,
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
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _logoController,
              builder: (_, _) => Opacity(
                opacity: _logoOpacity.value,
                child: const Text(
                  'FamilyHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _LoadingDots(),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity =
                (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2)).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF)
                    .withAlpha((opacity * 255).round()),
              ),
            );
          }),
        );
      },
    );
  }
}
