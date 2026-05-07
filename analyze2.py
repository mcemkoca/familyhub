
import os, re

lib_dir = r'c:\Temp\familyhub\lib'
out_path = r'c:\Temp\familyhub\analysis_output2.txt'

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
            analyze_catch_blocks(path, lines)
            analyze_supabase(path, lines)
            analyze_await_patterns(path, lines)

def analyze_catch_blocks(path, lines):
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        if re.search(r'\bcatch\s*\(', line):
            # find opening brace
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
            # Find matching closing brace
            # Simple brace counting from j
            brace_depth = 0
            k = j
            block_start = k
            while k < n:
                brace_depth += lines[k].count('{')
                brace_depth -= lines[k].count('}')
                if brace_depth == 0 and '}' in lines[k]:
                    break
                k += 1
            block_end = k
            # Extract block content (excluding first and last line braces)
            content_lines = []
            for idx in range(block_start+1, block_end):
                stripped = lines[idx].strip()
                if stripped and not stripped.startswith('//'):
                    content_lines.append(stripped)
            
            # Single line block?
            if block_start == block_end:
                # e.g. catch (_) {}
                single = lines[block_start].strip()
                add('Ignored/Empty catch block', path, i+1, single, 'HIGH')
                i = block_end + 1
                continue
            
            if not content_lines:
                add('Empty catch block', path, i+1, lines[i].strip(), 'HIGH')
            elif all(l.startswith('debugPrint') for l in content_lines):
                add('Log-only catch block', path, i+1, lines[i].strip(), 'MEDIUM')
            elif len(content_lines) == 1 and content_lines[0].startswith('return '):
                add('Silent return catch block', path, i+1, lines[i].strip(), 'MEDIUM')
            elif len(content_lines) == 1 and re.search(r'^return\s+[^;]+;?$', content_lines[0]):
                add('Silent return catch block', path, i+1, lines[i].strip(), 'MEDIUM')
            i = block_end + 1
            continue
        i += 1

def analyze_supabase(path, lines):
    for i, line in enumerate(lines):
        if re.search(r'Supabase\.instance\.client', line):
            # Exclude the wrapper itself if it's returning safeClient
            if 'core\supabase_client.dart' in path:
                continue
            add('Direct Supabase.instance.client', path, i+1, line.strip(), 'MEDIUM')

def analyze_await_patterns(path, lines):
    n = len(lines)
    brace_depth = 0
    await_active = False
    await_depth = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        # Update brace depth for this line
        opens = line.count('{')
        closes = line.count('}')
        # Heuristic: if line has 'await' and is not a comment
        if 'await ' in stripped and not stripped.startswith('//'):
            await_active = True
            await_depth = brace_depth + opens  # depth after this line's braces open
        
        if await_active:
            if 'mounted' in stripped or 'context.mounted' in stripped:
                await_active = False
            if re.search(r'\bsetState\s*\(', stripped):
                add('setState after await without mounted check', path, i+1, stripped, 'HIGH')
                await_active = False
            if re.search(r'Navigator\.(pop|push)', stripped):
                add('Navigator after await without mounted check', path, i+1, stripped, 'HIGH')
                await_active = False
            if re.search(r'context\.push\(', stripped):
                add('context.push after await without mounted check', path, i+1, stripped, 'HIGH')
                await_active = False
            if stripped.startswith('return '):
                await_active = False
            if 'await ' in stripped:
                # new await, reset
                await_depth = brace_depth + opens
            if closes > opens and (brace_depth - (closes - opens)) < await_depth:
                await_active = False
        
        brace_depth += opens - closes
        if brace_depth < 0:
            brace_depth = 0

analyze()

with open(out_path, 'w', encoding='utf-8') as out:
    for cat, path, line_no, snippet, sev in findings:
        out.write(f'{cat}|{path}|{line_no}|{snippet}|{sev}\n')
print('done')
