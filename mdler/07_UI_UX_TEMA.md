# UI/UX & TEMA
## 12 Tasarim Sorunu | Hedef: Mükemmel Dark Mode + Responsive

---

## 34. Dark Theme Uyumsuzluklari — Cozum

**Sorun:** Gercek cihazda dark tema ve system temasinda contrast yetersiz

### lib/core/theme/app_colors.dart
```dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF3b82f6);
  static const Color primaryLight = Color(0xFF60a5fa);
  static const Color primaryDark = Color(0xFF2563eb);

  // Background
  static const Color backgroundDark = Color(0xFF0f172a);
  static const Color surfaceDark = Color(0xFF1e293b);
  static const Color surfaceDarkElevated = Color(0xFF334155);

  // Text Dark
  static const Color textPrimaryDark = Color(0xFFf8fafc);
  static const Color textSecondaryDark = Color(0xFF94a3b8);
  static const Color textTertiaryDark = Color(0xFF64748b);
  static const Color textDisabledDark = Color(0xFF475569);

  // Text Light
  static const Color textPrimaryLight = Color(0xFF1e293b);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94a3b8);

  // Semantic
  static const Color success = Color(0xFF10b981);
  static const Color successLight = Color(0xFF34d399);
  static const Color warning = Color(0xFFf59e0b);
  static const Color warningLight = Color(0xFFfbbf24);
  static const Color error = Color(0xFFef4444);
  static const Color errorLight = Color(0xFFf87171);
  static const Color info = Color(0xFF0ea5e9);
  static const Color infoLight = Color(0xFF38bdf8);

  // Difficulty
  static const Color difficultyEasy = Color(0xFF10b981);
  static const Color difficultyMedium = Color(0xFFf59e0b);
  static const Color difficultyHard = Color(0xFFef4444);

  // Overlay
  static const Color overlayDark = Color(0xFF000000);
  static const Color overlayLight = Color(0xFFFFFFFF);
}
```

### lib/core/theme/app_theme.dart — Tam Theme
```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: AppColors.textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.surfaceDarkElevated,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceDarkElevated),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      // EKSIK TEMALAR:
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalBackgroundColor: AppColors.backgroundDark.withOpacity(0.8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkElevated,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceDarkElevated,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceDarkElevated),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceDarkElevated),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: const TextStyle(color: AppColors.textTertiaryDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceDarkElevated,
        thickness: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

---

## 35. System Theme Dinleyici

**Sorun:** System tema degisikliginde aninda yansimiyor

### lib/main.dart
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness _platformBrightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    ThemeMode themeMode;
    switch (themeProvider.themeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // ...
    );
  }
}
```

---

## 36. Smiley/Emoji Picker — Calisir Hale Getir

**Sorun:** Sohbet girisinde smiley iconlar calismiyor

### pubspec.yaml
```yaml
dependencies:
  emoji_picker_flutter: ^3.0.0
```

### lib/features/chat/widgets/emoji_picker_widget.dart
```dart
class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback onClose;

  const EmojiPickerWidget({
    required this.onEmojiSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ),
          // Emoji picker
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
              config: Config(
                columns: 8,
                emojiSizeMax: 28,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: isDark ? AppColors.surfaceDark : Colors.white,
                indicatorColor: AppColors.primary,
                iconColor: isDark ? AppColors.textTertiaryDark : Colors.grey,
                iconColorSelected: AppColors.primary,
                skinToneDialogBgColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                skinToneIndicatorColor: isDark ? AppColors.textSecondaryDark : Colors.grey,
                enableSkinTones: true,
                recentTabBehavior: RecentTabBehavior.RECENT,
                recentsLimit: 28,
                noRecents: Text(
                  'Kullanilan yok',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textTertiaryDark : Colors.grey,
                  ),
                ),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 37. use_build_context_synchronously — Tüm Ekranlar

**Sorun:** `flutter analyze` uyari veriyor

### Cozum — Her async islem sonrasi mounted kontrolu:
```dart
// YANLIS:
await someFuture();
Navigator.of(context).push(...);

// DOGRU:
if (!mounted) return;
await someFuture();
if (!mounted) return;
Navigator.of(context).push(...);
```

### Otomatik fix script:
```bash
# Tum dosyalarda arama
grep -r "await.*Navigator" lib/ --include="*.dart"

# Her bulunan yerde mounted kontrolu ekle
```

---

## Kontrol Listesi

- [ ] Dark mode contrast WCAG 4.5:1 sagliyor
- [ ] System theme degisikligi aninda yansiyor
- [ ] Emoji picker calisiyor
- [ ] `flutter analyze --fatal-infos --fatal-warnings` = 0
- [ ] Tüm ekranlarda `mounted` kontrolu var
- [ ] Light/Dark/System temalari test edildi
- [ ] TextField hintText renkleri okunakli
- [ ] FloatingActionButton renkleri gorunur

---
**Versiyon:** 1.0 | **Dosya:** 7/10 | **Hedef:** Mükemmel Dark Mode
