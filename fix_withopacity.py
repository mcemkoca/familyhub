import re
import os

def replace_with_opacity(content):
    pattern = r'\.withOpacity\(([0-9.]+)\)'
    def replacer(match):
        val = float(match.group(1))
        alpha = max(0, min(255, round(val * 255)))
        return f'.withAlpha({alpha})'
    return re.sub(pattern, replacer, content)

changed = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            new_content = replace_with_opacity(content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                changed += 1
print('Changed files: ' + str(changed))
