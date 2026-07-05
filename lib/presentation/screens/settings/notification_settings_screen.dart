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
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final Map<String, bool> _values = {};
  bool _loading = true;

  // Olay türü bildirimleri — uygulamamızın modüllerine uyarlanmış.
  final List<Map<String, dynamic>> _eventCategories = [
    {
      'key': 'notif_chat',
      'title': 'Mesajlar',
      'subtitle': 'Aile sohbeti ve etiketlemeler',
      'icon': Icons.chat_bubble_outline,
      'iconColor': const Color(0xFF6366F1),
      'defaultValue': true,
    },
    {
      'key': 'notif_notes',
      'title': 'Notlar & Duyurular',
      'subtitle': 'Aile notları ve duyurular',
      'icon': Icons.sticky_note_2_outlined,
      'iconColor': const Color(0xFF8B5CF6),
      'defaultValue': true,
    },
    {
      'key': 'notif_location',
      'title': 'Konum & Check-in',
      'subtitle': 'Güvenli bölge giriş/çıkış uyarıları',
      'icon': Icons.location_on_outlined,
      'iconColor': const Color(0xFFF59E0B),
      'defaultValue': true,
    },
    {
      'key': 'notif_gallery',
      'title': 'Fotoğraflar',
      'subtitle': 'Galeriye yeni eklenen anılar',
      'icon': Icons.photo_library_outlined,
      'iconColor': const Color(0xFFEC4899),
      'defaultValue': true,
    },
    {
      'key': 'notif_events',
      'title': 'Etkinlikler',
      'subtitle': 'Takvim etkinlikleri ve hatırlatmalar',
      'icon': Icons.event_outlined,
      'iconColor': const Color(0xFF06B6D4),
      'defaultValue': true,
    },
    {
      'key': 'notif_special_days',
      'title': 'Özel Günler',
      'subtitle': 'Doğum günleri ve yıldönümleri',
      'icon': Icons.cake_outlined,
      'iconColor': const Color(0xFFF472B6),
      'defaultValue': true,
    },
    {
      'key': 'notif_tasks',
      'title': 'Görevler & Listeler',
      'subtitle': 'Atanan görevler ve alışveriş listeleri',
      'icon': Icons.checklist_rtl_outlined,
      'iconColor': const Color(0xFF10B981),
      'defaultValue': true,
    },
    {
      'key': 'notif_timetable',
      'title': 'Ders Programı',
      'subtitle': 'Ajanda ve ders programı hatırlatmaları',
      'icon': Icons.view_timeline_outlined,
      'iconColor': const Color(0xFF6366F1),
      'defaultValue': true,
    },
    {
      'key': 'notif_budget',
      'title': 'Bütçe',
      'subtitle': 'Gider ve bütçe uyarıları',
      'icon': Icons.savings_outlined,
      'iconColor': const Color(0xFF22C55E),
      'defaultValue': true,
    },
    {
      'key': 'notif_documents',
      'title': 'Evrak',
      'subtitle': 'Belge son kullanma ve hatırlatmalar',
      'icon': Icons.description_outlined,
      'iconColor': const Color(0xFF3B82F6),
      'defaultValue': true,
    },
    {
      'key': 'notif_emergency',
      'title': 'Acil Durum',
      'subtitle': 'Panik butonu ve güvenlik uyarıları',
      'icon': Icons.warning_amber_rounded,
      'iconColor': AppColors.error,
      'defaultValue': true,
      'priority': true,
    },
  ];

  // Diğer bildirimler.
  final List<Map<String, dynamic>> _otherCategories = [
    {
      'key': 'notif_comments',
      'title': 'Yorumlar',
      'subtitle': 'Gönderilerinize gelen yorumlar',
      'icon': Icons.mode_comment_outlined,
      'iconColor': const Color(0xFF8B5CF6),
      'defaultValue': true,
    },
    {
      'key': 'notif_likes',
      'title': 'Beğeniler & En İyi Anlar',
      'subtitle': 'Beğeniler ve öne çıkan anılar',
      'icon': Icons.favorite_border,
      'iconColor': const Color(0xFFEF4444),
      'defaultValue': true,
    },
  ];

  List<Map<String, dynamic>> get _categories =>
      [..._eventCategories, ..._otherCategories];

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
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase sync hatası: $e');
    }
  }

  Widget _buildSection(
      String title, IconData icon, List<Map<String, dynamic>> cats) {
    return SettingsSection(
      title: title,
      icon: icon,
      children: cats.asMap().entries.map((entry) {
        final index = entry.key;
        final cat = entry.value;
        final key = cat['key'] as String;
        final value = _values[key] ?? cat['defaultValue'] as bool;
        final isLast = index == cats.length - 1;

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
    );
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
    final bg = const Color(0xFF0A0A0F);

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
                  child: _buildSection(
                    'BİLDİRİM TÜRÜ',
                    Icons.notifications_outlined,
                    _eventCategories,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSection(
                    'DİĞER BİLDİRİMLER',
                    Icons.more_horiz,
                    _otherCategories,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                      color: iconColor.withAlpha(35),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    },
                    activeTrackColor: const Color(0xFF6366F1),
                    activeThumbColor: Colors.white,
                    inactiveTrackColor: isDark
                        ? const Color(0x1EFFFFFF)
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
                    ? const Color(0x1EFFFFFF).withAlpha(80)
                    : const Color(0x1EFFFFFF).withAlpha(100),
              ),
          ],
        ),
      ),
    );
  }
}
