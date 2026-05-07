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
    {'icon': Icons.calendar_today, 'label': 'Planla', 'color': AppColors.cobalt, 'route': AppRoutes.calendar},
    {'icon': Icons.check_box, 'label': 'Görev', 'color': AppColors.softMint, 'route': AppRoutes.tasks},
    {'icon': Icons.chat_bubble, 'label': 'Mesaj', 'color': AppColors.purple, 'route': AppRoutes.chat},
    {'icon': Icons.warning_amber, 'label': 'Acil', 'color': AppColors.error, 'route': AppRoutes.emergency},
    {'icon': Icons.settings, 'label': 'Ayarlar', 'color': AppColors.slate, 'route': AppRoutes.settings},
  ];

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(100),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 110,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + (i * 60)),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Transform.translate(
                      offset: Offset(0, isOpen ? 0 : 20),
                      child: Transform.scale(
                        scale: isOpen ? 1.0 : 0.0,
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
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [item['color'] as Color, (item['color'] as Color).withAlpha(180)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: (item['color'] as Color).withAlpha(80), blurRadius: 12)],
                            ),
                            child: Icon(item['icon'] as IconData, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
