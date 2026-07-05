import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onToggle;

  const SettingsToggle({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: description,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onToggle(v);
              },
              activeTrackColor: const Color(0xFF6366F1),
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF1F2937),
              inactiveThumbColor: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
