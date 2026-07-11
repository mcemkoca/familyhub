import 'package:flutter/material.dart';

/// The only application languages enabled during the current FamilyHub
/// localization rollout.
enum AppLanguage {
  turkish(
    code: 'tr',
    nativeName: 'Türkçe',
    locale: Locale('tr', 'TR'),
  ),
  dutch(
    code: 'nl',
    nativeName: 'Nederlands',
    locale: Locale('nl', 'BE'),
  ),
  french(
    code: 'fr',
    nativeName: 'Français',
    locale: Locale('fr', 'BE'),
  ),
  english(
    code: 'en',
    nativeName: 'English',
    locale: Locale('en', 'GB'),
  );

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.locale,
  });

  final String code;
  final String nativeName;
  final Locale locale;

  static const defaultLanguage = AppLanguage.turkish;

  static AppLanguage fromStoredValue(String? value) {
    final normalized = value?.trim().toLowerCase();

    return switch (normalized) {
      'tr' || 'tr_tr' || 'tr-tr' || 'türkçe' || 'turkce' =>
        AppLanguage.turkish,
      'nl' || 'nl_be' || 'nl-be' || 'nl_nl' || 'nl-nl' || 'nederlands' =>
        AppLanguage.dutch,
      'fr' || 'fr_be' || 'fr-be' || 'fr_fr' || 'fr-fr' || 'français' ||
      'francais' => AppLanguage.french,
      'en' || 'en_gb' || 'en-gb' || 'en_us' || 'en-us' || 'english' =>
        AppLanguage.english,

      // German was exposed by the old settings screen but never had complete
      // localization resources. Preserve a readable experience by migrating it
      // to English instead of silently falling back to Turkish.
      'de' || 'de_de' || 'de-de' || 'deutsch' => AppLanguage.english,
      _ => defaultLanguage,
    };
  }

  static AppLanguage fromLocale(Locale locale) {
    return values.firstWhere(
      (language) => language.code == locale.languageCode.toLowerCase(),
      orElse: () => defaultLanguage,
    );
  }
}

const supportedAppLocales = <Locale>[
  Locale('tr', 'TR'),
  Locale('nl', 'BE'),
  Locale('fr', 'BE'),
  Locale('en', 'GB'),
];
