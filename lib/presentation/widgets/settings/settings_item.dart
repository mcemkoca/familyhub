import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../core/ui_extensions.dart';

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
    final isDark = context.isDark;
    final textColor = isDanger
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.dark);

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDanger
                          ? AppColors.error.alphaLow
                          : iconColor.withAlpha(isDark ? 35 : 30),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
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
                  if (showValueWidget != null)
                    showValueWidget!
                  else if (showValue != null)
                    Text(
                      showValue!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightGray,
                    size: 20,
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
