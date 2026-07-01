import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../services/child_auth_service.dart';
import '../../../services/child_notification_service.dart';
import '../../../services/location_tracking_service.dart';
import 'tabs/child_achievements_tab.dart';
import 'tabs/child_chat_tab.dart';
import 'tabs/child_home_tab.dart';
import 'tabs/child_safety_tab.dart';
import 'tabs/child_schedule_tab.dart';
import 'tabs/child_tasks_tab.dart';

class ChildDashboardScreen extends ConsumerStatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  ConsumerState<ChildDashboardScreen> createState() =>
      _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends ConsumerState<ChildDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ChildNotificationService.initialize();
    LocationTrackingService.startTracking();
  }

  @override
  void dispose() {
    ChildNotificationService.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await ChildAuthService.signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  void _onFabPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hızlı Aksiyon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _QuickActionTile(
                icon: Icons.chat_bubble_outline,
                label: 'Mesaj Gönder',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                },
              ),
              _QuickActionTile(
                icon: Icons.check_circle_outline,
                label: 'Görevlerime Git',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              _QuickActionTile(
                icon: Icons.calendar_today_outlined,
                label: 'Ders Programım',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 3);
                },
              ),
              _QuickActionTile(
                icon: Icons.location_on_outlined,
                label: 'Konumumu Paylaş',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to location share
                },
              ),
              _QuickActionTile(
                icon: Icons.auto_awesome,
                label: 'Akıllı Rotasyon',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  final currentSession = ChildAuthService.currentSession;
                  if (currentSession != null) {
                    context.push(
                      AppRoutes.smartRotation,
                      extra: currentSession.familyId,
                    );
                  }
                },
              ),
              _QuickActionTile(
                icon: Icons.timer,
                label: 'Güvenli Varış',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.safeArrival);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ChildAuthService.currentSession;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      ChildHomeTab(childName: session.childName),
      const ChildTasksTab(),
      const ChildChatTab(),
      ChildAchievementsTab(childName: session.childName),
      const ChildSafetyTab(),
    ];

    final navItems = [
      const _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Ana Sayfa',
      ),
      const _NavItem(
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        label: 'Görevlerim',
      ),
      const _NavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Sohbet',
      ),
      const _NavItem(
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events,
        label: 'Rozetler',
      ),
      const _NavItem(
        icon: Icons.shield_outlined,
        activeIcon: Icons.shield,
        label: 'Güvenlik',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3B82F6).withAlpha(20),
              child: const Icon(
                Icons.child_care,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Merhaba, ${session.childName}!',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 22),
            tooltip: 'Çıkış Yap',
            onPressed: _signOut,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _onFabPressed,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _ChildBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: navItems,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _ChildBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _ChildBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Left side: 2 tabs
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_buildNavItem(0), _buildNavItem(1)],
                ),
              ),
              // Space for FAB
              const SizedBox(width: 64),
              // Right side: 2 tabs
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(2),
                    _buildNavItem(3),
                    _buildNavItem(4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = selectedIndex == index;
    final item = items[index];
    final activeColor = const Color(0xFF3B82F6);
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
