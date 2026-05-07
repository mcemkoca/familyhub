import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color green = Color(0xFF10B981);
  static const Color mint = Color(0xFF34D399);

  // FamilyHub New Brand Colors
  static const Color cobalt = Color(0xFF2563EB);
  static const Color cobaltLight = Color(0xFF3B82F6);
  static const Color cobaltLighter = Color(0xFF60A5FA);
  static const Color coral = Color(0xFFF97316);
  static const Color softMint = Color(0xFF10B981);
  static const Color cloudWhite = Color(0xFFF8FAFC);
  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFF94A3B8);

  // Neutral
  static const Color dark = Color(0xFF1F2937);
  static const Color gray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  static const List<Color> taskGradient = [purple, pink];
  static const List<Color> streakGradient = [orange, red];
  static const List<Color> calendarGradient = [blue, cyan];
  static const List<Color> budgetGradient = [green, mint];
  static const List<Color> fabGradient = [cobalt, cobaltLight, cobaltLighter];
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
}

class AppStrings {
  static const String appName = 'FamilyHub';
  static const String tagline = 'Ailenizin kalbi burada atıyor';
}
