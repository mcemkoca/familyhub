import 'package:flutter/widgets.dart';
import '../hive_service.dart';

/// Kullanıcının dil kararı durumu — dil önerisi dialogunun tekrar tekrar
/// gösterilmesini engeller ve kaynağı (manuel/cihaz) izler.
enum LocaleDecision {
  notAsked,
  acceptedDeviceLocale,
  selectedManually,
  dismissed,
  migratedFromLegacy,
}

/// Merkezi locale çözümleme + kalıcılık servisi.
/// PRENSİP: kullanıcı seçimini cihaz diliyle sessizce EZMEZ. Sağlayıcı
/// içinde yan-etki (Hive yazımı) YAPMAZ — yazım yalnızca açık kullanıcı
/// eylemlerinde (selectManually / acceptDeviceLocale / dismiss) olur.
class LocaleService {
  LocaleService._();

  static const _kLanguage = 'language'; // etiket: 'Türkçe' | 'English' | ...
  static const _kDecision = 'localeDecision';
  static const _kUseDevice = 'useDeviceLanguage';

  /// Desteklenen dil kodları (ülke varyantından bağımsız).
  static const supportedCodes = {'tr', 'en', 'nl', 'fr'};

  static String labelForCode(String code) => switch (code) {
        'en' => 'English',
        'nl' => 'Nederlands',
        'fr' => 'Français',
        _ => 'Türkçe',
      };

  static Locale localeForLabel(String label) => switch (label) {
        'English' => const Locale('en', 'US'),
        'Nederlands' => const Locale('nl', 'NL'),
        'Français' => const Locale('fr', 'FR'),
        _ => const Locale('tr', 'TR'),
      };

  /// Cihazın tercih listesindeki İLK desteklenen dil kodu (yoksa null).
  /// PlatformDispatcher.locales kullanıcının sıralı dil tercihlerini verir.
  static String? deviceSupportedCode() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    for (final l in locales) {
      if (supportedCodes.contains(l.languageCode)) return l.languageCode;
    }
    return null;
  }

  /// Cihazın birincil dil etiketi (desteklenmiyorsa yine de en yakın etiket).
  static String deviceLanguageLabel() =>
      labelForCode(deviceSupportedCode() ?? 'tr');

  /// Cihazın birincil dili desteklenen bir dil mi?
  static bool get isDeviceLanguageSupported => deviceSupportedCode() != null;

  static LocaleDecision decision() {
    final raw = HiveService.getSetting(_kDecision);
    return LocaleDecision.values.firstWhere(
      (d) => d.name == raw,
      orElse: () => LocaleDecision.notAsked,
    );
  }

  static Future<void> _setDecision(LocaleDecision d) =>
      HiveService.setSetting(_kDecision, d.name);

  static bool get useDeviceLanguage =>
      HiveService.getBoolSetting(_kUseDevice, defaultValue: false);

  static String? get savedLanguageLabel {
    final s = HiveService.getSetting(_kLanguage);
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Başlangıç locale'i — TAMAMEN YAN-ETKİSİZ (Hive'a yazmaz).
  /// Öncelik: cihaz-dili modu → kayıtlı manuel seçim → cihaz locales → fallback tr.
  static Locale resolveInitialLocale() {
    if (useDeviceLanguage) {
      return localeForLabel(deviceLanguageLabel());
    }
    final saved = savedLanguageLabel;
    if (saved != null) return localeForLabel(saved);
    // Karar verilmemiş: cihaz dilini GÖSTER ama KAYDETME (dialog karar verecek).
    return localeForLabel(deviceLanguageLabel());
  }

  /// İlk açılış dil önerisi dialogu gösterilmeli mi?
  /// Yalnızca karar verilmemiş VE kayıtlı dil yoksa. (Legacy kullanıcılar —
  /// kayıtlı dili olan ama kararı olmayan — tekrar rahatsız edilmez.)
  static bool shouldSuggestLanguage() {
    if (decision() != LocaleDecision.notAsked) return false;
    return savedLanguageLabel == null;
  }

  // ── Açık kullanıcı eylemleri (kalıcılık burada olur) ──

  static Future<void> selectManually(String label) async {
    await HiveService.setBoolSetting(_kUseDevice, false);
    await HiveService.setSetting(_kLanguage, label);
    await _setDecision(LocaleDecision.selectedManually);
  }

  static Future<void> acceptDeviceLocale() async {
    await HiveService.setBoolSetting(_kUseDevice, true);
    await HiveService.setSetting(_kLanguage, deviceLanguageLabel());
    await _setDecision(LocaleDecision.acceptedDeviceLocale);
  }

  /// "Şimdilik mevcut dille devam" — gösterilen dili sabitler, tekrar sormaz.
  static Future<void> dismissSuggestion() async {
    if (savedLanguageLabel == null) {
      await HiveService.setSetting(_kLanguage, deviceLanguageLabel());
    }
    await _setDecision(LocaleDecision.dismissed);
  }

  /// Dil tercihini sıfırla — KULLANICI VERİSİNİ SİLMEZ, yalnızca dil kararını.
  static Future<void> resetLanguagePreference() async {
    await HiveService.setSetting(_kLanguage, '');
    await HiveService.setBoolSetting(_kUseDevice, false);
    await _setDecision(LocaleDecision.notAsked);
  }
}
