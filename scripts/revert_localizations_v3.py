import json
import re
from pathlib import Path

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

key_to_value = {k: v for k, v in arb.items() if not k.startswith('@')}

screen_dir = Path('lib/presentation/screens')
reverted = 0

for dart_file in screen_dir.rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Remove import
    content = re.sub(r"^import 'package:familyhub/l10n/app_localizations\.dart';\n", "", content, flags=re.MULTILINE)
    
    # Revert const Text(AppLocalizations.of(context)!.key) -> const Text('value')
    def revert_const_text(m):
        key = m.group(1)
        val = key_to_value.get(key)
        if val is None: return m.group(0)
        esc = val.replace("'", "\\'").replace('\\n', '\n')
        return f"const Text('{esc}')"
    content = re.sub(r"const Text\(AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)\)", revert_const_text, content)
    
    # Revert Text(AppLocalizations.of(context)!.key) -> Text('value')
    def revert_text(m):
        key = m.group(1)
        val = key_to_value.get(key)
        if val is None: return m.group(0)
        esc = val.replace("'", "\\'").replace('\\n', '\n')
        return f"Text('{esc}')"
    content = re.sub(r"Text\(AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)\)", revert_text, content)
    
    # Revert standalone AppLocalizations.of(context)!.key -> 'value'
    def revert_standalone(m):
        key = m.group(1)
        val = key_to_value.get(key)
        if val is None: return m.group(0)
        esc = val.replace("'", "\\'").replace('\\n', '\n')
        return f"'{esc}'"
    content = re.sub(r"AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)", revert_standalone, content)
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        reverted += 1

print(f"Reverted {reverted} files")
