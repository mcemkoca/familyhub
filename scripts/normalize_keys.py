import json
import re
from pathlib import Path

def normalize_key(key):
    # Turkish to ASCII
    mapping = {
        'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
        'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U'
    }
    for tr, asc in mapping.items():
        key = key.replace(tr, asc)
    
    # Remove non-alphanumeric except underscore
    key = re.sub(r'[^a-zA-Z0-9_]', '', key)
    
    # Ensure doesn't start with number or underscore
    key = re.sub(r'^[0-9_]+', '', key)
    
    # camelCase
    if '_' in key:
        parts = key.split('_')
        key = parts[0].lower() + ''.join(p.capitalize() for p in parts[1:] if p)
    else:
        key = key[0].lower() + key[1:] if key else 'key'
    
    if not key:
        key = 'key'
    return key

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

new_arb = {}
key_map = {}  # old_key -> new_key
for old_key, value in arb.items():
    if old_key.startswith('@'):
        # Keep metadata keys but also normalize the base key reference
        new_arb[old_key] = value
        continue
    new_key = normalize_key(old_key)
    # Handle collisions
    base = new_key
    counter = 1
    while new_key in new_arb:
        new_key = f"{base}{counter}"
        counter += 1
    new_arb[new_key] = value
    key_map[old_key] = new_key

with open('lib/l10n/app_tr.arb', 'w', encoding='utf-8') as f:
    json.dump(new_arb, f, ensure_ascii=False, indent=2)
    f.write('\n')

# Update replacements mapping
with open('scripts/replacements.json', 'r', encoding='utf-8') as f:
    replacements = json.load(f)

new_replacements = {}
for old_key, value in replacements.items():
    if old_key in key_map:
        new_replacements[value] = key_map[old_key]
    else:
        new_key = normalize_key(old_key)
        new_replacements[value] = new_key

with open('scripts/replacements.json', 'w', encoding='utf-8') as f:
    json.dump(new_replacements, f, ensure_ascii=False, indent=2)

print(f"Normalized {len(key_map)} keys")
print("Sample mappings:")
for i, (old, new) in enumerate(list(key_map.items())[:20]):
    print(f"  {old} -> {new}")
