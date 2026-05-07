import 'package:flutter/material.dart';

/// Consistent elevation shadow tokens for the FamilyHub design system.
/// Light and dark mode aware.
class AppShadows {
  AppShadows._();

  // Light mode shadows
  static List<BoxShadow> get lightSm => [
    BoxShadow(
      color: Colors.black.withAlpha(13), // ~0.05 opacity
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get lightMd => [
    BoxShadow(
      color: Colors.black.withAlpha(20), // ~0.08 opacity
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lightLg => [
    BoxShadow(
      color: Colors.black.withAlpha(26), // ~0.10 opacity
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Dark mode shadows (subtler, tinted)
  static List<BoxShadow> get darkSm => [
    BoxShadow(
      color: Colors.black.withAlpha(25), // ~0.10 opacity
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get darkMd => [
    BoxShadow(
      color: Colors.black.withAlpha(40), // ~0.16 opacity
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get darkLg => [
    BoxShadow(
      color: Colors.black.withAlpha(51), // ~0.20 opacity
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Returns the appropriate shadow set based on current brightness.
  static List<BoxShadow> sm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSm : lightSm;
  }

  static List<BoxShadow> md(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkMd : lightMd;
  }

  static List<BoxShadow> lg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkLg : lightLg;
  }
}
