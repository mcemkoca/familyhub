import 'package:flutter/material.dart';

/// Common UI helpers to reduce repetition across the codebase.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

extension ColorAlpha on Color {
  /// Low alpha for subtle backgrounds (e.g. icon containers).
  Color get alphaLow => withAlpha(30);

  /// Medium alpha for borders and pressed states.
  Color get alphaMedium => withAlpha(50);

  /// High alpha for emphasis.
  Color get alphaHigh => withAlpha(80);
}

extension BorderRadiusHelpers on double {
  BorderRadius get asRadius => BorderRadius.circular(this);
}
