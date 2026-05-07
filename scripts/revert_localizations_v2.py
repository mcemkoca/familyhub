import json
import re
from pathlib import Path

with open('scripts/extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

screen_dir = Path('lib/presentation/screens')
reverted = 0

for dart_file in screen_dir.rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Remove import if present
    content = re.sub(r"^import 'package:familyhub/l10n/app_localizations\.dart';\n", "", content, flags=re.MULTILINE)
    
    # Build pattern to match AppLocalizations.of(context)!.key where key contains Turkish chars
    # Revert Text(AppLocalizations.of(context)!.key) to Text('value')
    for key, value in extracted.items():
        escaped_value = value.replace("'", "\\'").replace('\\n', '\n')
        
        # const Text(AppLocalizations.of(context)!.key) -> const Text('value')
        pattern1 = rf"const Text\(AppLocalizations\.of\(context\)!\.{re.escape(key)}\)"
        replacement1 = f"const Text('{escaped_value}')"
        content = re.sub(pattern1, replacement1, content)
        
        # Text(AppLocalizations.of(context)!.key) -> Text('value')
        pattern2 = rf"Text\(AppLocalizations\.of\(context\)!\.{re.escape(key)}\)"
        replacement2 = f"Text('{escaped_value}')"
        content = re.sub(pattern2, replacement2, content)
        
        # Also revert standalone AppLocalizations.of(context)!.key (e.g. in labels)
        pattern3 = rf"AppLocalizations\.of\(context\)!\.{re.escape(key)}"
        replacement3 = f"'{escaped_value}'"
        content = re.sub(pattern3, replacement3, content)
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        reverted += 1

print(f"Reverted {reverted} files")
