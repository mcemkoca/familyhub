import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../../config/constants.dart';

class ParentRoleStep extends StatefulWidget {
  final Function(Map<String, dynamic> data) onSaved;

  const ParentRoleStep({super.key, required this.onSaved});

  @override
  State<ParentRoleStep> createState() => _ParentRoleStepState();
}

class _ParentRoleStepState extends State<ParentRoleStep> {
  String _role = 'admin';
  final _displayNameController = TextEditingController();
  Color _selectedColor = const Color(0xFF6366F1);

  final _colors = [
    {'color': const Color(0xFF6366F1), 'name': 'blue', 'hex': '2563EB'},
    {'color': AppColors.green, 'name': 'green', 'hex': '10B981'},
    {'color': AppColors.orange, 'name': 'orange', 'hex': 'F97316'},
    {'color': const Color(0xFF8B5CF6), 'name': 'purple', 'hex': '8B5CF6'},
    {'color': AppColors.red, 'name': 'red', 'hex': 'EF4444'},
    {'color': const Color(0xFFEC4899), 'name': 'pink', 'hex': 'EC4899'},
  ];

  String _colorName(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    switch (key) {
      case 'blue':
        return l.colorBlue;
      case 'green':
        return l.colorGreen;
      case 'orange':
        return l.colorOrange;
      case 'purple':
        return l.colorPurple;
      case 'red':
        return l.colorRed;
      case 'pink':
        return l.colorPink;
      default:
        return key;
    }
  }

  void _save() {
    HapticFeedback.mediumImpact();
    widget.onSaved({
      'role': _role,
      'display_name': _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
      'color': '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}',
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).aileRolu,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).ailedekiRolunuzuVeGorunumunuzuSecin,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).rolunuz,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RoleChip(
                  label: AppLocalizations.of(context).admin,
                  icon: Icons.admin_panel_settings,
                  selected: _role == 'admin',
                  onTap: () => setState(() => _role = 'admin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleChip(
                  label: AppLocalizations.of(context).roleParent,
                  icon: Icons.people,
                  selected: _role == 'parent',
                  onTap: () => setState(() => _role = 'parent'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).ailedeGorunenAdiniz,
              hintText: AppLocalizations.of(context).ornAnneBabaMehmet,
              prefixIcon: const Icon(Icons.badge_outlined),
              filled: true,
              fillColor: const Color(0xFF13131A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).renkSecimi,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors.map((c) {
              final color = c['color'] as Color;
              final selected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(80),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _colorName(context, c['name'] as String),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).next,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6366F1).withAlpha(30)
              : (const Color(0xFF13131A)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF6366F1)
                  : (const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? const Color(0xFF6366F1)
                    : (const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
