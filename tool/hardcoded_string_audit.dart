import 'dart:convert';
import 'dart:io';

/// Heuristic scanner for user-facing hard-coded strings in Flutter source.
///
/// Usage:
///   dart run tool/hardcoded_string_audit.dart
///   dart run tool/hardcoded_string_audit.dart --strict
///
/// This scanner intentionally favors recall over precision. Findings must be
/// reviewed before conversion to localization keys.
void main(List<String> args) {
  final strict = args.contains('--strict');
  final sourceDirectory = Directory('lib');

  if (!sourceDirectory.existsSync()) {
    stderr.writeln('ERROR: lib directory was not found.');
    exitCode = 2;
    return;
  }

  final findings = <Map<String, dynamic>>[];
  final dartFiles = sourceDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}app_localizations'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_shouldSkipLine(line)) {
        continue;
      }

      for (final rule in _rules) {
        for (final match in rule.pattern.allMatches(line)) {
          final value = match.namedGroup('value')?.trim();
          if (value == null || !_looksUserFacing(value)) {
            continue;
          }

          findings.add({
            'file': file.path.replaceAll('\\', '/'),
            'line': index + 1,
            'kind': rule.name,
            'value': value,
            'source': line.trim(),
          });
        }
      }
    }
  }

  final byFile = <String, int>{};
  for (final finding in findings) {
    final file = finding['file'] as String;
    byFile[file] = (byFile[file] ?? 0) + 1;
  }

  final report = {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'findingCount': findings.length,
    'fileCount': byFile.length,
    'byFile': Map.fromEntries(
      byFile.entries.toList()
        ..sort((left, right) => right.value.compareTo(left.value)),
    ),
    'findings': findings,
  };

  final outputDirectory = Directory('build')..createSync(recursive: true);
  final outputFile = File(
    '${outputDirectory.path}/hardcoded_string_audit.json',
  );
  const encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync('${encoder.convert(report)}\n');

  stdout.writeln('FamilyHub hard-coded string audit');
  stdout.writeln('Dart files scanned: ${dartFiles.length}');
  stdout.writeln('Potential user-facing strings: ${findings.length}');
  stdout.writeln('Affected files: ${byFile.length}');
  stdout.writeln('Report: ${outputFile.path}');

  if (strict && findings.isNotEmpty) {
    exitCode = 1;
  }
}

bool _shouldSkipLine(String line) {
  final trimmed = line.trim();
  return trimmed.isEmpty ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('///') ||
      trimmed.startsWith('import ') ||
      trimmed.startsWith('export ') ||
      trimmed.startsWith('part ') ||
      trimmed.contains('debugPrint(') ||
      trimmed.contains('print(') ||
      trimmed.contains('String.fromEnvironment(') ||
      trimmed.contains('RegExp(') ||
      trimmed.contains('routeName:') ||
      trimmed.contains('analyticsEvent') ||
      trimmed.contains('eventName:') ||
      trimmed.contains('table(') ||
      trimmed.contains("from('") ||
      trimmed.contains('Supabase') ||
      trimmed.contains('HiveService.getSetting(') ||
      trimmed.contains('HiveService.setSetting(');
}

bool _looksUserFacing(String value) {
  if (value.length < 2) {
    return false;
  }
  if (value.startsWith(r'$') || value.startsWith('{')) {
    return false;
  }
  if (RegExp(r'^[a-z0-9_./:-]+$').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'^#[0-9A-Fa-f]{6,8}$').hasMatch(value)) {
    return false;
  }
  if (value.startsWith('package:') || value.startsWith('assets/')) {
    return false;
  }
  return RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşüÀ-ÿ]').hasMatch(value);
}

class _AuditRule {
  const _AuditRule(this.name, this.pattern);

  final String name;
  final RegExp pattern;
}

final _rules = <_AuditRule>[
  _AuditRule(
    'Text',
    RegExp(r'''\bText\(\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'label',
    RegExp(r'''\blabel\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'title',
    RegExp(r'''\btitle\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'description',
    RegExp(r'''\bdescription\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'hintText',
    RegExp(r'''\bhintText\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'helperText',
    RegExp(r'''\bhelperText\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'errorText',
    RegExp(r'''\berrorText\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'tooltip',
    RegExp(r'''\btooltip\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'semanticLabel',
    RegExp(r'''\bsemanticLabel\s*:\s*(?:const\s+)?[\"'](?<value>[^\"']+)[\"']'''),
  ),
  _AuditRule(
    'SnackBar',
    RegExp(r'''SnackBar\([^\n]*[\"'](?<value>[^\"']+)[\"']'''),
  ),
];
