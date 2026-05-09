#!/usr/bin/env python3
"""Fix budget_screen.dart to use part/part_of for extracted widgets."""

import os

# Files to add as parts
part_files = [
    "widgets/budget_summary_card.dart",
    "widgets/budget_monthly_progress_card.dart",
    "widgets/budget_a_i_analysis_card.dart",
    "widgets/budget_trend_chart.dart",
    "widgets/budget_category_budget_section.dart",
    "widgets/budget_transaction_tile.dart",
    "widgets/budget_picker_button.dart",
    "widgets/budget_a_i_stat_row.dart",
    "widgets/budget_models.dart",
]

# Read original budget_screen.dart
with open('lib/presentation/screens/budget/budget_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find class start lines
class_starts = []
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith('class '):
        class_starts.append(i)

# Keep BudgetScreen and _BudgetScreenState (first two classes)
# Remove all other classes from the file
end_of_state = class_starts[2] if len(class_starts) > 2 else len(lines)
new_lines = lines[:end_of_state]

# Add part directives at the end
new_lines.append('\n')
for pf in part_files:
    new_lines.append(f"part '{pf}';\n")

# Write back
with open('lib/presentation/screens/budget/budget_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"Updated budget_screen.dart ({len(new_lines)} lines)")

# Add part_of to each widget file
for pf in part_files:
    filepath = f'lib/presentation/screens/budget/{pf}'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove all import lines (they will be inherited from budget_screen.dart)
    # Actually, part files can have their own imports in Dart
    # So we keep imports but add part_of at the top
    
    # Add part_of directive at the very top
    part_of = "part of '../budget_screen.dart';\n\n"
    if not content.startswith("part of"):
        content = part_of + content
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Updated {filepath}")

print("Done!")
