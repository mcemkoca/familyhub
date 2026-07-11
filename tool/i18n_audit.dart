import 'dart:convert';
import 'dart:io';

/// FamilyHub localization quality audit.
///
/// Usage:
///   dart run tool/i18n_audit.dart
///   dart run tool/i18n_audit.dart --strict
///
/// The audit checks:
/// - required locale files (TR/NL/FR/EN)
/// - key parity against the Turkish template
/// - placeholder parity
/// - empty translations
/// - likely Turkish leakage in non-Turkish locales
/// - suspicious values copied unchanged from Turkish
void main(List<String> args) {
  const requiredLocales = <String>['tr', 'nl', 'fr', 'en'];
  const templateLocale = 'tr';
  final strict = args.contains('--strict');

  final l10nDirectory = Directory('lib/l10n');
  if (!l10nDirectory.existsSync()) {
    stderr.writeln('ERROR: lib/l10n directory was not found.');
    exitCode = 2;
    return;
  }

  final localeDocuments = <String, Map<String, dynamic>>{};
  final fileErrors = <String>[];

  for (final locale in requiredLocales) {
    final file = File('${l10nDirectory.path}/app_$locale.arb');
    if (!file.existsSync()) {
      fileErrors.add('Missing locale file: ${file.path}');
      continue;
    }

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        fileErrors.add('${file.path} does not contain a JSON object.');
        continue;
      }
      localeDocuments[locale] = decoded;
    } on FormatException catch (error) {
      fileErrors.add('Invalid JSON in ${file.path}: ${error.message}');
    }
  }

  final template = localeDocuments[templateLocale];
  if (template == null) {
    stderr.writeln('ERROR: Template locale app_$templateLocale.arb is unavailable.');
    for (final error in fileErrors) {
      stderr.writeln('- $error');
    }
    exitCode = 2;
    return;
  }

  final templateKeys = _messageKeys(template);
  final findings = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'templateLocale': templateLocale,
    'requiredLocales': requiredLocales,
    'templateKeyCount': templateKeys.length,
    'fileErrors': fileErrors,
    'locales': <String, dynamic>{},
  };

  var blockingIssueCount = fileErrors.length;
  var warningCount = 0;

  for (final locale in requiredLocales) {
    final document = localeDocuments[locale];
    if (document == null) {
      continue;
    }

    final keys = _messageKeys(document);
    final missingKeys = templateKeys.difference(keys).toList()..sort();
    final extraKeys = keys.difference(templateKeys).toList()..sort();
    final emptyValues = <String>[];
    final placeholderMismatches = <Map<String, dynamic>>[];
    final copiedFromTemplate = <String>[];
    final likelyTurkishLeakage = <String>[];

    for (final key in templateKeys.intersection(keys)) {
      final templateValue = template[key];
      final localeValue = document[key];
      if (localeValue is! String) {
        emptyValues.add(key);
        continue;
      }

      if (localeValue.trim().isEmpty) {
        emptyValues.add(key);
      }

      final expectedPlaceholders = _placeholders(templateValue);
      final actualPlaceholders = _placeholders(localeValue);
      if (!_setEquals(expectedPlaceholders, actualPlaceholders)) {
        placeholderMismatches.add({
          'key': key,
          'expected': expectedPlaceholders.toList()..sort(),
          'actual': actualPlaceholders.toList()..sort(),
        });
      }

      if (locale != templateLocale && templateValue is String) {
        if (_normalized(templateValue) == _normalized(localeValue) &&
            !_isAllowedSameValue(key, localeValue)) {
          copiedFromTemplate.add(key);
        }

        if (_looksTurkish(localeValue) && !_isAllowedSameValue(key, localeValue)) {
          likelyTurkishLeakage.add(key);
        }
      }
    }

    final translatedCount = templateKeys.length - missingKeys.length;
    final coverage = templateKeys.isEmpty
        ? 1.0
        : translatedCount / templateKeys.length;

    findings['locales'][locale] = {
      'keyCount': keys.length,
      'translatedKeyCount': translatedCount,
      'coveragePercent': double.parse((coverage * 100).toStringAsFixed(2)),
      'missingKeys': missingKeys,
      'extraKeys': extraKeys,
      'emptyValues': emptyValues,
      'placeholderMismatches': placeholderMismatches,
      'copiedFromTemplate': copiedFromTemplate,
      'likelyTurkishLeakage': likelyTurkishLeakage,
    };

    blockingIssueCount +=
        missingKeys.length + emptyValues.length + placeholderMismatches.length;
    warningCount +=
        extraKeys.length + copiedFromTemplate.length + likelyTurkishLeakage.length;
  }

  findings['summary'] = {
    'blockingIssueCount': blockingIssueCount,
    'warningCount': warningCount,
    'strictMode': strict,
  };

  final outputDirectory = Directory('build');
  outputDirectory.createSync(recursive: true);
  final outputFile = File('${outputDirectory.path}/i18n_audit.json');
  const encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync('${encoder.convert(findings)}\n');

  stdout.writeln('FamilyHub i18n audit');
  stdout.writeln('Template keys: ${templateKeys.length}');
  for (final locale in requiredLocales) {
    final localeResult = findings['locales'][locale];
    if (localeResult == null) {
      stdout.writeln('$locale: locale file missing');
      continue;
    }
    stdout.writeln(
      '$locale: ${localeResult['coveragePercent']}% coverage, '
      '${(localeResult['missingKeys'] as List).length} missing, '
      '${(localeResult['placeholderMismatches'] as List).length} placeholder errors, '
      '${(localeResult['likelyTurkishLeakage'] as List).length} likely Turkish leaks',
    );
  }
  stdout.writeln('Report: ${outputFile.path}');

  if (strict && blockingIssueCount > 0) {
    exitCode = 1;
  }
}

Set<String> _messageKeys(Map<String, dynamic> document) => document.keys
    .where((key) => !key.startsWith('@'))
    .toSet();

Set<String> _placeholders(dynamic value) {
  if (value is! String) {
    return <String>{};
  }
  final matches = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}').allMatches(value);
  return matches.map((match) => match.group(1)!).toSet();
}

bool _setEquals(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

String _normalized(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

bool _isAllowedSameValue(String key, String value) {
  const allowedKeys = <String>{
    'appTitle',
    'email',
    'phone',
    'premium',
    'admin',
    'online',
    'qrShare',
  };
  if (allowedKeys.contains(key)) {
    return true;
  }

  final compact = value.trim();
  if (compact.isEmpty) {
    return false;
  }

  // Values made only of numbers, punctuation, emojis, codes or placeholders
  // are valid across locales.
  return !RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(compact);
}

bool _looksTurkish(String value) {
  if (RegExp(r'[ÇĞİıÖŞÜçğöşü]').hasMatch(value)) {
    return true;
  }

  final normalized = ' ${_normalized(value)} ';
  const commonTurkishTokens = <String>[
    ' için ',
    ' veya ',
    ' henüz ',
    ' ayarlar ',
    ' görev ',
    ' aile ',
    ' çocuk ',
    ' sağlık ',
    ' eğitim ',
    ' gelişim ',
    ' alışveriş ',
    ' bütçe ',
    ' kaydet ',
    ' sil ',
    ' düzenle ',
    ' oluştur ',
    ' güncelle ',
    ' bulunamadı ',
    ' başarısız ',
    ' gerekiyor ',
    ' istediğinize ',
  ];
  return commonTurkishTokens.any(normalized.contains);
}
