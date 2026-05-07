import re
from pathlib import Path

for dart_file in Path('lib/presentation/screens').rglob('*.dart'):
    content = dart_file.read_text(encoding='utf-8')
    original = content
    
    def fix_const_line(match):
        line = match.group(0)
        # Only remove the first occurrence of 'const ' on this line
        return line.replace('const ', '', 1)
    
    # Match lines containing both 'const ' and 'AppLocalizations'
    content = re.sub(r'^.*const .*AppLocalizations.*$', fix_const_line, content, flags=re.MULTILINE)
    
    if content != original:
        dart_file.write_text(content, encoding='utf-8')
