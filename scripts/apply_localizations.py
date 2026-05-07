import json
import re
from pathlib import Path

with open('scripts/replacements.json', 'r', encoding='utf-8') as f:
    replacements = json.load(f)

# Filter out strings with interpolation
simple_replacements = {}
for value, key in replacements.items():
    if '${' not in value and '$' not in value:
        simple_replacements[value] = key

print(f"Simple replacements (no interpolation): {len(simple_replacements)}")

screen_dir = Path('lib/presentation/screens')
total_files = 0
modified_files = 0
total_replacements = 0

import_statement = "import 'package:familyhub/l10n/app_localizations.dart';\n"

for dart_file in screen_dir.rglob('*.dart'):
    total_files += 1
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Add import if missing
    if 'app_localizations.dart' not in content:
        # Find last import line
        import_lines = re.findall(r"^import .*;\n", content, re.MULTILINE)
        if import_lines:
            last_import = import_lines[-1]
            content = content.replace(last_import, last_import + import_statement, 1)
        else:
            content = import_statement + content
    
    # Replace const Text('value') and Text('value') where value is simple
    for value, key in sorted(simple_replacements.items(), key=lambda x: -len(x[0])):
        # Escape regex special chars in value
        escaped = re.escape(value)
        
        # Pattern: const Text('value') → Text(AppLocalizations.of(context)!.key)
        pattern1 = rf"const Text\('{escaped}'\)"
        replacement1 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count1 = re.subn(pattern1, replacement1, content)
        
        # Pattern: Text('value') → Text(AppLocalizations.of(context)!.key)
        pattern2 = rf"Text\('{escaped}'\)"
        replacement2 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count2 = re.subn(pattern2, replacement2, content)
        
        # Pattern: const Text("value") → Text(AppLocalizations.of(context)!.key)
        pattern3 = rf'const Text\("{escaped}"\)'
        replacement3 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count3 = re.subn(pattern3, replacement3, content)
        
        # Pattern: Text("value") → Text(AppLocalizations.of(context)!.key)
        pattern4 = rf'Text\("{escaped}"\)'
        replacement4 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count4 = re.subn(pattern4, replacement4, content)
        
        total_replacements += count1 + count2 + count3 + count4
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        modified_files += 1

print(f"Modified {modified_files}/{total_files} files")
print(f"Total replacements: {total_replacements}")
