import 'package:flutter/material.dart';
import '../../config/constants.dart';

/// Centralized typography scale that respects the current theme brightness.
/// Use instead of inline `TextStyle(fontSize: ...)` for consistency.
class AppTypography {
  AppTypography._();

  static TextStyle _style(BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    final defaultColor = const Color(0xFFE5E7EB);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? defaultColor,
    );
  }

  // ── Display / Headings ───────────────────────────────────────────────

  static TextStyle displayLarge(BuildContext context) => _style(
    context,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium(BuildContext context) => _style(
    context,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle displaySmall(BuildContext context) => _style(
    context,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  // ── Headlines ─────────────────────────────────────────────────────────

  static TextStyle headlineLarge(BuildContext context) => _style(
    context,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle headlineMedium(BuildContext context) => _style(
    context,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headlineSmall(BuildContext context) => _style(
    context,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────────────────────

  static TextStyle bodyLarge(BuildContext context) => _style(
    context,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => _style(
    context,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodySmall(BuildContext context) => _style(
    context,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // ── Labels / Captions ─────────────────────────────────────────────────

  static TextStyle labelLarge(BuildContext context) => _style(
    context,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle labelMedium(BuildContext context) => _style(
    context,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall(BuildContext context) => _style(
    context,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ── Button ────────────────────────────────────────────────────────────

  static TextStyle button(BuildContext context) => _style(
    context,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.25,
  );

  // ── Semantic helpers ──────────────────────────────────────────────────

  static TextStyle caption(BuildContext context) => bodySmall(context).copyWith(
    color: const Color(0xFF6B7280),
  );

  static TextStyle error(BuildContext context) => bodyMedium(context).copyWith(
    color: AppColors.error,
  );

  static TextStyle success(BuildContext context) => bodyMedium(context).copyWith(
    color: const Color(0xFF10B981),
  );
}
