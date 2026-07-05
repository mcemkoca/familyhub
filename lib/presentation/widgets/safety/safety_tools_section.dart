import 'package:flutter/material.dart';
import '../../../core/ui_extensions.dart';
import '../settings/settings_item.dart';

class SafetyTool {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  SafetyTool({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    this.badge,
    required this.onTap,
  });
}

class SafetyToolsSection extends StatelessWidget {
  final List<SafetyTool> tools;

  const SafetyToolsSection({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            'GÜVENLİK ARAÇLARI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: 16.0.asRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < tools.length; i++) ...[
                SettingsItem(
                  icon: tools[i].icon,
                  iconColor: tools[i].iconColor,
                  label: tools[i].label,
                  description: tools[i].description,
                  showValue: tools[i].badge,
                  onTap: tools[i].onTap,
                  isLast: i == tools.length - 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
