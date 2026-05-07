import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme(Color accentColor, {double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: AppColors.pink,
        surface: AppColors.card,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.dark,
      ),
      textTheme: _textTheme(Brightness.light, fontScale: fontScale),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.gray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        titleTextStyle: GoogleFonts.inter(fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.dark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : AppColors.gray),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withAlpha(80) : AppColors.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : Colors.transparent),
        side: BorderSide(color: AppColors.gray),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        hintStyle: TextStyle(color: AppColors.slate.withAlpha(180)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
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
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.dark, fontSize: 14 * fontScale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: accentColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        modalBackgroundColor: AppColors.background.withAlpha(200),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: accentColor,
        labelStyle: TextStyle(color: AppColors.dark, fontSize: 12 * fontScale),
        secondaryLabelStyle: TextStyle(color: Colors.white, fontSize: 12 * fontScale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12 * fontScale),
        waitDuration: const Duration(milliseconds: 500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: accentColor.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: AppColors.gray, fontSize: 12 * fontScale),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: AppColors.gray, size: 24),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.slate, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: AppColors.border,
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
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: AppColors.pink,
        surface: AppColors.darkCard,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: _textTheme(Brightness.dark, fontScale: fontScale),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: GoogleFonts.inter(fontSize: 18 * fontScale, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : AppColors.darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withAlpha(80) : AppColors.darkBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : Colors.transparent),
        side: BorderSide(color: AppColors.darkTextSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        hintStyle: TextStyle(color: AppColors.darkTextSecondary.withAlpha(180)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.darkBorder),
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
        backgroundColor: AppColors.darkCard,
        contentTextStyle: TextStyle(color: AppColors.darkTextPrimary, fontSize: 14 * fontScale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: accentColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        modalBackgroundColor: AppColors.darkBackground.withAlpha(200),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBackground,
        selectedColor: accentColor,
        labelStyle: TextStyle(color: AppColors.darkTextPrimary, fontSize: 12 * fontScale),
        secondaryLabelStyle: TextStyle(color: Colors.white, fontSize: 12 * fontScale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(color: AppColors.darkTextPrimary, fontSize: 12 * fontScale),
        waitDuration: const Duration(milliseconds: 500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: accentColor.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: AppColors.darkTextSecondary, fontSize: 12 * fontScale),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: AppColors.darkTextSecondary, size: 24),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextSecondary, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: AppColors.darkBorder,
        thumbColor: accentColor,
        overlayColor: accentColor.withAlpha(40),
        trackHeight: 4,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness, {double fontScale = 1.0}) {
    final color = brightness == Brightness.light ? AppColors.dark : AppColors.darkTextPrimary;
    double s(double size) => size * fontScale;
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: s(32), fontWeight: FontWeight.bold, color: color, height: 1.2),
        displayMedium: TextStyle(fontSize: s(28), fontWeight: FontWeight.bold, color: color, height: 1.2),
        displaySmall: TextStyle(fontSize: s(24), fontWeight: FontWeight.bold, color: color, height: 1.3),
        headlineLarge: TextStyle(fontSize: s(22), fontWeight: FontWeight.bold, color: color, height: 1.3),
        headlineMedium: TextStyle(fontSize: s(20), fontWeight: FontWeight.w600, color: color, height: 1.3),
        headlineSmall: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleLarge: TextStyle(fontSize: s(18), fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleMedium: TextStyle(fontSize: s(16), fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleSmall: TextStyle(fontSize: s(14), fontWeight: FontWeight.w600, color: color, height: 1.4),
        bodyLarge: TextStyle(fontSize: s(16), fontWeight: FontWeight.normal, color: color, height: 1.5),
        bodyMedium: TextStyle(fontSize: s(14), fontWeight: FontWeight.normal, color: color, height: 1.5),
        bodySmall: TextStyle(fontSize: s(12), fontWeight: FontWeight.normal, color: color, height: 1.5),
        labelLarge: TextStyle(fontSize: s(14), fontWeight: FontWeight.w500, color: color, height: 1.4),
        labelMedium: TextStyle(fontSize: s(12), fontWeight: FontWeight.w500, color: color, height: 1.4),
        labelSmall: TextStyle(fontSize: s(11), fontWeight: FontWeight.bold, color: color, height: 1.2),
      ),
    );
  }
}
