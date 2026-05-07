import json
import re
from pathlib import Path

# Load existing ARB
with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    existing_arb = json.load(f)

existing_values = {v: k for k, v in existing_arb.items() if not k.startswith('@')}

# Load extracted strings
with open('scripts/extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

# Build merge: use existing keys when values match
value_to_key = dict(existing_values)
new_arb = dict(existing_arb)
replacements = {}  # value -> key

for key, value in extracted.items():
    if value in value_to_key:
        replacements[value] = value_to_key[value]
    else:
        # Avoid key collision
        final_key = key
        counter = 1
        while final_key in new_arb:
            final_key = f"{key}_{counter}"
            counter += 1
        new_arb[final_key] = value
        value_to_key[value] = final_key
        replacements[value] = final_key

# Save merged ARB
with open('lib/l10n/app_tr.arb', 'w', encoding='utf-8') as f:
    json.dump(new_arb, f, ensure_ascii=False, indent=2)
    f.write('\n')

# Save replacements mapping
with open('scripts/replacements.json', 'w', encoding='utf-8') as f:
    json.dump(replacements, f, ensure_ascii=False, indent=2)

print(f"ARB updated: {len(existing_arb)} -> {len(new_arb)} entries")
print(f"Replacements prepared: {len(replacements)}")
