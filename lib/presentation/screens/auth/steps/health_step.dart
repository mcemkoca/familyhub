import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class HealthStep extends StatefulWidget {
  final Function(Map<String, dynamic> data) onSaved;
  final bool isLoading;

  const HealthStep({super.key, required this.onSaved, this.isLoading = false});

  @override
  State<HealthStep> createState() => _HealthStepState();
}

class _HealthStepState extends State<HealthStep> {
  String? _bloodType;
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  final _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-',
  ];

  void _save() {
    HapticFeedback.mediumImpact();

    final allergies = _allergiesController.text.trim().isEmpty
        ? null
        : _allergiesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final conditions = _conditionsController.text.trim().isEmpty
        ? null
        : _conditionsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    widget.onSaved({
      'blood_type': _bloodType,
      'allergies': allergies,
      'chronic_conditions': conditions,
      'emergency_contact': _emergencyNameController.text.trim().isEmpty
          ? null
          : {
              'name': _emergencyNameController.text.trim(),
              'phone': _emergencyPhoneController.text.trim(),
              'relation': _emergencyRelationController.text.trim(),
            },
    });
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).healthInfo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acil durumlar için sağlık bilgilerinizi ekleyin (isteğe bağlı)',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kan Grubu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodTypes.map((type) {
              final selected = _bloodType == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                selectedColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : (const Color(0xFFE5E7EB)),
                ),
                onSelected: (_) => setState(() => _bloodType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _allergiesController,
            label: 'Alerjiler',
            icon: Icons.healing_outlined,
            hintText: 'Örn: yer fıstığı, polen, antibiyotik (virgülle ayırın)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _conditionsController,
            label: AppLocalizations.of(context).chronicConditions,
            icon: Icons.medical_services_outlined,
            hintText: 'Örn: astım, diyabet (virgülle ayırın)',
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).acilDurumdaAranacakKisi,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emergencyNameController,
            label: 'Ad Soyad',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emergencyPhoneController,
            label: 'Telefon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emergencyRelationController,
            label: AppLocalizations.of(context).yakinlikDerecesi,
            icon: Icons.people_outline,
            hintText: AppLocalizations.of(context).ornEsAnneBaba,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Tamamla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFF13131A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
