import json
import re
from pathlib import Path

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

# Build reverse mapping: normalized key -> value
key_to_value = {k: v for k, v in arb.items() if not k.startswith('@')}

screen_dir = Path('lib/presentation/screens')
reverted = 0

for dart_file in screen_dir.rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Remove import if present
    content = re.sub(r"^import 'package:familyhub/l10n/app_localizations\.dart';\n", "", content, flags=re.MULTILINE)
    
    # Revert Text(AppLocalizations.of(context)!.key) to Text('value')
    def revert_text(match):
        key = match.group(1)
        value = key_to_value.get(key)
        if value is None:
            return match.group(0)
        escaped = value.replace("'", "\\'").replace('\\n', '\n')
        return f"Text('{escaped}')"
    
    content = re.sub(r"Text\(AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)\)", revert_text, content)
    
    # Revert const Text(AppLocalizations.of(context)!.key) to const Text('value')
    def revert_const_text(match):
        key = match.group(1)
        value = key_to_value.get(key)
        if value is None:
            return match.group(0)
        escaped = value.replace("'", "\\'").replace('\\n', '\n')
        return f"const Text('{escaped}')"
    
    content = re.sub(r"const Text\(AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)\)", revert_const_text, content)
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        reverted += 1

print(f"Reverted {reverted} files")
