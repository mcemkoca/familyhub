import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../services/hive_service.dart';
import '../../widgets/settings/screen_header.dart';

/// Ana Ekran Özelleştirme (FamilyWall "Customize Home Screen").
/// Akıllı Kart / İpuçları gösterimini ve kutucuk sırasını yönetir.
class HubCustomizeScreen extends StatefulWidget {
  const HubCustomizeScreen({super.key});

  @override
  State<HubCustomizeScreen> createState() => _HubCustomizeScreenState();
}

class _HubCustomizeScreenState extends State<HubCustomizeScreen> {
  bool _smartCard = true;
  bool _tips = true;

  // Hub modülleri (route, etiket, ikon) — sıralama için.
  static final List<(String, String, IconData)> _tiles = [
    (AppRoutes.shopping, 'Alışveriş', Icons.shopping_cart_outlined),
    (AppRoutes.kitchen, 'Mutfak', Icons.restaurant_outlined),
    (AppRoutes.childManagement, 'Çocuk', Icons.child_care_outlined),
    (AppRoutes.childDevelopment, 'Gelişim', Icons.eco_outlined),
    (AppRoutes.familyHealth, 'Sağlık', Icons.monitor_heart_outlined),
    (AppRoutes.familyMap, 'Konum', Icons.map_outlined),
    (AppRoutes.emergency, 'Acil', Icons.emergency_outlined),
    (AppRoutes.budget, 'Bütçe', Icons.account_balance_wallet_outlined),
    (AppRoutes.subscriptions, 'Ev Giderleri', Icons.receipt_long_outlined),
    (AppRoutes.gallery, 'Galeri', Icons.photo_library_outlined),
    (AppRoutes.education, 'Eğitim', Icons.menu_book_outlined),
    (AppRoutes.aiAssistant, 'AI', Icons.psychology_outlined),
    (AppRoutes.legalBenefits, 'Yasal Haklar', Icons.gavel_outlined),
    (AppRoutes.familyIntelligence, 'Aile Zekası', Icons.auto_awesome_mosaic_outlined),
    (AppRoutes.familyHubAI, 'FamilyHub AI', Icons.smart_toy_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _smartCard =
        HiveService.getBoolSetting('hub_show_smart_card', defaultValue: true);
    _tips = HiveService.getBoolSetting('hub_show_tips', defaultValue: true);
  }

  List<(String, String, IconData)> get _orderedTiles {
    final raw = HiveService.getSetting('hub_tile_order');
    if (raw == null || raw.isEmpty) return List.of(_tiles);
    final order = raw.split('|');
    final list = List.of(_tiles);
    list.sort((a, b) {
      final ia = order.indexOf(a.$1);
      final ib = order.indexOf(b.$1);
      return (ia < 0 ? 9999 : ia).compareTo(ib < 0 ? 9999 : ib);
    });
    return list;
  }

  Future<void> _saveOrder(List<(String, String, IconData)> tiles) async {
    await HiveService.setSetting(
        'hub_tile_order', tiles.map((t) => t.$1).join('|'));
  }

  void _openReorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReorderSheet(
        initial: _orderedTiles,
        onSave: _saveOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: 'Ana Ekranı Özelleştir',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('AKILLI KART SEÇENEKLERİ'),
          _card(Column(
            children: [
              _toggleTile(
                icon: Icons.dashboard_customize_outlined,
                color: const Color(0xFF6366F1),
                title: 'Akıllı Kartı Göster',
                subtitle:
                    'Aile aktivitesine dair hızlı güncellemeleri ana ekranda gösterir.',
                value: _smartCard,
                onChanged: (v) {
                  setState(() => _smartCard = v);
                  HiveService.setBoolSetting('hub_show_smart_card', v);
                },
              ),
              const Divider(height: 1, indent: 60, color: Color(0x14FFFFFF)),
              _toggleTile(
                icon: Icons.lightbulb_outline,
                color: const Color(0xFFF59E0B),
                title: 'İpuçlarını Göster',
                subtitle:
                    'Uygulama ve özellikler hakkında yararlı ipuçları (Keşfet) gösterir.',
                value: _tips,
                onChanged: (v) {
                  setState(() => _tips = v);
                  HiveService.setBoolSetting('hub_show_tips', v);
                },
              ),
            ],
          )),
          const SizedBox(height: 20),
          _sectionTitle('KUTUCUK SIRASI'),
          _card(
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openReorder,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apps,
                          color: Color(0xFF8B5CF6), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ana Ekran Kutucuklarını Düzenle',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE5E7EB))),
                          const SizedBox(height: 4),
                          const Text(
                            'Kutucukları yeniden sıralayarak ana ekranını kişiselleştir. '
                            'Düzenlemek için aşağıdaki butona bas.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Text(AppLocalizations.of(context).edit,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6366F1)
                                      .withAlpha(255))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF4B5563), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF6B7280))),
      );

  Widget _card(Widget child) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: child,
      );

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5E7EB))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF6B7280), height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6366F1),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// Kutucuk yeniden sıralama sheet'i.
class _ReorderSheet extends StatefulWidget {
  final List<(String, String, IconData)> initial;
  final Future<void> Function(List<(String, String, IconData)>) onSave;
  const _ReorderSheet({required this.initial, required this.onSave});

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late List<(String, String, IconData)> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Kutucukları Sürükle-Sırala',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.onSave(_items);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Kaydet',
                        style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _items.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final it = _items.removeAt(oldIndex);
                    _items.insert(newIndex, it);
                  });
                },
                itemBuilder: (context, i) {
                  final t = _items[i];
                  return Container(
                    key: ValueKey(t.$1),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(t.$3, color: const Color(0xFF9CA3AF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle,
                              color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
