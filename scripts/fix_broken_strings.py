import re
from pathlib import Path

screen_dir = Path('lib/presentation/screens')
fixed = 0

for dart_file in screen_dir.rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Fix Text('X'Y) -> Text('X Y')
    content = re.sub(
        r"Text\('([^']+)'([A-Za-zğüşıöçĞÜŞİÖÇ][A-Za-zğüşıöçĞÜŞİÖÇ0-9_]*)\)",
        r"Text('\1 \2')",
        content
    )
    
    # Fix const Text('X'Y) -> const Text('X Y')
    content = re.sub(
        r"const Text\('([^']+)'([A-Za-zğüşıöçĞÜŞİÖÇ][A-Za-zğüşıöçĞÜŞİÖÇ0-9_]*)\)",
        r"const Text('\1 \2')",
        content
    )
    
    # Fix 'X'Y -> 'X Y' (standalone string fragments)
    content = re.sub(
        r"'([^']+)'([A-Za-zğüşıöçĞÜŞİÖÇ][A-Za-zğüşıöçĞÜŞİÖÇ0-9_]*)",
        r"'\1 \2'",
        content
    )
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        fixed += 1

print(f"Fixed {fixed} files")
