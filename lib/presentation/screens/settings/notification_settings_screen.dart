import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/hive_service.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<String, bool> _values = {};
  bool _loading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'notif_events',
      'title': 'Etkinlik Hatırlatmaları',
      'subtitle': 'Yaklaşan etkinlikler için bildirimler',
      'icon': Icons.calendar_today_outlined,
      'iconColor': AppColors.cobalt,
      'defaultValue': true,
    },
    {
      'key': 'notif_tasks',
      'title': 'Görev Bildirimleri',
      'subtitle': 'Atanan ve yaklaşan görevler',
      'icon': Icons.check_circle_outline,
      'iconColor': AppColors.success,
      'defaultValue': true,
    },
    {
      'key': 'notif_emergency',
      'title': 'Acil Durum Uyarıları',
      'subtitle': 'Panik butonu ve güvenlik bildirimleri',
      'icon': Icons.warning_amber_rounded,
      'iconColor': AppColors.error,
      'defaultValue': true,
      'priority': true,
    },
    {
      'key': 'notif_chat',
      'title': 'Sohbet Bildirimleri',
      'subtitle': 'Mesajlar, duyurular ve etiketlemeler',
      'icon': Icons.chat_bubble_outline,
      'iconColor': const Color(0xFF8B5CF6),
      'defaultValue': true,
    },
    {
      'key': 'notif_location',
      'title': 'Konum Bildirimleri',
      'subtitle': 'Güvenli bölge giriş/çıkış uyarıları',
      'icon': Icons.location_on_outlined,
      'iconColor': const Color(0xFFF59E0B),
      'defaultValue': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    for (final cat in _categories) {
      final key = cat['key'] as String;
      final defaultValue = cat['defaultValue'] as bool;
      _values[key] = HiveService.getBoolSetting(key, defaultValue: defaultValue);
    }
    setState(() => _loading = false);
  }

  Future<void> _onChanged(String key, bool newValue) async {
    setState(() => _values[key] = newValue);
    await HiveService.setBoolSetting(key, newValue);
    await _syncToSupabase(key, newValue);
  }

  Future<void> _syncToSupabase(String settingKey, bool value) async {
    final client = SupabaseConfig.safeClient;
    final userId = AuthService.currentUserId;
    if (client == null || userId == null) return;

    try {
      // Önce mevcut ayarları çek
      final existing = await client
          .from('settings')
          .select('notifications')
          .eq('user_id', userId)
          .maybeSingle();

      final Map<String, dynamic> notifications =
          (existing?['notifications'] as Map<String, dynamic>?) ?? {};

      notifications[settingKey] = value;
      notifications['updated_at'] = DateTime.now().toIso8601String();

      await client.from('settings').upsert({
        'user_id': userId,
        'notifications': notifications,
      });
    } catch (e) {
      debugPrint('Supabase sync hatası: $e');
    }
  }

  String _displayValue(Map<String, dynamic> cat) {
    final key = cat['key'] as String;
    final value = _values[key] ?? cat['defaultValue'] as bool;

    if (cat['priority'] == true && value) {
      return 'Yüksek Öncelik';
    }
    return value ? 'Açık' : 'Kapalı';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Bildirim Ayarları',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SettingsSection(
                    title: 'BİLDİRİMLER',
                    icon: Icons.notifications_outlined,
                    children: _categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cat = entry.value;
                      final key = cat['key'] as String;
                      final value = _values[key] ?? cat['defaultValue'] as bool;
                      final isLast = index == _categories.length - 1;

                      return _NotificationCategoryTile(
                        title: cat['title'] as String,
                        subtitle: cat['subtitle'] as String,
                        icon: cat['icon'] as IconData,
                        iconColor: cat['iconColor'] as Color,
                        value: value,
                        displayValue: _displayValue(cat),
                        isLast: isLast,
                        onChanged: (v) => _onChanged(key, v),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotificationCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final String displayValue;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _NotificationCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.displayValue,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(isDark ? 35 : 30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    },
                    activeTrackColor: AppColors.cobalt,
                    activeThumbColor: Colors.white,
                    inactiveTrackColor: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                    inactiveThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 68,
                color: isDark
                    ? AppColors.darkBorder.withAlpha(80)
                    : AppColors.border.withAlpha(100),
              ),
          ],
        ),
      ),
    );
  }
}
