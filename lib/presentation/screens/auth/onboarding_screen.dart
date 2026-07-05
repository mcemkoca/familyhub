import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedLanguage = 'tr';

  // Feature slides (indices 1-3; index 0 = language, index 4 = family setup)
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

  // Total pages: language (0) + slides + family setup (last)
  int get _totalPages => 1 + _slides.length + 1;
  int get _familyPageIndex => _totalPages - 1;

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
    if (_currentPage < _familyPageIndex) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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

  // Dil kodu → Hive'da saklanan tam etiket ve locale (localeProvider ve
  // içerik/para birimi özellikleri bu etiketi okur).
  static const Map<String, ({String label, Locale locale})> _langMap = {
    'tr': (label: 'Türkçe', locale: Locale('tr', 'TR')),
    'fr': (label: 'Français', locale: Locale('fr', 'FR')),
    'nl': (label: 'Nederlands', locale: Locale('nl', 'NL')),
    'en': (label: 'English', locale: Locale('en', 'US')),
  };

  void _selectLanguage(String code) {
    setState(() => _selectedLanguage = code);
    final entry = _langMap[code] ?? _langMap['tr']!;
    // Seçimi kalıcılaştır — yeniden açılışta ve içerik özelliklerinde korunur.
    HiveService.setSetting('language', entry.label);
    ref.read(localeProvider.notifier).state = entry.locale;
  }

  String get _nextLabel {
    if (_currentPage == 0) return _localizedNext;
    if (_currentPage == _familyPageIndex - 1) return _localizedLetsGo;
    return _localizedNext;
  }

  // Simple inline translations for onboarding (before full l10n loads)
  String get _localizedNext {
    switch (_selectedLanguage) {
      case 'fr': return 'Suivant';
      case 'nl': return 'Volgende';
      case 'en': return 'Next';
      default: return 'İleri';
    }
  }

  String get _localizedLetsGo {
    switch (_selectedLanguage) {
      case 'fr': return 'Allons-y';
      case 'nl': return 'Laten we gaan';
      case 'en': return 'Let\'s go';
      default: return 'Başla';
    }
  }

  String get _localizedSkip {
    switch (_selectedLanguage) {
      case 'fr': return 'Passer';
      case 'nl': return 'Overslaan';
      case 'en': return 'Skip';
      default: return 'Atla';
    }
  }

  String get _chooseLanguageLabel {
    switch (_selectedLanguage) {
      case 'fr': return 'Choisissez votre langue';
      case 'nl': return 'Kies uw taal';
      case 'en': return 'Choose your language';
      default: return 'Dilinizi Seçin';
    }
  }

  String get _familySetupTitle {
    switch (_selectedLanguage) {
      case 'fr': return 'Commencer avec votre famille';
      case 'nl': return 'Begin met uw familie';
      case 'en': return 'Start with your family';
      default: return 'Ailenizle Başlayın';
    }
  }

  String get _createFamilyLabel {
    switch (_selectedLanguage) {
      case 'fr': return 'Créer une nouvelle famille';
      case 'nl': return 'Nieuwe familie aanmaken';
      case 'en': return 'Create a new family';
      default: return 'Yeni Aile Oluştur';
    }
  }

  String get _joinFamilyLabel {
    switch (_selectedLanguage) {
      case 'fr': return 'Rejoindre avec un code';
      case 'nl': return 'Deelnemen met een code';
      case 'en': return 'Join with a code';
      default: return 'Davet Koduyla Katıl';
    }
  }

  String get _orLabel {
    switch (_selectedLanguage) {
      case 'fr': return 'ou';
      case 'nl': return 'of';
      case 'en': return 'or';
      default: return 'veya';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (hide on family setup page)
            if (_currentPage < _familyPageIndex)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      _localizedSkip,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildLanguagePage();
                  if (index == _familyPageIndex) return _buildFamilySetupPage();
                  return _buildFeaturePage(_slides[index - 1]);
                },
              ),
            ),

            // Dots + next button (hide on family setup page which has its own CTAs)
            if (_currentPage < _familyPageIndex)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF8B5CF6)
                                : const Color(0x1EFFFFFF),
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
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _nextLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePage() {
    const languages = [
      {'code': 'tr', 'flag': '🇹🇷', 'name': 'Türkçe'},
      {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
      {'code': 'nl', 'flag': '🇳🇱', 'name': 'Nederlands'},
      {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.language, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          Text(
            _chooseLanguageLabel,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...languages.map((lang) {
            final isSelected = _selectedLanguage == lang['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectLanguage(lang['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withAlpha(30)
                        : const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0x1EFFFFFF),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF6366F1),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeaturePage(Map<String, String> slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            slide['image']!,
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.family_restroom,
                color: Colors.white,
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide['title']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide['desc']!,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySetupPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.family_restroom, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 32),
          Text(
            _familySetupTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'FamilyHub',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Create family button (gradient)
          SizedBox(
            width: double.infinity,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _markOnboardingDone();
                  if (mounted) context.go(AppRoutes.register);
                },
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: Text(
                  _createFamilyLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(child: Divider(color: Color(0x1EFFFFFF))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _orLabel,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ),
              const Expanded(child: Divider(color: Color(0x1EFFFFFF))),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _markOnboardingDone();
                if (mounted) context.go(AppRoutes.joinFamily);
              },
              icon: const Icon(Icons.group_add_outlined, size: 22),
              label: Text(
                _joinFamilyLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () async {
              await _markOnboardingDone();
              if (mounted) context.go(AppRoutes.login);
            },
            child: Text(
              _localizedSkip,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
