import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';
import '../../providers/app_providers.dart';
import '../../../config/country_config.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'Türkçe';
  String _selectedCountry = 'BE';
  String _dateFormat = 'DD/MM/YYYY';

  // Yalnızca çevirisi (ARB) olan diller listelenir. Deutsch için çeviri
  // olmadığından listeden çıkarıldı (seçilse de uygulanamıyordu).
  final _languages = ['Türkçe', 'English', 'Nederlands', 'Français'];
  final _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = HiveService.getSetting('language') ?? 'Türkçe';
    _selectedCountry = HiveService.getSetting('country') ?? 'BE';
    _dateFormat = HiveService.getSetting('dateFormat') ?? 'DD/MM/YYYY';
  }

  /// Ülke seçilince dil, para birimi, tarih formatı otomatik ayarlanır.
  Future<void> _saveCountry(Country c) async {
    setState(() {
      _selectedCountry = c.code;
      _selectedLanguage = c.languageLabel;
      _dateFormat = c.dateFormat;
    });
    HapticFeedback.selectionClick();
    await HiveService.setSetting('country', c.code);
    await HiveService.setSetting('language', c.languageLabel);
    await HiveService.setSetting('region', c.name);
    await HiveService.setSetting('currency', c.currencyCode);
    await HiveService.setSetting('currencySymbol', c.currencySymbol);
    await HiveService.setSetting('dateFormat', c.dateFormat);
    ref.read(countryProvider.notifier).state = c.code;
    ref.read(localeProvider.notifier).state = c.locale;
    // Ülke değişti → zamanlanmış bildirimler için yerel saat dilimini güncelle.
    NotificationService.refreshTimezone();
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
      case 'Nederlands':
        newLocale = const Locale('nl', 'NL');
        break;
      case 'Français':
        newLocale = const Locale('fr', 'FR');
        break;
      case 'Türkçe':
      default:
        newLocale = const Locale('tr', 'TR');
        break;
    }
    ref.read(localeProvider.notifier).state = newLocale;
  }

  Future<void> _saveDateFormat(String fmt) async {
    setState(() => _dateFormat = fmt);
    await HiveService.setSetting('dateFormat', fmt);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0A0A0F);
    final cardBg = const Color(0xFF13131A);

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
            title: 'ÜLKE / BÖLGE',
            children: CountryConfig.all.map((c) {
              final selected = _selectedCountry == c.code;
              return _buildOptionTile(
                label: c.display,
                selected: selected,
                onTap: () => _saveCountry(c),
                cardBg: cardBg,
              );
            }).toList(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(
              'Ülke seçimi; dil, para birimi, ev gideri ve market içeriğini belirler.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
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
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
