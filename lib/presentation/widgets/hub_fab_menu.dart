import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';

class HubFABMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  const HubFABMenu({super.key, required this.isOpen, required this.onClose});

  final List<Map<String, dynamic>> _items = const [
    {'icon': Icons.shopping_cart_outlined, 'label': 'Alışveriş', 'color': AppColors.softMint,  'route': AppRoutes.shopping},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Bütçe',     'color': AppColors.cobalt,   'route': AppRoutes.budget},
    {'icon': Icons.photo_library_outlined,          'label': 'Galeri',    'color': AppColors.purple,   'route': AppRoutes.gallery},
    {'icon': Icons.location_on_outlined,            'label': 'Konum',     'color': AppColors.orange,   'route': AppRoutes.location},
    {'icon': Icons.child_care,                      'label': 'Çocuk',     'color': AppColors.pink,     'route': AppRoutes.childManagement},
    {'icon': Icons.warning_amber,                   'label': 'Acil',      'color': AppColors.error,    'route': AppRoutes.emergency},
  ];

  Widget _buildRow(BuildContext context, List<Map<String, dynamic>> items, int baseIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final i = baseIndex + entry.key;
        final item = entry.value;
        return AnimatedContainer(
          duration: Duration(milliseconds: 180 + (i * 50)),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onClose();
              context.push(item['route'] as String);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item['color'] as Color, (item['color'] as Color).withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: (item['color'] as Color).withAlpha(90), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(item['icon'] as IconData, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final row1 = _items.sublist(0, 3);
    final row2 = _items.sublist(3);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(120),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRow(context, row2, 3),
                  const SizedBox(height: 14),
                  _buildRow(context, row1, 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
