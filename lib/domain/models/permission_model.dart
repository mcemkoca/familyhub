class PermissionModel {
  final String role; // 'admin' | 'member' | 'child'
  final Map<String, bool> permissions;

  PermissionModel({required this.role, required this.permissions});

  static final Map<String, Map<String, bool>> defaultPermissions = {
    'admin': {
      'manage_members': true,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': true,
      'delete_content': true,
    },
    'member': {
      'manage_members': false,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': false,
      'delete_content': false,
    },
    'parent': {
      'manage_members': false,
      'edit_settings': true,
      'view_finance': true,
      'manage_backups': false,
      'delete_content': false,
    },
    'child': {
      'manage_members': false,
      'edit_settings': false,
      'view_finance': false,
      'manage_backups': false,
      'delete_content': false,
    },
  };

  static Map<String, bool> forRole(String role) {
    return Map<String, bool>.from(defaultPermissions[role] ?? defaultPermissions['member']!);
  }
}
