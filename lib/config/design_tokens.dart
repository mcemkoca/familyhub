/// FamilyHub Design Tokens
/// Bu dosya Figma tasarım sistemi ile senkronize tutulan
/// renk, tipografi ve spacing tokenlarını tanımlar.
///
/// Figma'dan değişiklik geldiğinde sadece bu dosyayı güncelleyin.
library;

import 'package:flutter/material.dart';

// ─── RENK TOKENLARı ─────────────────────────────────────────────────────────

abstract class DesignTokens {
  // Brand primary
  static const Color brand100 = Color(0xFFEDE9FE); // violet-100
  static const Color brand200 = Color(0xFFDDD6FE); // violet-200
  static const Color brand300 = Color(0xFFC4B5FD); // violet-300
  static const Color brand400 = Color(0xFFA78BFA); // violet-400
  static const Color brand500 = Color(0xFF8B5CF6); // violet-500 (primary)
  static const Color brand600 = Color(0xFF7C3AED); // violet-600
  static const Color brand700 = Color(0xFF6D28D9); // violet-700
  static const Color brand800 = Color(0xFF5B21B6); // violet-800
  static const Color brand900 = Color(0xFF4C1D95); // violet-900

  // Accent — sohbet, bildirim
  static const Color accent100 = Color(0xFFDCFCE7);
  static const Color accent500 = Color(0xFF10B981); // emerald-500
  static const Color accent600 = Color(0xFF059669);

  // Danger — acil, hata
  static const Color danger100 = Color(0xFFFEE2E2);
  static const Color danger500 = Color(0xFFEF4444);
  static const Color danger600 = Color(0xFFDC2626);

  // Warning — uyarı, batarya düşük
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning500 = Color(0xFFF59E0B);

  // Info — konum, bilgi
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info600 = Color(0xFF2563EB);

  // Nötr
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Semantic — anlam taşıyan tokenlar
  static const Color bgPrimary = neutral50;
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgDarkPrimary = neutral900;
  static const Color bgDarkSecondary = neutral800;

  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral500;
  static const Color textDisabled = neutral400;
  static const Color textDarkPrimary = neutral100;
  static const Color textDarkSecondary = neutral400;

  static const Color borderDefault = neutral200;
  static const Color borderFocus = brand500;
  static const Color borderDark = neutral700;

  // Feature renkleri
  static const Color featureChat = brand500;
  static const Color featureGallery = Color(0xFFEC4899);
  static const Color featureShopping = accent500;
  static const Color featureKitchen = Color(0xFFF97316);
  static const Color featureEducation = Color(0xFF6366F1);
  static const Color featureGps = Color(0xFF06B6D4);
  static const Color featureBudget = info600;
  static const Color featureChild = warning500;
  static const Color featureSafety = danger500;

  // ─── TİPOGRAFİ SKALI ────────────────────────────────────────────────────

  static const double fontXs = 10;
  static const double fontSm = 12;
  static const double fontMd = 14;
  static const double fontLg = 16;
  static const double fontXl = 20;
  static const double font2xl = 24;
  static const double font3xl = 30;
  static const double font4xl = 36;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightExtrabold = FontWeight.w800;
  static const FontWeight weightBlack = FontWeight.w900;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ─── BOYUT VE ARALIK TOKENLARı ──────────────────────────────────────────

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius12 = 12;
  static const double radius14 = 14;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radiusFull = 9999;

  static const double elevation0 = 0;
  static const double elevation1 = 2;
  static const double elevation2 = 4;
  static const double elevation3 = 8;
  static const double elevation4 = 16;

  // ─── COMPONENT TOKENLARı ─────────────────────────────────────────────────

  // Button
  static const double buttonHeight = 48;
  static const double buttonHeightSm = 36;
  static const double buttonHeightLg = 56;
  static const double buttonRadius = radius12;
  static const double buttonFontSize = fontMd;
  static const FontWeight buttonFontWeight = weightBold;

  // Card
  static const double cardRadius = radius16;
  static const double cardPadding = space4;
  static const Color cardShadowLight = Color(0x0F000000); // 6% opacity
  static const Color cardShadowDark = Color(0x1A000000); // 10% opacity

  // Input
  static const double inputHeight = 48;
  static const double inputRadius = radius12;
  static const double inputFontSize = fontMd;
  static const Color inputBorderLight = borderDefault;
  static const Color inputBorderDark = borderDark;

  // Bottom Navigation
  static const double bottomNavHeight = 64;
  static const double bottomNavIconSize = 22;
  static const double bottomNavLabelSize = fontXs;

  // Avatar
  static const double avatarXs = 24;
  static const double avatarSm = 36;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 80;

  // Chip
  static const double chipHeight = 32;
  static const double chipRadius = radiusFull;
  static const double chipFontSize = fontSm;

  // ─── ANİMASYON TOKENLARı ─────────────────────────────────────────────────

  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 320);
  static const Duration durationVerySlow = Duration(milliseconds: 500);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEnter = Curves.easeOut;
  static const Curve curveExit = Curves.easeIn;
  static const Curve curveBounce = Curves.elasticOut;

  // ─── GRADYAN TOKENLARı ───────────────────────────────────────────────────

  // ─── AILE GRADYANLARI (sıcak, davetkar tonlar) ──────────────────────────────

  // Ana ekran başlığı — gün batımı turuncu → pembe → mor
  static const LinearGradient gradientHub = LinearGradient(
    colors: [Color(0xFFFF9A56), Color(0xFFFF6B95), Color(0xFFC850C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Mutfak — şeftali → altın sarısı
  static const LinearGradient gradientKitchen = LinearGradient(
    colors: [Color(0xFFFDA085), Color(0xFFF6D365)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Eğitim — lavanta → pembe bulut
  static const LinearGradient gradientEducation = LinearGradient(
    colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // GPS / Harita — gökyüzü mavi → turkuaz
  static const LinearGradient gradientGps = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bütçe — gün batımı turuncu → sarı
  static const LinearGradient gradientBudget = LinearGradient(
    colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Güvenlik / Acil — kırmızı → turuncu
  static const LinearGradient gradientSafety = LinearGradient(
    colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sohbet — mor → mavi
  static const LinearGradient gradientChat = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFFA18CD1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Alışveriş — yeşil nane → teal
  static const LinearGradient gradientShopping = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Galeri — orkide → kırmızı
  static const LinearGradient gradientGallery = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Çocuk / Başarı — nane → gökyüzü
  static const LinearGradient gradientChild = LinearGradient(
    colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Eski brand gradyanı (uyumluluk için)
  static const LinearGradient gradientBrand = LinearGradient(
    colors: [brand500, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── YARDIMCI METODLAR ───────────────────────────────────────────────────

  /// Özellik adına göre renk döner
  static Color featureColor(String featureName) {
    return switch (featureName.toLowerCase()) {
      'chat' || 'sohbet' => featureChat,
      'gallery' || 'galeri' => featureGallery,
      'shopping' || 'alışveriş' => featureShopping,
      'kitchen' || 'mutfak' => featureKitchen,
      'education' || 'eğitim' => featureEducation,
      'gps' || 'konum' || 'location' => featureGps,
      'budget' || 'bütçe' => featureBudget,
      'child' || 'çocuk' => featureChild,
      'safety' || 'güvenlik' => featureSafety,
      _ => brand500,
    };
  }

  /// İkon gölgesi oluşturur
  static List<BoxShadow> cardShadow(bool isDark) => [
        const BoxShadow(
          color: cardShadowDark,
          blurRadius: elevation3,
          offset: Offset(0, 2),
        ),
      ];

  /// Özellik kartı dekorasyonu
  static BoxDecoration featureCardDecoration(Color color,
      {bool isDark = false}) =>
      BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(radius14),
        border: Border.all(color: color.withAlpha(60)),
      );
}

// ─── TextStyle KISA YOLLARI ──────────────────────────────────────────────────

abstract class AppTextStyles {
  static TextStyle heading1(bool isDark) => TextStyle(
      fontSize: DesignTokens.font3xl,
      fontWeight: DesignTokens.weightBlack,
      color: isDark
          ? DesignTokens.textDarkPrimary
          : DesignTokens.textPrimary,
      height: DesignTokens.lineHeightTight);

  static TextStyle heading2(bool isDark) => TextStyle(
      fontSize: DesignTokens.font2xl,
      fontWeight: DesignTokens.weightExtrabold,
      color: isDark
          ? DesignTokens.textDarkPrimary
          : DesignTokens.textPrimary,
      height: DesignTokens.lineHeightTight);

  static TextStyle heading3(bool isDark) => TextStyle(
      fontSize: DesignTokens.fontXl,
      fontWeight: DesignTokens.weightBold,
      color: isDark
          ? DesignTokens.textDarkPrimary
          : DesignTokens.textPrimary,
      height: DesignTokens.lineHeightNormal);

  static TextStyle body(bool isDark) => TextStyle(
      fontSize: DesignTokens.fontMd,
      fontWeight: DesignTokens.weightRegular,
      color: isDark
          ? DesignTokens.textDarkPrimary
          : DesignTokens.textPrimary,
      height: DesignTokens.lineHeightNormal);

  static TextStyle bodySmall(bool isDark) => TextStyle(
      fontSize: DesignTokens.fontSm,
      fontWeight: DesignTokens.weightRegular,
      color: isDark
          ? DesignTokens.textDarkSecondary
          : DesignTokens.textSecondary,
      height: DesignTokens.lineHeightNormal);

  static const TextStyle caption = TextStyle(
      fontSize: DesignTokens.fontXs,
      fontWeight: DesignTokens.weightMedium,
      color: DesignTokens.textSecondary);

  static const TextStyle label = TextStyle(
      fontSize: DesignTokens.fontSm,
      fontWeight: DesignTokens.weightSemibold,
      color: DesignTokens.textSecondary);

  static const TextStyle button = TextStyle(
      fontSize: DesignTokens.buttonFontSize,
      fontWeight: DesignTokens.buttonFontWeight,
      letterSpacing: 0.2);
}
