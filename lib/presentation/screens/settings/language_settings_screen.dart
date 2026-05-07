import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import '../../../config/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'Türkçe';
  String _selectedRegion = 'Türkiye';
  String _dateFormat = 'DD/MM/YYYY';

  final _languages = ['Türkçe', 'English', 'Deutsch', 'Nederlands'];
  final _regions = ['Türkiye', 'United States', 'Germany', 'Netherlands'];
  final _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = HiveService.getSetting('language') ?? 'Türkçe';
    _selectedRegion = HiveService.getSetting('region') ?? 'Türkiye';
    _dateFormat = HiveService.getSetting('dateFormat') ?? 'DD/MM/YYYY';
  }

  Future<void> _saveLanguage(String lang) async {
    setState(() => _selectedLanguage = lang);
    await HiveService.setSetting('language', lang);
    HapticFeedback.selectionClick();

    Locale newLocale;
    switch (lang) {
      case 'English':
        newLocale = const Locale('en', 'US');
        break;
      case 'Deutsch':
        newLocale = const Locale('de', 'DE');
        break;
      case 'Nederlands':
        newLocale = const Locale('nl', 'NL');
        break;
      case 'Türkçe':
      default:
        newLocale = const Locale('tr', 'TR');
        break;
    }
    ref.read(localeProvider.notifier).state = newLocale;
  }

  Future<void> _saveRegion(String region) async {
    setState(() => _selectedRegion = region);
    await HiveService.setSetting('region', region);
    HapticFeedback.selectionClick();
  }

  Future<void> _saveDateFormat(String fmt) async {
    setState(() => _dateFormat = fmt);
    await HiveService.setSetting('dateFormat', fmt);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Dil ve Bölge',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroup(
            title: 'UYGULAMA DİLİ',
            children: _languages.map((lang) {
              final selected = _selectedLanguage == lang;
              return _buildOptionTile(
                label: lang,
                selected: selected,
                onTap: () => _saveLanguage(lang),
                cardBg: cardBg,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildGroup(
            title: 'BÖLGE',
            children: _regions.map((region) {
              final selected = _selectedRegion == region;
              return _buildOptionTile(
                label: region,
                selected: selected,
                onTap: () => _saveRegion(region),
                cardBg: cardBg,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildGroup(
            title: 'TARİH FORMATI',
            children: _dateFormats.map((fmt) {
              final selected = _dateFormat == fmt;
              return _buildOptionTile(
                label: fmt,
                selected: selected,
                onTap: () => _saveDateFormat(fmt),
                cardBg: cardBg,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup({required String title, required List<Widget> children}) {
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
    required Color cardBg,
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
              Icon(
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
