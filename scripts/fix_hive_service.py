#!/usr/bin/env python3
"""Fix strict-casts issues in hive_service.dart by adding explicit casts."""

import re

KEY_TYPES = {
    # Strings
    'id': 'String', 'title': 'String', 'name': 'String', 'description': 'String?',
    'category': 'String', 'currency': 'String', 'content': 'String',
    'senderId': 'String', 'senderName': 'String', 'imageUrl': 'String?',
    'audioUrl': 'String?', 'replyToId': 'String?', 'replyToContent': 'String?',
    'replyToSender': 'String?', 'assignedTo': 'String', 'createdBy': 'String',
    'email': 'String', 'phone': 'String?', 'avatarUrl': 'String?',
    'familyId': 'String', 'role': 'String', 'bloodType': 'String?',
    'allergies': 'String?', 'medications': 'String?', 'conditions': 'String?',
    'emergencyContact': 'String?', 'doctor': 'String?', 'notes': 'String?',
    'code': 'String', 'city': 'String?', 'country': 'String',
    'unit': 'String', 'icon': 'String?', 'label': 'String',
    'value': 'String', 'question': 'String', 'answer': 'String',
    # Ints
    'streakCount': 'int', 'priority': 'int', 'type': 'int',
    'readCount': 'int', 'status': 'int', 'fontScale': 'int',
    'index': 'int', 'color': 'int', 'senderColor': 'int',
    # Doubles
    'amount': 'double', 'budgetLimit': 'double?',
    # Bools
    'isRead': 'bool', 'isPinned': 'bool', 'isAdmin': 'bool',
    'isPremium': 'bool', 'isOnline': 'bool', 'isChild': 'bool',
    'isActive': 'bool', 'isDarkMode': 'bool', 'notificationsEnabled': 'bool',
    # Lists
    'tags': 'List', 'attachments': 'List', 'reactions': 'List',
    'members': 'List', 'children': 'List', 'tasks': 'List',
}

def fix_line(line: str) -> str:
    """Add explicit casts to Map accesses in a line."""
    # Pattern: var['key'] used as a typed argument
    # Match simple accesses like t['id'], m['title']
    
    # Fix List<String>.from(t['tags']) -> List<String>.from(t['tags'] as List)
    line = re.sub(
        r"List<String>\.from\((\w+)\['(\w+)'\]\)",
        r"List<String>.from(\1['\2'] as List<dynamic>)",
        line
    )
    
    # Fix List<dynamic>.from(...) -> List<dynamic>.from(... as List)
    line = re.sub(
        r"List<dynamic>\.from\((\w+)\['(\w+)'\]\)",
        r"List<dynamic>.from(\1['\2'] as List<dynamic>)",
        line
    )
    
    # Fix DateTime.parse(t['key']) -> DateTime.parse(t['key'] as String)
    line = re.sub(
        r"DateTime\.parse\((\w+)\['(\w+)'\]\)",
        r"DateTime.parse(\1['\2'] as String)",
        line
    )
    
    # Fix Color(m['senderColor']) -> Color(m['senderColor'] as int)
    line = re.sub(
        r"Color\((\w+)\['(\w+)'\]\)",
        r"Color(\1['\2'] as int)",
        line
    )
    
    # Fix generic map accesses: t['key'] -> t['key'] as Type
    def replace_access(match):
        var = match.group(1)
        key = match.group(2)
        typ = KEY_TYPES.get(key)
        if typ and typ != 'List':
            return f"{var}['{key}'] as {typ}"
        return match.group(0)
    
    # Only replace if it's used as a parameter (after colon or comma or in parens)
    # Pattern: word['key'] where it's likely a typed argument
    line = re.sub(r"(\w+)\['(\w+)'\]", replace_access, line)
    
    return line

def main():
    with open('lib/services/hive_service.dart', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed_count = 0
    new_lines = []
    for line in lines:
        new_line = fix_line(line)
        if new_line != line:
            fixed_count += 1
        new_lines.append(new_line)
    
    with open('lib/services/hive_service.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"Fixed {fixed_count} lines in hive_service.dart")

if __name__ == "__main__":
    main()
