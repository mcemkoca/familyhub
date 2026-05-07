import re
from pathlib import Path

screen_dir = Path('lib/presentation/screens')
fixed = 0

for dart_file in screen_dir.rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    # Fix broken import patterns
    content = re.sub(r"^import\s+package':", r"import 'package:", content, flags=re.MULTILINE)
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
        fixed += 1

print(f"Fixed imports in {fixed} files")
