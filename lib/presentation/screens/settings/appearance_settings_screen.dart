import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import '../../../config/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends ConsumerState<AppearanceSettingsScreen> {
  late ThemeMode _selectedThemeMode;
  late Color _selectedAccent;
  late String _selectedAccentKey;
  late double _selectedFontScale;
  bool _hasChanges = false;

  late final ThemeMode _originalThemeMode;
  late final Color _originalAccent;
  late final double _originalFontScale;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = ref.read(themeModeProvider);
    _selectedAccent = ref.read(accentColorProvider);
    _selectedFontScale = ref.read(fontScaleProvider);

    _originalThemeMode = _selectedThemeMode;
    _originalAccent = _selectedAccent;
    _originalFontScale = _selectedFontScale;

    final savedAccent = HiveService.getSetting('accentColor') ?? 'cobalt';
    _selectedAccentKey = savedAccent;
  }

  void _markChanged() {
    setState(() {
      _hasChanges = _selectedThemeMode != _originalThemeMode ||
          _selectedAccent != _originalAccent ||
          _selectedFontScale != _originalFontScale;
    });
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    final themeValue = switch (_selectedThemeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    await HiveService.setSetting('themeMode', themeValue);
    await HiveService.setSetting('accentColor', _selectedAccentKey);
    await HiveService.setDoubleSetting('fontScale', _selectedFontScale);

    ref.read(themeModeProvider.notifier).state = _selectedThemeMode;
    ref.read(accentColorProvider.notifier).state = _selectedAccent;
    ref.read(fontScaleProvider.notifier).state = _selectedFontScale;

    _originalThemeMode = _selectedThemeMode;
    _originalAccent = _selectedAccent;
    _originalFontScale = _selectedFontScale;

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).gorunumAyarlariKaydedildi)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeOptions = [
      {'icon': Icons.wb_sunny, 'label': 'Açık', 'mode': ThemeMode.light},
      {'icon': Icons.nights_stay, 'label': 'Karanlık', 'mode': ThemeMode.dark},
      {'icon': Icons.brightness_auto, 'label': 'Sistem', 'mode': ThemeMode.system},
    ];

    final accentOptions = [
      {'color': AppColors.cobalt, 'label': 'Kobalt', 'key': 'cobalt'},
      {'color': AppColors.green, 'label': 'Yeşil', 'key': 'green'},
      {'color': AppColors.orange, 'label': 'Turuncu', 'key': 'orange'},
      {'color': AppColors.purple, 'label': 'Mor', 'key': 'purple'},
      {'color': AppColors.red, 'label': 'Kırmızı', 'key': 'red'},
    ];

    final fontOptions = [
      {'scale': 0.875, 'label': 'Küçük'},
      {'scale': 1.0, 'label': 'Normal'},
      {'scale': 1.125, 'label': 'Büyük'},
      {'scale': 1.25, 'label': 'Çok Büyük'},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: ScreenHeader(
        title: 'Görünüm',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tema',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              children: themeOptions.map((opt) {
                final selected = _selectedThemeMode == opt['mode'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedThemeMode = opt['mode'] as ThemeMode);
                      ref.read(themeModeProvider.notifier).state = opt['mode'] as ThemeMode;
                      _markChanged();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark ? _selectedAccent.withAlpha(30) : _selectedAccent.withAlpha(15))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _selectedAccent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            opt['icon'] as IconData,
                            color: selected ? _selectedAccent : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected
                                  ? _selectedAccent
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aksan Rengi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: accentOptions.map((opt) {
                final selected = _selectedAccent == opt['color'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedAccent = opt['color'] as Color;
                      _selectedAccentKey = opt['key'] as String;
                    });
                    ref.read(accentColorProvider.notifier).state = opt['color'] as Color;
                    _markChanged();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: opt['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: (opt['color'] as Color).withAlpha(80), blurRadius: 12)]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Yazı Boyutu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: fontOptions.map((opt) {
                final selected = _selectedFontScale == opt['scale'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFontScale = opt['scale'] as double);
                    ref.read(fontScaleProvider.notifier).state = opt['scale'] as double;
                    _markChanged();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? _selectedAccent.withAlpha(30) : _selectedAccent.withAlpha(15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _selectedAccent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 16 * (opt['scale'] as double),
                            fontWeight: FontWeight.w600,
                            color: selected ? _selectedAccent : (isDark ? AppColors.darkTextPrimary : AppColors.dark),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? _selectedAccent : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          Icon(Icons.check_circle, color: _selectedAccent, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _hasChanges ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                disabledForegroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
