import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/localization/locale_service.dart';
import '../../providers/app_providers.dart';
import '../../../config/country_config.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

/// Modern Dil ve Bölge ayarları — seçimler ANLIK uygulanmaz; taslak tutulur ve
/// "Kaydet" ile birlikte uygulanır (dil, ülke, para birimi, tarih formatı).
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  // Kaydedilmiş (mevcut) değerler
  late String _savedLanguage;
  late String _savedCountry;
  late String _savedDateFormat;

  // Taslak (henüz kaydedilmemiş) seçimler
  late String _draftLanguage;
  late String _draftCountry;
  late String _draftDateFormat;

  bool _saving = false;

  // Cihaz dili (otomatik) modu — açılışta kayıtlı dil yoksa cihaz dili kullanılır.
  late bool _savedDevice;
  late bool _draftDevice;

  /// Cihazın sistem dili (tr/en/nl/fr'den biri, değilse Türkçe).
  String get _deviceLanguageLabel {
    final code =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return switch (code) {
      'en' => 'English',
      'nl' => 'Nederlands',
      'fr' => 'Français',
      _ => 'Türkçe',
    };
  }

  // Dil kartları: (etiket, bayrak, yerel ad, İngilizce ad)
  static const _languages = <(String, String, String, String)>[
    ('Türkçe', '🇹🇷', 'Türkçe', 'Turkish'),
    ('English', '🇬🇧', 'English', 'English'),
    ('Nederlands', '🇳🇱', 'Nederlands', 'Dutch'),
    ('Français', '🇫🇷', 'Français', 'French'),
  ];
  static const _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];

  @override
  void initState() {
    super.initState();
    // 'deviceLang' bayrağı: kullanıcı cihaz dilini takip etmeyi seçtiyse.
    _savedDevice = HiveService.getBoolSetting('useDeviceLanguage',
        defaultValue: false);
    _savedLanguage =
        _savedDevice ? _deviceLanguageLabel : (HiveService.getSetting('language') ?? 'Türkçe');
    _savedCountry = HiveService.getSetting('country') ?? 'BE';
    _savedDateFormat = HiveService.getSetting('dateFormat') ?? 'DD/MM/YYYY';
    _draftDevice = _savedDevice;
    _draftLanguage = _savedLanguage;
    _draftCountry = _savedCountry;
    _draftDateFormat = _savedDateFormat;
  }

  bool get _dirty =>
      _draftDevice != _savedDevice ||
      _draftLanguage != _savedLanguage ||
      _draftCountry != _savedCountry ||
      _draftDateFormat != _savedDateFormat;

  Locale _localeFor(String lang) => switch (lang) {
        'English' => const Locale('en', 'US'),
        'Nederlands' => const Locale('nl', 'NL'),
        'Français' => const Locale('fr', 'FR'),
        _ => const Locale('tr', 'TR'),
      };

  void _pickLanguage(String lang) {
    HapticFeedback.selectionClick();
    setState(() {
      _draftLanguage = lang;
      _draftDevice = false;
    });
  }

  void _pickDeviceLanguage() {
    HapticFeedback.selectionClick();
    setState(() {
      _draftDevice = true;
      _draftLanguage = _deviceLanguageLabel;
    });
  }

  void _pickCountry(Country c) {
    HapticFeedback.selectionClick();
    setState(() {
      _draftCountry = c.code;
      _draftDateFormat = c.dateFormat; // ülke tarih formatını önerir
    });
  }

  void _pickDateFormat(String fmt) {
    HapticFeedback.selectionClick();
    setState(() => _draftDateFormat = fmt);
  }

  Future<void> _save() async {
    if (!_dirty || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final country = CountryConfig.all.firstWhere(
      (c) => c.code == _draftCountry,
      orElse: () => CountryConfig.all.first,
    );

    // Cihaz dili modu: sabit dil yerine cihazın sistem dili takip edilir.
    final effectiveLang =
        _draftDevice ? _deviceLanguageLabel : _draftLanguage;

    // Dil kararı LocaleService üzerinden (karar-state + kalıcılık tek yerde).
    if (_draftDevice) {
      await LocaleService.acceptDeviceLocale();
    } else {
      await LocaleService.selectManually(_draftLanguage);
    }
    // Bölge tercihleri (dilden ayrı — dil≠bölge).
    await HiveService.setSetting('country', country.code);
    await HiveService.setSetting('region', country.name);
    await HiveService.setSetting('currency', country.currencyCode);
    await HiveService.setSetting('currencySymbol', country.currencySymbol);
    await HiveService.setSetting('dateFormat', _draftDateFormat);

    // Sağlayıcıları güncelle → uygulama anında yeni dile/bölgeye geçer.
    ref.read(countryProvider.notifier).state = country.code;
    ref.read(localeProvider.notifier).state = _localeFor(effectiveLang);
    NotificationService.refreshTimezone();

    setState(() {
      _savedDevice = _draftDevice;
      _savedLanguage = effectiveLang;
      _draftLanguage = effectiveLang;
      _savedCountry = _draftCountry;
      _savedDateFormat = _draftDateFormat;
      _saving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text('Dil ve bölge ayarları kaydedildi'),
        ]),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0F);
    final selectedCountry = CountryConfig.all.firstWhere(
      (c) => c.code == _draftCountry,
      orElse: () => CountryConfig.all.first,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: AppLocalizations.of(context).dilVeBolge,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          // ── Önizleme kartı ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1330), Color(0xFF141225)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x2A8B5CF6)),
            ),
            child: Row(
              children: [
                Text(selectedCountry.flag,
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_draftLanguage,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedCountry.name} · ${selectedCountry.currencySymbol} · $_draftDateFormat',
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionTitle(AppLocalizations.of(context).uygulamaDili),
          const SizedBox(height: 10),
          // Cihaz dili (otomatik) — seçilirse uygulama cihazın sistem dilini takip eder.
          GestureDetector(
            onTap: _pickDeviceLanguage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _draftDevice
                    ? const Color(0xFF6366F1).withAlpha(28)
                    : const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _draftDevice
                      ? const Color(0xFF6366F1)
                      : const Color(0x14FFFFFF),
                  width: _draftDevice ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone_rounded,
                      color: Color(0xFF9CA3AF), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cihaz Dili (Otomatik)',
                            style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text('Sistem dili: $_deviceLanguageLabel',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_draftDevice)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF6366F1), size: 20),
                ],
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: _languages.map((l) {
              final sel = !_draftDevice && _draftLanguage == l.$1;
              return _LangCard(
                flag: l.$2,
                native: l.$3,
                english: l.$4,
                selected: sel,
                onTap: () => _pickLanguage(l.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          _sectionTitle('ÜLKE / BÖLGE'),
          const SizedBox(height: 10),
          ...CountryConfig.all.map((c) {
            final sel = _draftCountry == c.code;
            return _RegionTile(
              country: c,
              selected: sel,
              onTap: () => _pickCountry(c),
            );
          }),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Ülke seçimi; para birimi, ev gideri ve market içeriğini belirler.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 22),

          _sectionTitle(AppLocalizations.of(context).tarihFormati),
          const SizedBox(height: 10),
          Row(
            children: _dateFormats.map((fmt) {
              final sel = _draftDateFormat == fmt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _pickDateFormat(fmt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF13131A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF6366F1)
                                : const Color(0x14FFFFFF)),
                      ),
                      child: Text(
                        fmt,
                        style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF9CA3AF),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      // ── Sticky Kaydet butonu ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
          border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
        ),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _dirty && !_saving ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              disabledBackgroundColor: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    _dirty ? 'Kaydet' : 'Kaydedildi',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _dirty
                            ? Colors.white
                            : const Color(0xFF6B7280)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
      );
}

class _LangCard extends StatelessWidget {
  final String flag;
  final String native;
  final String english;
  final bool selected;
  final VoidCallback onTap;
  const _LangCard({
    required this.flag,
    required this.native,
    required this.english,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6366F1).withAlpha(30)
              : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : const Color(0x14FFFFFF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(native,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(english,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF6366F1), size: 20),
          ],
        ),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  final Country country;
  final bool selected;
  final VoidCallback onTap;
  const _RegionTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6366F1).withAlpha(28)
                : const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? const Color(0xFF6366F1) : const Color(0x14FFFFFF),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(country.name,
                    style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Text(country.currencySymbol,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF6366F1), size: 20)
              else
                const Icon(Icons.circle_outlined,
                    color: Color(0xFF374151), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
