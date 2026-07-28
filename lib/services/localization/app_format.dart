import 'package:intl/intl.dart';
import '../hive_service.dart';
import 'locale_service.dart';

/// Locale-duyarlı biçimlendirme — sabit '₺', 'tr_TR', 'dd.MM.yyyy' yerine.
/// Dil (görüntü) ile bölge/para birimi AYRI ele alınır:
///   • tarih/sayı biçimi → aktif UYGULAMA DİLİ locale'i
///   • para birimi kodu → aktif BÖLGE tercihi (Hive 'currency'), yoksa EUR
class AppFormat {
  AppFormat._();

  /// Aktif uygulama dilinin intl locale kodu (tr_TR, en_US, fr_BE, nl_BE).
  static String get currentLocale {
    final label =
        LocaleService.savedLanguageLabel ?? LocaleService.deviceLanguageLabel();
    final loc = LocaleService.localeForLabel(label);
    return loc.countryCode == null
        ? loc.languageCode
        : '${loc.languageCode}_${loc.countryCode}';
  }

  /// Aktif bölgenin para birimi kodu (Hive 'currency'), yoksa EUR.
  static String get currencyCode =>
      HiveService.getSetting('currency') ?? 'EUR';

  static String _symbolFor(String code) => switch (code) {
        'TRY' => '₺',
        'EUR' => '€',
        'USD' => '\$',
        'GBP' => '£',
        _ => code,
      };

  /// Para biçimi — locale + bölge para birimine göre.
  static String currency(
    num amount, {
    String? code,
    String? locale,
    int decimalDigits = 0,
  }) {
    final c = code ?? currencyCode;
    return NumberFormat.currency(
      locale: locale ?? currentLocale,
      symbol: _symbolFor(c),
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  /// Tarih biçimi — aktif dile göre (pattern yerelleştirilmiş ay/gün adları).
  static String date(DateTime d, {String pattern = 'dd MMM yyyy', String? locale}) =>
      DateFormat(pattern, locale ?? currentLocale).format(d);

  static String dateLong(DateTime d, {String? locale}) =>
      DateFormat('dd MMMM yyyy', locale ?? currentLocale).format(d);

  static String monthYear(DateTime d, {String? locale}) =>
      DateFormat('MMMM yyyy', locale ?? currentLocale).format(d);

  static String time(DateTime d, {String? locale}) =>
      DateFormat('HH:mm', locale ?? currentLocale).format(d);

  static String number(num n, {String? locale}) =>
      NumberFormat.decimalPattern(locale ?? currentLocale).format(n);

  static String percent(num ratio, {String? locale, int decimals = 0}) {
    final f = NumberFormat.percentPattern(locale ?? currentLocale);
    f.maximumFractionDigits = decimals;
    return f.format(ratio);
  }
}
