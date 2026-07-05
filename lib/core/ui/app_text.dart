import 'package:flutter/material.dart';

/// Theme-aware text widgets that eliminate inline brightness ternary checks.
class AppText extends StatelessWidget {
  const AppText.headline(
    this.data, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = AppTextStyle.headline;

  const AppText.title(
    this.data, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = AppTextStyle.title;

  const AppText.body(
    this.data, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = AppTextStyle.body;

  const AppText.caption(
    this.data, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = AppTextStyle.caption;

  final String data;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = color ?? (const Color(0xFFE5E7EB));

    final textStyle = switch (style) {
      AppTextStyle.headline => theme.textTheme.headlineSmall?.copyWith(color: defaultColor),
      AppTextStyle.title => theme.textTheme.titleMedium?.copyWith(color: defaultColor),
      AppTextStyle.body => theme.textTheme.bodyMedium?.copyWith(color: defaultColor),
      AppTextStyle.caption => theme.textTheme.bodySmall?.copyWith(color: defaultColor.withValues(alpha: 0.6)),
    };

    return Semantics(
      label: data,
      child: Text(
        data,
        style: textStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

enum AppTextStyle { headline, title, body, caption }
