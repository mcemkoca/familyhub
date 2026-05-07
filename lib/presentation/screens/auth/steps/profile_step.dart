import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/constants.dart';
import '../../../../core/validation/input_validator.dart';

class ProfileStep extends StatefulWidget {
  final Function(Map<String, dynamic> data) onSaved;

  const ProfileStep({super.key, required this.onSaved});

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String _language = 'tr';
  String _theme = 'system';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _save() {
    HapticFeedback.mediumImpact();

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      final error = InputValidator.validatePhone(phone);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    widget.onSaved({
      'phone': phone.isEmpty ? null : phone,
      'date_of_birth': _dateOfBirth?.toIso8601String(),
      'preferred_language': _language,
      'theme_preference': _theme,
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
            'Profil Bilgileri',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kişisel bilgilerinizi ekleyin (isteğe bağlı)',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _phoneController,
            label: 'Telefon Numarası',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hintText: '+90 5xx xxx xx xx',
          ),
          const SizedBox(height: 16),
          _buildDatePicker(isDark),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Tercih Edilen Dil',
            value: _language,
            items: const [
              {'value': 'tr', 'label': 'Türkçe'},
              {'value': 'en', 'label': 'English'},
            ],
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Tema Tercihi',
            value: _theme,
            items: const [
              {'value': 'light', 'label': 'Açık'},
              {'value': 'dark', 'label': 'Karanlık'},
              {'value': 'system', 'label': 'Sistem'},
            ],
            onChanged: (v) => setState(() => _theme = v!),
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

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: isDark ? AppColors.darkTextSecondary : AppColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doğum Tarihi',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Seçilmedi',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
