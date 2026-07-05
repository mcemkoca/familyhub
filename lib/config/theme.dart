import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme(Color accentColor, {double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: const Color(0xFFEC4899),
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF111827),
      ),
      textTheme: _textTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F5F7),
        foregroundColor: const Color(0xFF111827),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : const Color(0xFF9CA3AF)),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withAlpha(80) : const Color(0xFFE5E7EB)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : Colors.transparent),
        side: const BorderSide(color: Color(0xFF9CA3AF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        hintStyle: TextStyle(color: const Color(0xFF9CA3AF).withAlpha(180)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: accentColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        modalBackgroundColor: Colors.black.withAlpha(100),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: accentColor,
        labelStyle: const TextStyle(color: Color(0xFF374151), fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: accentColor.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Color(0xFF6B7280), size: 24),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF374151), size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: const Color(0xFFE5E7EB),
        thumbColor: accentColor,
        overlayColor: accentColor.withAlpha(40),
        trackHeight: 4,
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor, {double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFFEC4899),
        surface: Color(0xFF13131A),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE5E7EB),
      ),
      textTheme: _textTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: const Color(0xFF13131A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF13131A),
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFE5E7EB)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1EFFFFFF),
        thickness: 0.5,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF6366F1) : const Color(0xFF6B7280)),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF6366F1).withAlpha(80) : const Color(0x1EFFFFFF)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : Colors.transparent),
        side: const BorderSide(color: Color(0xFF6B7280)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF13131A),
        hintStyle: TextStyle(color: const Color(0xFF6B7280).withAlpha(180)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: Color(0x1EFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: Color(0x1EFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF13131A),
        contentTextStyle: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: accentColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF13131A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        modalBackgroundColor: const Color(0xFF0A0A0F).withAlpha(200),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0A0A0F),
        selectedColor: accentColor,
        labelStyle: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF13131A),
        indicatorColor: accentColor.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Color(0xFF6B7280), size: 24),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF6B7280), size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: const Color(0x1EFFFFFF),
        thumbColor: accentColor,
        overlayColor: accentColor.withAlpha(40),
        trackHeight: 4,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? const Color(0xFF111827) : const Color(0xFFE5E7EB);
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, height: 1.2),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, height: 1.2),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, height: 1.3),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, height: 1.3),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.3),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: color, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: color, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color, height: 1.4),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color, height: 1.4),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, height: 1.2),
      ),
    );
  }
}
