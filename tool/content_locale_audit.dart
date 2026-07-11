import 'dart:convert';
import 'dart:io';

/// Audits JSON-backed FamilyHub content for TR/NL/FR/EN readiness.
///
/// The scanner reports:
/// - JSON files containing user-facing text
/// - records without a translations map
/// - missing tr/nl/fr/en translations
/// - empty localized values
/// - likely Turkish-only content in generic assets
/// - external URLs and whether source metadata is present
void main() {
  const requiredLocales = <String>['tr', 'nl', 'fr', 'en'];
  final roots = <Directory>[
    Directory('assets/data'),
  ].where((directory) => directory.existsSync()).toList();

  final files = <File>[];
  for (final root in roots) {
    files.addAll(
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json')),
    );
  }
  files.sort((a, b) => a.path.compareTo(b.path));

  final findings = <Map<String, dynamic>>[];
  final fileSummary = <String, Map<String, dynamic>>{};

  for (final file in files) {
    dynamic document;
    try {
      document = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      findings.add({
        'severity': 'error',
        'type': 'invalid_json',
        'file': _path(file),
        'message': error.message,
      });
      continue;
    }

    final state = _FileState(file: _path(file));
    _visit(
      document,
      r'$',
      requiredLocales,
      state,
      findings,
    );
    fileSummary[state.file] = state.toJson();
  }

  final report = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'requiredLocales': requiredLocales,
    'filesScanned': files.length,
    'findingCount': findings.length,
    'files': fileSummary,
    'findings': findings,
    'summary': {
      'errors': findings.where((f) => f['severity'] == 'error').length,
      'warnings': findings.where((f) => f['severity'] == 'warning').length,
      'info': findings.where((f) => f['severity'] == 'info').length,
      'filesWithUserFacingText': fileSummary.values
          .where((value) => (value['userFacingStringCount'] as int) > 0)
          .length,
      'translationMapsFound': fileSummary.values.fold<int>(
        0,
        (sum, value) => sum + value['translationMapCount'] as int,
      ),
    },
  };

  final output = Directory('build')..createSync(recursive: true);
  final outputFile = File('${output.path}/content_locale_audit.json');
  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );

  stdout.writeln('FamilyHub content locale audit');
  stdout.writeln('JSON files scanned: ${files.length}');
  stdout.writeln('Findings: ${findings.length}');
  stdout.writeln('Report: ${outputFile.path}');
}

void _visit(
  dynamic node,
  String pointer,
  List<String> requiredLocales,
  _FileState state,
  List<Map<String, dynamic>> findings,
) {
  if (node is Map<String, dynamic>) {
    final translations = node['translations'];
    if (translations is Map<String, dynamic>) {
      state.translationMapCount++;
      for (final locale in requiredLocales) {
        if (!translations.containsKey(locale)) {
          findings.add({
            'severity': 'error',
            'type': 'missing_locale',
            'file': state.file,
            'pointer': '$pointer.translations',
            'locale': locale,
          });
          continue;
        }
        final localized = translations[locale];
        if (_isEmptyLocalizedValue(localized)) {
          findings.add({
            'severity': 'error',
            'type': 'empty_locale',
            'file': state.file,
            'pointer': '$pointer.translations.$locale',
            'locale': locale,
          });
        }
      }
    }

    for (final entry in node.entries) {
      final key = entry.key;
      final value = entry.value;
      final childPointer = '$pointer.${_escape(key)}';

      if (value is String && _isUserFacingKey(key) && _looksUserFacing(value)) {
        state.userFacingStringCount++;
        if (translations is! Map<String, dynamic>) {
          findings.add({
            'severity': _looksTurkish(value) ? 'warning' : 'info',
            'type': _looksTurkish(value)
                ? 'turkish_only_user_content'
                : 'unlocalized_user_content',
            'file': state.file,
            'pointer': childPointer,
            'key': key,
            'value': _truncate(value),
          });
        }
      }

      if (value is String && _looksLikeUrl(value)) {
        state.urlCount++;
      }

      _visit(value, childPointer, requiredLocales, state, findings);
    }
    return;
  }

  if (node is List) {
    for (var index = 0; index < node.length; index++) {
      _visit(
        node[index],
        '$pointer[$index]',
        requiredLocales,
        state,
        findings,
      );
    }
  }
}

bool _isEmptyLocalizedValue(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Map) {
    return value.values.every(_isEmptyLocalizedValue);
  }
  if (value is List) {
    return value.isEmpty || value.every(_isEmptyLocalizedValue);
  }
  return false;
}

bool _isUserFacingKey(String key) {
  final normalized = key.toLowerCase();
  const tokens = <String>{
    'title',
    'name',
    'summary',
    'description',
    'body',
    'content',
    'subtitle',
    'label',
    'tip',
    'text',
    'message',
    'instruction',
    'steps',
    'ingredients',
    'benefits',
    'warning',
    'question',
    'answer',
    'activity',
    'suggestion',
    'goal',
  };
  return tokens.any(normalized.contains);
}

bool _looksUserFacing(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 3 || _looksLikeUrl(trimmed)) return false;
  if (RegExp(r'^[a-z0-9_./:-]+$').hasMatch(trimmed)) return false;
  return RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşüÀ-ÿ]').hasMatch(trimmed);
}

bool _looksTurkish(String value) {
  if (RegExp(r'[ÇĞİıÖŞÜçğöşü]').hasMatch(value)) return true;
  final text = ' ${value.toLowerCase()} ';
  const tokens = <String>[
    ' aile ',
    ' çocuk ',
    ' görev ',
    ' için ',
    ' veya ',
    ' yemek ',
    ' sağlık ',
    ' eğitim ',
    ' gelişim ',
    ' alışveriş ',
    ' bütçe ',
    ' öneri ',
    ' aktivite ',
    ' malzeme ',
    ' dakika ',
  ];
  return tokens.any(text.contains);
}

bool _looksLikeUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

String _escape(String value) => value.replaceAll('.', r'\.');
String _path(File file) => file.path.replaceAll('\\', '/');
String _truncate(String value) =>
    value.length <= 180 ? value : '${value.substring(0, 177)}...';

class _FileState {
  _FileState({required this.file});

  final String file;
  int userFacingStringCount = 0;
  int translationMapCount = 0;
  int urlCount = 0;

  Map<String, dynamic> toJson() => {
        'userFacingStringCount': userFacingStringCount,
        'translationMapCount': translationMapCount,
        'urlCount': urlCount,
      };
}
