import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final String? showValue;
  final Widget? showValueWidget;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isLast;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    this.showValue,
    this.showValueWidget,
    required this.onTap,
    this.isDanger = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDanger ? AppColors.error : Theme.of(context).colorScheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      hint: description,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDanger
                          ? AppColors.error.withAlpha(25)
                          : iconColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isDanger ? AppColors.error : iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
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
                  if (showValueWidget != null)
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                      child: showValueWidget!,
                    )
                  else if (showValue != null)
                    Text(
                      showValue!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                    size: 20,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 64,
                endIndent: 0,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
      ),
    );
  }
}
