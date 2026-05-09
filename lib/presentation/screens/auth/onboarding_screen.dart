import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../services/hive_service.dart';
import '../../../services/onboarding_service.dart';
import '../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/onboarding/onboarding_1.png',
      'title': 'Güvende Kalın',
      'desc': 'Canlı konum paylaşımı ve acil durum butonu ile ailenizi koruyun.',
    },
    {
      'image': 'assets/images/onboarding/onboarding_2.png',
      'title': 'Aileniz Bir Arada',
      'desc': 'Tüm aile üyelerinizi tek bir yerden yönetin, organize olun.',
    },
    {
      'image': 'assets/images/onboarding/onboarding_3.png',
      'title': 'Organize Olun',
      'desc': 'Görevler, takvim etkinlikleri ve alışveriş listeleri ile hayatı kolaylaştırın.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _maybeLoadRemoteSlides();
  }

  Future<void> _maybeLoadRemoteSlides() async {
    final remoteSlides = await OnboardingService.getSlides();
    if (remoteSlides.isNotEmpty && mounted) {
      setState(() => _slides = remoteSlides);
    }
  }

  void _nextPage() async {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _markOnboardingDone();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  void _skip() async {
    await _markOnboardingDone();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _markOnboardingDone() async {
    await HiveService.setOnboardingCompleted(true);
    ref.read(onboardingCompletedProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Onboarding image
                        Image.asset(
                          _slides[index]['image']!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.purple, AppColors.pink],
                                ),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const Icon(
                                Icons.family_restroom,
                                color: Colors.white,
                                size: 80,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _slides[index]['title']!,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _slides[index]['desc']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.gray,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.purple
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Başla'
                            : 'İleri',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
