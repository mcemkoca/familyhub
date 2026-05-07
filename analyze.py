
import os, re

lib_dir = r'c:\Temp\familyhub\lib'
out_path = r'c:\Temp\familyhub\analysis_output.txt'

findings = []

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
            analyze_file(path, lines)

    with open(out_path, 'w', encoding='utf-8') as out:
        for cat, path, line_no, snippet, sev in findings:
            out.write(f'{cat}|{path}|{line_no}|{snippet}|{sev}\n')

def analyze_file(path, lines):
    # Patterns 1-4
    for i, line in enumerate(lines):
        l = line.strip()
        if re.search(r'catch\s*\(\s*e\s*\)\s*\{\s*\}', l):
            findings.append(('Empty catch block', path, i+1, l, 'HIGH'))
        if re.search(r'catch\s*\(\s*_\s*\)\s*\{\s*\}', l):
            findings.append(('Ignored catch block', path, i+1, l, 'HIGH'))
        if re.search(r'catch\s*\([^)]*\)\s*\{\s*debugPrint\s*\(', l):
            findings.append(('Log-only catch block', path, i+1, l, 'MEDIUM'))
        if re.search(r'catch\s*\([^)]*\)\s*\{\s*return\s+[^;]*;\s*\}', l):
            findings.append(('Silent return catch block', path, i+1, l, 'MEDIUM'))
    
    # Pattern 7
    for i, line in enumerate(lines):
        l = line.strip()
        if re.search(r'Supabase\.instance\.client', l):
            findings.append(('Direct Supabase.instance.client', path, i+1, l, 'MEDIUM'))
    
    # Patterns 5-6
    for i, line in enumerate(lines):
        if 'await ' not in line:
            continue
        # Determine base indentation of this line
        base_indent = len(line) - len(line.lstrip())
        saw_mounted = False
        for j in range(i+1, min(i+20, len(lines))):
            next_line = lines[j]
            nl_stripped = next_line.strip()
            if not nl_stripped or nl_stripped.startswith('//'):
                continue
            # If we hit a closing brace at same or lower indentation, stop
            if next_line.rstrip().endswith('}') and (len(next_line) - len(next_line.lstrip())) <= base_indent:
                # allow same-indent closing brace? e.g. end of if block
                pass
            # Heuristic: if line starts with } at lower indent, stop
            if next_line.strip().startswith('}') and (len(next_line) - len(next_line.lstrip())) < base_indent:
                break
            if 'await ' in nl_stripped:
                saw_mounted = False
                continue
            if 'mounted' in nl_stripped or 'context.mounted' in nl_stripped:
                saw_mounted = True
                continue
            if 'setState(' in nl_stripped:
                if not saw_mounted:
                    findings.append(('setState after await without mounted check', path, i+1, nl_stripped, 'HIGH'))
                break
            if re.search(r'Navigator\.(pop|push)', nl_stripped):
                if not saw_mounted:
                    findings.append(('Navigator after await without mounted check', path, i+1, nl_stripped, 'HIGH'))
                break
            if re.search(r'context\.push\(', nl_stripped):
                if not saw_mounted:
                    findings.append(('context.push after await without mounted check', path, i+1, nl_stripped, 'HIGH'))
                break
            # Stop scanning at certain control flow lines at same or lower indentation
            indent = len(next_line) - len(next_line.lstrip())
            if indent <= base_indent and re.search(r'^(if\s|else|for\s|while\s|return\s|switch\s|try\s|catch)', nl_stripped):
                break

analyze()
print('done')
