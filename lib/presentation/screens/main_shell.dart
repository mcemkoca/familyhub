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
      'label': 'Merkez',
    },
    {
      'route': AppRoutes.chat,
      'icon': Icons.forum_rounded,
      'label': 'Sohbet',
    },
    {
      'route': AppRoutes.kitchen,
      'icon': Icons.ramen_dining_rounded,
      'label': 'Mutfak',
    },
    {
      'route': AppRoutes.education,
      'icon': Icons.school_rounded,
      'label': 'Eğitim',
    },
    {
      'route': AppRoutes.settings,
      'icon': Icons.settings_rounded,
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
          left: 16,
          right: 16,
        ),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            // Koyu cam efekti (rgba(10,12,28,0.72)) + ince neon mor kenar.
            color: isDark
                ? const Color(0xB80A0C1C)
                : Colors.white.withAlpha(245),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF8B5CF6).withAlpha(60)
                  : Colors.white.withAlpha(200),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0),
                  _buildNavItem(1),
                  _buildFabSlot(),
                  _buildNavItem(2),
                  _buildNavItem(3),
                  _buildNavItem(4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isActive = _currentIndex == index;
    final tab = _tabs[index];
    final icon = tab['icon'] as IconData;
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
                    child: Icon(
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

  Widget _buildFabSlot() {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: Container(
            height: double.infinity,
            alignment: Alignment.topCenter,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4D8DFF), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(38), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withAlpha(120),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4D8DFF).withAlpha(70),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _menuOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
