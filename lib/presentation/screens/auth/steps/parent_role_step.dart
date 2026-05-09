import 'package:flutter/material.dart';
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
  Color _selectedColor = AppColors.cobalt;

  final _colors = [
    {'color': AppColors.cobalt, 'name': 'Mavi', 'hex': '2563EB'},
    {'color': AppColors.green, 'name': 'Yeşil', 'hex': '10B981'},
    {'color': AppColors.orange, 'name': 'Turuncu', 'hex': 'F97316'},
    {'color': AppColors.purple, 'name': 'Mor', 'hex': '8B5CF6'},
    {'color': AppColors.red, 'name': 'Kırmızı', 'hex': 'EF4444'},
    {'color': AppColors.pink, 'name': 'Pembe', 'hex': 'EC4899'},
  ];

  void _save() {
    HapticFeedback.mediumImpact();
    widget.onSaved({
      'role': _role,
      'display_name': _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aile Rolü',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ailedeki rolünüzü ve görünümünüzü seçin',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rolünüz',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RoleChip(
                  label: 'Yönetici',
                  icon: Icons.admin_panel_settings,
                  selected: _role == 'admin',
                  onTap: () => setState(() => _role = 'admin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleChip(
                  label: 'Ebeveyn',
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
              labelText: 'Ailede Görünen Adınız',
              hintText: 'Örn: Anne, Baba, Mehmet',
              prefixIcon: const Icon(Icons.badge_outlined),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Renk Seçimi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
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
                            ? [BoxShadow(color: color.withAlpha(80), blurRadius: 12)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['name'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
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
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('İleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cobalt.withAlpha(isDark ? 30 : 15)
              : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.cobalt : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.cobalt : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.cobalt : (isDark ? AppColors.darkTextSecondary : AppColors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
