import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import 'package:go_router/go_router.dart';

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? rightAction;
  final Color? backgroundColor;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.rightAction,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkBackground : Colors.white);
    final safeTop = MediaQuery.of(context).viewPadding.top;

    return Container(
      color: bg,
      padding: EdgeInsets.only(top: safeTop),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkBorder.withAlpha(80)
                  : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (showBack)
              InkWell(
                onTap: onBack ?? () => context.pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                  ),
                ),
              )
            else
              const SizedBox(width: 40),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: rightAction,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
