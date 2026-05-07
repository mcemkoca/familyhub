import os, re

lib_dir = r'c:\Temp\familyhub\lib'
out_path = r'c:\Temp\familyhub\analysis_output4.txt'

findings = []

def add(cat, path, line_no, snippet, sev):
    findings.append((cat, path, line_no, snippet.strip(), sev))

def analyze():
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if not f.endswith('.dart'):
                continue
            path = os.path.join(root, f)
            try:
                with open(path, 'r', encoding='utf-8') as fh:
                    lines = fh.readlines()
            except Exception:
                continue
            lines = [l.rstrip('\n') for l in lines]
            analyze_catch(path, lines)
            analyze_supabase(path, lines)
            analyze_await(path, lines)

def analyze_catch(path, lines):
    n = len(lines)
    i = 0
    while i < n:
        if re.search(r'\bcatch\s*\(', lines[i]):
            j = i
            brace_found = False
            while j < n:
                if '{' in lines[j]:
                    brace_found = True
                    break
                j += 1
            if not brace_found:
                i += 1
                continue
            brace_depth = 1  # we are inside the opening brace
            k = j + 1
            while k < n:
                brace_depth += lines[k].count('{')
                brace_depth -= lines[k].count('}')
                if brace_depth <= 0:
                    break
                k += 1
            content = []
            for idx in range(j+1, k):
                s = lines[idx].strip()
                if s and not s.startswith('//'):
                    content.append(s)
            header = lines[i].strip()
            if not content:
                add('Empty catch block', path, i+1, header, 'HIGH')
            elif len(content) == 1:
                c = content[0]
                if c.startswith('debugPrint') and not re.search(r'\bthrow\b', c):
                    add('Log-only catch block', path, i+1, header + ' -> ' + c, 'MEDIUM')
                elif re.search(r'^return\s+(\[\]|null|false|0)', c):
                    add('Silent return catch block', path, i+1, header + ' -> ' + c, 'MEDIUM')
            i = k + 1
            continue
        i += 1

def analyze_supabase(path, lines):
    for i, line in enumerate(lines):
        if re.search(r'Supabase\.instance\.client', line):
            if 'supabase_client.dart' in path:
                continue
            add('Direct Supabase.instance.client', path, i+1, line.strip(), 'MEDIUM')

def analyze_await(path, lines):
    n = len(lines)
    brace_depth = 0
    awaits = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        opens = line.count('{')
        closes = line.count('}')
        
        if 'await ' in stripped and not stripped.startswith('//'):
            awaits.append(brace_depth + opens)
        
        if awaits:
            if 'mounted' in stripped or 'context.mounted' in stripped:
                awaits.clear()
            elif re.search(r'\bsetState\s*\(', stripped) and not stripped.startswith('//'):
                if 'await ' not in stripped:
                    add('setState after await without mounted check', path, i+1, stripped, 'HIGH')
                awaits.clear()
            elif re.search(r'Navigator\.(pop|push)', stripped) and 'await ' not in stripped:
                add('Navigator after await without mounted check', path, i+1, stripped, 'HIGH')
                awaits.clear()
            elif re.search(r'context\.push\(', stripped) and 'await ' not in stripped:
                add('context.push after await without mounted check', path, i+1, stripped, 'HIGH')
                awaits.clear()
            elif stripped.startswith('return '):
                awaits.clear()
        
        if closes > 0 and awaits:
            new_depth = brace_depth + opens - closes
            awaits = [d for d in awaits if d <= new_depth]
        
        brace_depth += opens - closes
        if brace_depth < 0:
            brace_depth = 0

analyze()

with open(out_path, 'w', encoding='utf-8') as out:
    for cat, path, line_no, snippet, sev in findings:
        out.write(f'{cat}|{path}|{line_no}|{snippet}|{sev}\n')
print('done')
