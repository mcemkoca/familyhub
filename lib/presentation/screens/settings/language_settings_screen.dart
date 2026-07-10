import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  // FAZ 3 — ek bölge tercihleri (dilden ayrı).
  late String _savedTimeFormat; // '24h' | '12h'
  late String _savedFirstDay; // 'mon' | 'sun'
  late String _savedUnits; // 'metric' | 'imperial'
  late String _savedTemp; // 'C' | 'F'
  late String _draftTimeFormat;
  late String _draftFirstDay;
  late String _draftUnits;
  late String _draftTemp;

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
    _savedTimeFormat = HiveService.getSetting('timeFormat') ?? '24h';
    _savedFirstDay = HiveService.getSetting('firstDayOfWeek') ?? 'mon';
    _savedUnits = HiveService.getSetting('measurementSystem') ?? 'metric';
    _savedTemp = HiveService.getSetting('tempUnit') ?? 'C';
    _draftDevice = _savedDevice;
    _draftLanguage = _savedLanguage;
    _draftCountry = _savedCountry;
    _draftDateFormat = _savedDateFormat;
    _draftTimeFormat = _savedTimeFormat;
    _draftFirstDay = _savedFirstDay;
    _draftUnits = _savedUnits;
    _draftTemp = _savedTemp;
  }

  bool get _dirty =>
      _draftDevice != _savedDevice ||
      _draftLanguage != _savedLanguage ||
      _draftCountry != _savedCountry ||
      _draftDateFormat != _savedDateFormat ||
      _draftTimeFormat != _savedTimeFormat ||
      _draftFirstDay != _savedFirstDay ||
      _draftUnits != _savedUnits ||
      _draftTemp != _savedTemp;

  // ── Canlı önizleme yardımcıları (taslak seçime göre, intl ile) ──
  String get _draftLocaleCode {
    final loc = _localeFor(_draftDevice ? _deviceLanguageLabel : _draftLanguage);
    return loc.countryCode == null
        ? loc.languageCode
        : '${loc.languageCode}_${loc.countryCode}';
  }

  String get _datePattern => switch (_draftDateFormat) {
        'MM/DD/YYYY' => 'MM/dd/yyyy',
        'YYYY-MM-DD' => 'yyyy-MM-dd',
        _ => 'dd/MM/yyyy',
      };

  String _previewDate() {
    try {
      return DateFormat(_datePattern, _draftLocaleCode).format(DateTime.now());
    } catch (_) {
      return DateFormat(_datePattern).format(DateTime.now());
    }
  }

  String _previewTime() {
    final pattern = _draftTimeFormat == '12h' ? 'h:mm a' : 'HH:mm';
    try {
      return DateFormat(pattern, _draftLocaleCode).format(DateTime.now());
    } catch (_) {
      return DateFormat(pattern).format(DateTime.now());
    }
  }

  String _previewCurrency() {
    final c = CountryConfig.all.firstWhere(
      (c) => c.code == _draftCountry,
      orElse: () => CountryConfig.all.first,
    );
    try {
      return NumberFormat.currency(
        locale: _draftLocaleCode,
        symbol: c.currencySymbol,
        decimalDigits: 2,
      ).format(1234.5);
    } catch (_) {
      return '${c.currencySymbol}1234.50';
    }
  }

  String _previewTemp() => _draftTemp == 'F' ? '72°F' : '22°C';

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
    await HiveService.setSetting('timeFormat', _draftTimeFormat);
    await HiveService.setSetting('firstDayOfWeek', _draftFirstDay);
    await HiveService.setSetting('measurementSystem', _draftUnits);
    await HiveService.setSetting('tempUnit', _draftTemp);

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
      _savedTimeFormat = _draftTimeFormat;
      _savedFirstDay = _draftFirstDay;
      _savedUnits = _draftUnits;
      _savedTemp = _draftTemp;
      _saving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(AppLocalizations.of(context).dilBolgeKaydedildi),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            '${selectedCountry.name} · ${selectedCountry.currencySymbol}',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Canlı örnek — taslak seçime göre anlık biçim.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sampleChip(Icons.event_outlined, _previewDate()),
                    _sampleChip(Icons.schedule_outlined, _previewTime()),
                    _sampleChip(Icons.payments_outlined, _previewCurrency()),
                    _sampleChip(Icons.thermostat_outlined, _previewTemp()),
                  ],
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
                        Text(AppLocalizations.of(context).cihazDiliOtomatik,
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(
                            AppLocalizations.of(context)
                                .sistemDili(_deviceLanguageLabel),
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

          _sectionTitle(AppLocalizations.of(context).ulkeBolge),
          const SizedBox(height: 10),
          ...CountryConfig.all.map((c) {
            final sel = _draftCountry == c.code;
            return _RegionTile(
              country: c,
              selected: sel,
              onTap: () => _pickCountry(c),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              AppLocalizations.of(context).ulkeSecimiBilgi,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          const SizedBox(height: 22),

          // ── Saat formatı ──
          _sectionTitle(AppLocalizations.of(context).saatFormati),
          const SizedBox(height: 10),
          _segment(
            options: [('24h', AppLocalizations.of(context).saat24), ('12h', AppLocalizations.of(context).saat12)],
            value: _draftTimeFormat,
            onSelect: (v) {
              HapticFeedback.selectionClick();
              setState(() => _draftTimeFormat = v);
            },
          ),
          const SizedBox(height: 22),

          // ── Haftanın ilk günü ──
          _sectionTitle(AppLocalizations.of(context).haftaninIlkGunu),
          const SizedBox(height: 10),
          _segment(
            options: [('mon', AppLocalizations.of(context).pazartesi), ('sun', AppLocalizations.of(context).pazar)],
            value: _draftFirstDay,
            onSelect: (v) {
              HapticFeedback.selectionClick();
              setState(() => _draftFirstDay = v);
            },
          ),
          const SizedBox(height: 22),

          // ── Ölçü birimi ──
          _sectionTitle(AppLocalizations.of(context).olcuBirimi),
          const SizedBox(height: 10),
          _segment(
            options: [('metric', AppLocalizations.of(context).metrik), ('imperial', AppLocalizations.of(context).imperyal)],
            value: _draftUnits,
            onSelect: (v) {
              HapticFeedback.selectionClick();
              setState(() => _draftUnits = v);
            },
          ),
          const SizedBox(height: 22),

          // ── Sıcaklık birimi ──
          _sectionTitle(AppLocalizations.of(context).sicaklikBirimi),
          const SizedBox(height: 10),
          _segment(
            options: [('C', AppLocalizations.of(context).celsius), ('F', AppLocalizations.of(context).fahrenheit)],
            value: _draftTemp,
            onSelect: (v) {
              HapticFeedback.selectionClick();
              setState(() => _draftTemp = v);
            },
          ),
          const SizedBox(height: 28),

          // ── Sıfırlama (onaylı) — kullanıcı VERİSİNİ SİLMEZ ──
          _sectionTitle(AppLocalizations.of(context).sifirlama),
          const SizedBox(height: 10),
          _resetTile(
            icon: Icons.translate_rounded,
            title: AppLocalizations.of(context).dilTercihiniSifirla,
            subtitle: AppLocalizations.of(context).dilTercihiniSifirlaAcik,
            onTap: _confirmResetLanguage,
          ),
          const SizedBox(height: 8),
          _resetTile(
            icon: Icons.public_off_rounded,
            title: AppLocalizations.of(context).bolgeAyarlariniSifirla,
            subtitle: AppLocalizations.of(context).bolgeAyarlariniSifirlaAcik,
            onTap: _confirmResetRegion,
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
                    _dirty
                        ? AppLocalizations.of(context).kaydet
                        : AppLocalizations.of(context).kaydedildi,
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

  Widget _sampleChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _segment({
    required List<(String, String)> options,
    required String value,
    required ValueChanged<String> onSelect,
  }) =>
      Row(
        children: options.map((o) {
          final sel = value == o.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
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
                  child: Text(o.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              sel ? Colors.white : const Color(0xFF9CA3AF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _resetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x22EF4444)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFF87171), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Color(0xFFF3F4F6),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF6B7280), size: 20),
            ],
          ),
        ),
      );

  Future<bool> _confirmDialog(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(message,
            style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).vazgec,
                style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).sifirla),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _confirmResetLanguage() async {
    final t = AppLocalizations.of(context);
    final ok = await _confirmDialog(
      t.dilTercihiniSifirla,
      t.dilTercihiniSifirlaOnay,
    );
    if (!ok) return;
    await LocaleService.resetLanguagePreference();
    if (!mounted) return;
    final deviceLoc = _localeFor(_deviceLanguageLabel);
    ref.read(localeProvider.notifier).state = deviceLoc;
    setState(() {
      _savedDevice = false;
      _draftDevice = false;
      _savedLanguage = _deviceLanguageLabel;
      _draftLanguage = _deviceLanguageLabel;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).dilTercihiSifirlandi),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmResetRegion() async {
    final t = AppLocalizations.of(context);
    final ok = await _confirmDialog(
      t.bolgeAyarlariniSifirla,
      t.bolgeAyarlariniSifirlaOnay,
    );
    if (!ok) return;
    await HiveService.setSetting('dateFormat', 'DD/MM/YYYY');
    await HiveService.setSetting('timeFormat', '24h');
    await HiveService.setSetting('firstDayOfWeek', 'mon');
    await HiveService.setSetting('measurementSystem', 'metric');
    await HiveService.setSetting('tempUnit', 'C');
    if (!mounted) return;
    setState(() {
      _savedDateFormat = _draftDateFormat = 'DD/MM/YYYY';
      _savedTimeFormat = _draftTimeFormat = '24h';
      _savedFirstDay = _draftFirstDay = 'mon';
      _savedUnits = _draftUnits = 'metric';
      _savedTemp = _draftTemp = 'C';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).bolgeAyarlariSifirlandi),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
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
