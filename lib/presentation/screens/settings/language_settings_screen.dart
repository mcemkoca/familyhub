import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/hive_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  AppLanguage _selectedLanguage = AppLanguage.defaultLanguage;
  String _selectedRegionCode = 'BE';
  String _dateFormat = 'DD/MM/YYYY';

  static const _regions = <_RegionOption>[
    _RegionOption(code: 'BE', labelKey: 'region.be'),
    _RegionOption(code: 'NL', labelKey: 'region.nl'),
    _RegionOption(code: 'FR', labelKey: 'region.fr'),
    _RegionOption(code: 'TR', labelKey: 'region.tr'),
    _RegionOption(code: 'GB', labelKey: 'region.gb'),
  ];

  static const _dateFormats = <String>[
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'YYYY-MM-DD',
  ];

  @override
  void initState() {
    super.initState();

    final storedLanguage =
        HiveService.getSetting('languageCode') ??
        HiveService.getSetting('language');
    _selectedLanguage = AppLanguage.fromStoredValue(storedLanguage);

    final storedRegion =
        HiveService.getSetting('regionCode') ??
        HiveService.getSetting('region');
    _selectedRegionCode = _normalizeRegion(storedRegion);

    _dateFormat = HiveService.getSetting('dateFormat') ?? 'DD/MM/YYYY';
  }

  Future<void> _saveLanguage(AppLanguage language) async {
    setState(() => _selectedLanguage = language);

    await HiveService.setSetting('languageCode', language.code);
    await HiveService.setSetting('language', language.nativeName);

    ref.read(localeProvider.notifier).state = language.locale;
    HapticFeedback.selectionClick();
  }

  Future<void> _saveRegion(_RegionOption region) async {
    setState(() => _selectedRegionCode = region.code);
    await HiveService.setSetting('regionCode', region.code);
    await HiveService.setSetting('region', region.code);
    HapticFeedback.selectionClick();
  }

  Future<void> _saveDateFormat(String format) async {
    setState(() => _dateFormat = format);
    await HiveService.setSetting('dateFormat', format);
    HapticFeedback.selectionClick();
  }

  String _normalizeRegion(String? storedValue) {
    final normalized = storedValue?.trim().toLowerCase();
    return switch (normalized) {
      'be' || 'belgië' || 'belgique' || 'belgium' ||
      'belgië / belgique' => 'BE',
      'nl' || 'nederland' || 'netherlands' => 'NL',
      'fr' || 'france' => 'FR',
      'tr' || 'türkiye' || 'turkiye' || 'turkey' => 'TR',
      'gb' || 'uk' || 'united kingdom' => 'GB',
      'us' || 'united states' => 'GB',
      'de' || 'germany' || 'deutschland' => 'BE',
      _ => 'BE',
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkBackground : AppColors.cloudWhite;
    final cardBackground = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: ScreenHeader(
        title: strings.text('language.title'),
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroup(
            title: strings.text('language.application'),
            children: AppLanguage.values.map((language) {
              final selected = _selectedLanguage == language;
              return _buildOptionTile(
                label: language.nativeName,
                selected: selected,
                onTap: () => _saveLanguage(language),
                cardBackground: cardBackground,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildGroup(
            title: strings.text('language.region'),
            children: _regions.map((region) {
              final selected = _selectedRegionCode == region.code;
              return _buildOptionTile(
                label: strings.text(region.labelKey),
                selected: selected,
                onTap: () => _saveRegion(region),
                cardBackground: cardBackground,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildGroup(
            title: strings.text('language.dateFormat'),
            children: _dateFormats.map((format) {
              final selected = _dateFormat == format;
              return _buildOptionTile(
                label: format,
                selected: selected,
                onTap: () => _saveDateFormat(format),
                cardBackground: cardBackground,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slateLight : AppColors.slate,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(20)
                    : Colors.black.withAlpha(5),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color cardBackground,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.cobalt,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _RegionOption {
  const _RegionOption({required this.code, required this.labelKey});

  final String code;
  final String labelKey;
}
