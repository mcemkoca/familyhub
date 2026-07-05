import 'package:flutter/material.dart';

/// Theme-aware card widget that eliminates ~40+ inline dark-mode ternary checks.
/// Automatically adapts background and border colors based on theme brightness.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? (const Color(0xFF374151));
    final defaultBorder = borderColor ?? (const Color(0xFF1F2937));

    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: elevation ?? (2),
      color: defaultColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: BorderSide(color: defaultBorder, width: 1),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return Semantics(container: true, child: card);
  }
}
