import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../services/call_service.dart';
import '../widgets/hub_fab_menu.dart';
import 'call/voice_call_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  int _currentIndex = 0;
  bool _menuOpen = false;
  StreamSubscription<dynamic>? _incomingCallSub;

  final _tabs = [
    {
      'route': AppRoutes.hub,
      'icon': Icons.home_rounded,
      'asset': 'assets/icons/nav/merkez.png',
      'label': 'Merkez',
    },
    {
      'route': AppRoutes.chat,
      'icon': Icons.forum_rounded,
      'asset': 'assets/icons/nav/sohbet.png',
      'label': 'Sohbet',
    },
    {
      'route': AppRoutes.kitchen,
      'icon': Icons.ramen_dining_rounded,
      'asset': 'assets/icons/nav/mutfak.png',
      'label': 'Mutfak',
    },
    {
      'route': AppRoutes.education,
      'icon': Icons.school_rounded,
      'asset': 'assets/icons/nav/egitim.png',
      'label': 'Eğitim',
    },
    {
      'route': AppRoutes.settings,
      'icon': Icons.settings_rounded,
      'asset': 'assets/icons/nav/ayarlar.png',
      'label': 'Ayarlar',
    },
  ];

  @override
  void initState() {
    super.initState();
    CallService.startListeningIncomingCalls();
    _incomingCallSub = CallService.incomingCallStream.listen((session) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              session: session,
              initialMode: VoiceCallMode.incoming,
            ),
          ),
        );
      }
    });
    // Route değişimlerini dinle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndexWithRoute();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndexWithRoute();
  }

  void _syncIndexWithRoute() {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere(
      (t) => location == (t['route'] as String),
    );
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
      _menuOpen = false;
    });
    context.go(_tabs[index]['route'] as String);
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    CallService.stopListeningIncomingCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_menuOpen)
            HubFABMenu(
              isOpen: _menuOpen,
              onClose: () => setState(() => _menuOpen = false),
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeBottom > 0 ? 8 : 12,
          left: 14,
          right: 14,
        ),
        child: SizedBox(
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // İki cam pill yarısı + ortada FAB için boşluk.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: [
                    Expanded(child: _pill([0, 1])),
                    const SizedBox(width: 84), // FAB çentiği
                    Expanded(child: _pill([2, 3, 4])),
                  ],
                ),
              ),
              // Yükseltilmiş merkez FAB.
              Positioned(
                bottom: 16,
                child: _buildFab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tek bir cam pill yarısı — verilen sekme indeksleriyle.
  Widget _pill(List<int> indices) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xB80A0C1C) : Colors.white.withAlpha(245),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8B5CF6).withAlpha(55)
              : Colors.white.withAlpha(200),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final i in indices) _buildNavItem(i)],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isActive = _currentIndex == index;
    final tab = _tabs[index];
    final icon = tab['icon'] as IconData;
    final asset = tab['asset'] as String?;
    final label = tab['label'] as String;
    final badge = tab['badge'] as int?;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(index),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF6366F1).withAlpha(40)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isActive && isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withAlpha(60),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: asset != null
                        ? SizedBox(
                            width: isActive ? 28 : 25,
                            height: isActive ? 28 : 25,
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.55,
                              child: Image.asset(asset, fit: BoxFit.contain),
                            ),
                          )
                        : Icon(
                            icon,
                            size: isActive ? 26 : 24,
                            color: isActive
                                ? const Color(0xFF6366F1)
                                : (const Color(0xFF6B7280)),
                          ),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: 4,
                      right: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badge.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isActive ? 12 : 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF6C63FF)
                      : (const Color(0xFF8B8FA3)),
                ),
              ),
              const SizedBox(height: 3),
              // Aktif sekme altı neon gösterge çizgisi.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 3,
                width: isActive ? 20 : 0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4D8DFF), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: const Color(0xFF6C63FF).withAlpha(120),
                              blurRadius: 8),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleMenu,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withAlpha(140),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF4D8DFF).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: _menuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Image.asset(
            'assets/icons/nav/fab.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
