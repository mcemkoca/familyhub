#!/usr/bin/env python3
"""Split budget_screen.dart into smaller widget files."""

import os
import re

with open('lib/presentation/screens/budget/budget_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find all class start lines
class_starts = []
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith('class '):
        class_starts.append(i)

output_dir = 'lib/presentation/screens/budget/widgets'
os.makedirs(output_dir, exist_ok=True)

for i, start in enumerate(class_starts):
    end = class_starts[i+1] if i+1 < len(class_starts) else len(lines)
    class_lines = lines[start:end]
    class_name = class_lines[0].strip().split(' ')[1].split('(')[0].split(' ')[0]
    
    # Skip BudgetScreen itself - keep it in original file
    if class_name == 'BudgetScreen':
        continue
    
    # Determine file name
    if class_name == '_Cat':
        file_name = 'budget_models.dart'
    else:
        clean_name = class_name.lstrip('_')
        file_name = 'budget_' + re.sub(r'(?<!^)(?=[A-Z])', '_', clean_name).lower() + '.dart'
    
    file_path = os.path.join(output_dir, file_name)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write("import 'package:flutter/material.dart';\n")
        f.write("import 'package:flutter_riverpod/flutter_riverpod.dart';\n")
        f.write("import 'package:fl_chart/fl_chart.dart';\n")
        f.write("import 'package:intl/intl.dart';\n")
        f.write("import '../../../../config/constants.dart';\n")
        f.write("import '../../../../domain/entities.dart';\n")
        f.write("import '../../../../l10n/app_localizations.dart';\n")
        f.write("import '../../../providers/app_providers.dart';\n")
        f.write("import 'package:familyhub/l10n/app_localizations.dart';\n")
        f.write('\n')
        f.writelines(class_lines)
    
    print(f'Created {file_path} ({end-start} lines)')

print('Done!')
