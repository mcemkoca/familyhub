import 'package:flutter/material.dart';

/// Merkezi ülke yapılandırması.
/// Ülkeye bağlı her şey (dil, para birimi, bayrak, gider şablonu anahtarı)
/// buradan yönetilir. Register + Ayarlar bu listeyi kullanır.
class Country {
  final String code; // BE, TR, NL, FR, DE
  final String name; // Belçika
  final String flag; // 🇧🇪
  final String languageLabel; // uygulama dili etiketi
  final Locale locale;
  final String currencyCode; // EUR, TRY
  final String currencySymbol; // €, ₺
  final String dateFormat;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.languageLabel,
    required this.locale,
    required this.currencyCode,
    required this.currencySymbol,
    required this.dateFormat,
  });

  String get display => '$flag  $name';
}

class CountryConfig {
  CountryConfig._();

  static const List<Country> all = [
    Country(
      code: 'BE', name: 'Belçika', flag: '🇧🇪',
      languageLabel: 'Nederlands', locale: Locale('nl', 'BE'),
      currencyCode: 'EUR', currencySymbol: '€', dateFormat: 'DD/MM/YYYY',
    ),
    Country(
      code: 'TR', name: 'Türkiye', flag: '🇹🇷',
      languageLabel: 'Türkçe', locale: Locale('tr', 'TR'),
      currencyCode: 'TRY', currencySymbol: '₺', dateFormat: 'DD/MM/YYYY',
    ),
    Country(
      code: 'NL', name: 'Hollanda', flag: '🇳🇱',
      languageLabel: 'Nederlands', locale: Locale('nl', 'NL'),
      currencyCode: 'EUR', currencySymbol: '€', dateFormat: 'DD-MM-YYYY',
    ),
    Country(
      code: 'FR', name: 'Fransa', flag: '🇫🇷',
      languageLabel: 'Français', locale: Locale('fr', 'FR'),
      currencyCode: 'EUR', currencySymbol: '€', dateFormat: 'DD/MM/YYYY',
    ),
    Country(
      code: 'DE', name: 'Almanya', flag: '🇩🇪',
      languageLabel: 'Deutsch', locale: Locale('de', 'DE'),
      currencyCode: 'EUR', currencySymbol: '€', dateFormat: 'DD.MM.YYYY',
    ),
  ];

  static const Country fallback = Country(
    code: 'BE', name: 'Belçika', flag: '🇧🇪',
    languageLabel: 'Nederlands', locale: Locale('nl', 'BE'),
    currencyCode: 'EUR', currencySymbol: '€', dateFormat: 'DD/MM/YYYY',
  );

  static Country byCode(String? code) {
    return all.firstWhere((c) => c.code == code, orElse: () => fallback);
  }
}
