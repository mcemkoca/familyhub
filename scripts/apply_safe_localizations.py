import json
import re
import sys
from pathlib import Path

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

value_to_key = {v: k for k, v in arb.items() if not k.startswith('@')}

import_statement = "import 'package:familyhub/l10n/app_localizations.dart';\n"

target = sys.argv[1] if len(sys.argv) > 1 else None

if target:
    files = [Path(target)]
else:
    files = list(Path('lib/presentation/screens').rglob('*.dart'))

total_replacements = 0
modified_files = 0

for dart_file in files:
    content = dart_file.read_text(encoding='utf-8')
    original = content
    file_replacements = 0
    
    has_import = 'app_localizations.dart' in content
    
    for value, key in sorted(value_to_key.items(), key=lambda x: -len(x[0])):
        escaped = re.escape(value)
        
        # const Text('value') -> Text(AppLocalizations.of(context)!.key)
        pattern1 = rf"const Text\('{escaped}'\)"
        replacement1 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count1 = re.subn(pattern1, replacement1, content)
        
        # Text('value') -> Text(AppLocalizations.of(context)!.key)
        pattern2 = rf"Text\('{escaped}'\)"
        replacement2 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count2 = re.subn(pattern2, replacement2, content)
        
        # const Text("value") -> Text(AppLocalizations.of(context)!.key)
        pattern3 = rf'const Text\("{escaped}"\)'
        replacement3 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count3 = re.subn(pattern3, replacement3, content)
        
        # Text("value") -> Text(AppLocalizations.of(context)!.key)
        pattern4 = rf'Text\("{escaped}"\)'
        replacement4 = f"Text(AppLocalizations.of(context)!.{key})"
        content, count4 = re.subn(pattern4, replacement4, content)
        
        file_replacements += count1 + count2 + count3 + count4
    
    if file_replacements > 0 and not has_import:
        import_lines = re.findall(r"^import .*;\n", content, re.MULTILINE)
        if import_lines:
            last_import = import_lines[-1]
            content = content.replace(last_import, last_import + import_statement, 1)
        else:
            content = import_statement + content
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        modified_files += 1
        total_replacements += file_replacements

print(f"Modified {modified_files} files, {total_replacements} replacements")
