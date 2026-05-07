import json

DART_KEYWORDS = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield'
}

with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

new_arb = {}
for key, value in arb.items():
    if key in DART_KEYWORDS:
        new_key = f"{key}Label"
        print(f"Renamed: {key} -> {new_key}")
    else:
        new_key = key
    new_arb[new_key] = value

with open('lib/l10n/app_tr.arb', 'w', encoding='utf-8') as f:
    json.dump(new_arb, f, ensure_ascii=False, indent=2)
    f.write('\n')

print("Done")
