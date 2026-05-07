import re
import json
from pathlib import Path
from collections import defaultdict

def extract_turkish_strings(file_path):
    """Extract string literals containing Turkish characters."""
    content = file_path.read_text(encoding='utf-8')
    
    # Match single and double quoted strings
    pattern = r"'([^'\n]*[çğıöşüÇĞİÖŞÜ][^'\n]*)'|\"([^\"\n]*[çğıöşüÇĞİÖŞÜ][^\"\n]*)\""
    matches = re.findall(pattern, content)
    
    results = []
    for m in matches:
        s = m[0] if m[0] else m[1]
        # Skip obvious non-UI strings
        if s.startswith('assets/'): continue
        if s.startswith('lib/'): continue
        if s.startswith('/'): continue  # routes
        if re.match(r'^[a-z]+:', s): continue  # uri schemes like tel:, sms:
        if len(s) < 2: continue
        results.append(s)
    return results

def to_camel_case(s):
    """Convert a Turkish string to camelCase key."""
    # Remove punctuation, keep Turkish chars
    s = re.sub(r"[^\w\sçğıöşüÇĞİÖŞÜ]", "", s)
    words = s.split()
    if not words:
        return ""
    key = words[0].lower()
    for w in words[1:]:
        key += w.capitalize()
    return key

# Collect all strings
all_strings = defaultdict(list)
screen_dir = Path('lib/presentation/screens')
for dart_file in screen_dir.rglob('*.dart'):
    strings = extract_turkish_strings(dart_file)
    for s in strings:
        all_strings[s].append(str(dart_file))

# Output unique strings sorted by frequency
unique = sorted(all_strings.items(), key=lambda x: -len(x[1]))

# Generate ARB entries
arb_entries = {}
for s, files in unique:
    key = to_camel_case(s)
    # Ensure uniqueness
    base_key = key
    counter = 1
    while key in arb_entries:
        key = f"{base_key}_{counter}"
        counter += 1
    arb_entries[key] = s

# Write JSON
with open('scripts/extracted_strings.json', 'w', encoding='utf-8') as f:
    json.dump(arb_entries, f, ensure_ascii=False, indent=2)

# Also write as ARB format
arb_output = {"@@locale": "tr"}
arb_output.update(arb_entries)

with open('scripts/extracted_arb.json', 'w', encoding='utf-8') as f:
    json.dump(arb_output, f, ensure_ascii=False, indent=2)

with open('scripts/extracted_summary.txt', 'w', encoding='utf-8') as f:
    f.write(f"Extracted {len(unique)} unique strings\n")
    f.write("Top 50 most frequent:\n")
    for s, files in unique[:50]:
        f.write(f"  ({len(files)}x) {s}\n")
print(f"Extracted {len(unique)} unique strings")
