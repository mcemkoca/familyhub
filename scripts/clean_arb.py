import json
import re
from pathlib import Path

# Load existing clean ARB base
with open('lib/l10n/app_tr.arb', 'r', encoding='utf-8') as f:
    arb = json.load(f)

# Keep only the original manually-curated entries (first 160, identifiable by simple keys)
original_keys = [
    '@@locale', 'appTitle', 'family', 'settings', 'profile', 'logout', 'login', 'register',
    'email', 'password', 'confirmPassword', 'name', 'phone', 'ok', 'cancel', 'save',
    'delete', 'edit', 'add', 'send', 'loading', 'error', 'success', 'retry', 'chat',
    'calendar', 'tasks', 'safety', 'healthCard', 'shopping', 'budget', 'hub',
    'notifications', 'search', 'more', 'back', 'next', 'done', 'close', 'yes', 'no',
    'welcome', 'welcomeSubtitle', 'emailRequired', 'passwordRequired', 'passwordTooShort',
    'invalidEmail', 'loginFailed', 'registerFailed', 'noAccount', 'haveAccount',
    'forgotPassword', 'members', 'online', 'admin', 'child', 'parent', 'role',
    'removeMember', 'roleChangeSuccess', 'removeConfirm', 'leaveFamilyConfirm',
    'typeMessage', 'image', 'location', 'event', 'poll', 'voiceMessage', 'today',
    'yesterday', 'noEvents', 'addEvent', 'eventTitle', 'startTime', 'endTime',
    'allDay', 'reminder', 'category', 'description', 'taskTitle', 'dueDate',
    'priority', 'high', 'medium', 'low', 'completed', 'pending', 'emergency',
    'emergencyButton', 'emergencyInfo', 'emergencySent', 'call112', 'healthInfo',
    'bloodType', 'allergies', 'medications', 'chronicConditions', 'emergencyContact',
    'doctor', 'organDonor', 'notes', 'qrShare', 'privacyNote', 'language', 'turkish',
    'english', 'theme', 'light', 'dark', 'system', 'fontSize', 'small', 'normal',
    'large', 'premium', 'upgradeToPremium', 'premiumFeatures', 'subscriptionActive',
    'subscriptionExpired', 'noInternet', 'sessionExpired', 'serverError', 'tryAgain',
    'pullToRefresh', 'noData', 'select', 'camera', 'gallery', 'file', 'cancelled',
    'permissionDenied', 'locationPermission', 'locationUnavailable', 'invitationSent',
    'invitationCode', 'copy', 'share', 'copied', 'memberCount', 'childCount',
    'onlineCount', 'adminCount', 'pinnedMessage', 'messageDeleted', 'reactionAdded',
    'callStarted', 'callEnded', 'missedCall', 'incomingCall', 'newMessage',
    'markAsRead', 'markAllRead', 'deleteAll', 'archive', 'unarchive', 'active',
    'inactive', 'unknown', 'notSet', 'optional'
]

clean_arb = {k: arb[k] for k in original_keys if k in arb}

# Load extracted strings
with open('scripts/extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

def normalize_key(key):
    mapping = {
        'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
        'Ç': 'C', 'Ğ': 'G', 'İ': 'I', 'Ö': 'O', 'Ş': 'S', 'Ü': 'U'
    }
    for tr, asc in mapping.items():
        key = key.replace(tr, asc)
    key = re.sub(r'[^a-zA-Z0-9_]', '', key)
    key = re.sub(r'^[0-9_]+', '', key)
    if '_' in key:
        parts = key.split('_')
        key = parts[0].lower() + ''.join(p.capitalize() for p in parts[1:] if p)
    else:
        key = key[0].lower() + key[1:] if key else 'key'
    if not key:
        key = 'key'
    return key

# Filter UI-safe strings
added = 0
for old_key, value in extracted.items():
    # Skip interpolation, methods, newlines, too long, etc.
    if '${' in value:
        continue
    if re.search(r'\$[a-zA-Z_][a-zA-Z0-9_]*', value):
        continue
    if '\n' in value:
        continue
    if '(' in value or ')' in value:
        continue
    if '[' in value or ']' in value:
        continue
    if '{' in value or '}' in value:
        continue
    if len(value) > 80:
        continue
    if value in clean_arb.values():
        continue
    
    new_key = normalize_key(old_key)
    base = new_key
    counter = 1
    while new_key in clean_arb:
        new_key = f"{base}{counter}"
        counter += 1
    clean_arb[new_key] = value
    added += 1

with open('lib/l10n/app_tr.arb', 'w', encoding='utf-8') as f:
    json.dump(clean_arb, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f"Clean ARB: {len(clean_arb)} entries ({added} new)")
