import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/health_card_service.dart';
import '../../widgets/settings/screen_header.dart';
import '../../widgets/settings/settings_section.dart';
import 'package:go_router/go_router.dart';

class HealthCardEditScreen extends StatefulWidget {
  const HealthCardEditScreen({super.key});

  @override
  State<HealthCardEditScreen> createState() => _HealthCardEditScreenState();
}

class _HealthCardEditScreenState extends State<HealthCardEditScreen> {
  bool _isLoading = true;
  bool _saving = false;

  String? _bloodType;
  final _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _organDonor = false;

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _doctorHospitalController = TextEditingController();

  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await HealthCardService.load();
      if (data != null) {
        _bloodType = data.bloodType.isNotEmpty ? data.bloodType : null;
        _allergiesController.text = data.allergies.join(', ');
        _conditionsController.text = data.chronicConditions.join(', ');
        _medicationsController.text = data.medications
            .map((m) {
              if (m.dosage.isNotEmpty) {
                return '${m.name} (${m.dosage})';
              }
              return m.name;
            })
            .join(', ');
        _organDonor = data.organDonor;
        _emergencyNameController.text = data.emergencyContactName;
        _emergencyPhoneController.text = data.emergencyContactPhone;
        _emergencyRelationController.text = data.emergencyContactRelation;
        _doctorNameController.text = data.doctorName;
        _doctorPhoneController.text = data.doctorPhone;
        _doctorHospitalController.text = data.doctorHospital;
        _notesController.text = data.notes;
      }
    } catch (e) {
      debugPrint('Health card load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    setState(() => _saving = true);

    try {
      final allergies = _allergiesController.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final conditions = _conditionsController.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final medications = _medicationsController.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) {
            // Try to parse "Name (Dosage)" format
            final match = RegExp(r'^(.+?)\s*\(([^)]+)\)\s*$').firstMatch(e);
            if (match != null) {
              return Medication(
                name: match.group(1)!.trim(),
                dosage: match.group(2)!.trim(),
                frequency: '',
              );
            }
            return Medication(name: e, dosage: '', frequency: '');
          })
          .toList();

      final data = HealthCardData(
        bloodType: _bloodType ?? '',
        allergies: allergies,
        medications: medications,
        chronicConditions: conditions,
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        emergencyContactRelation: _emergencyRelationController.text.trim(),
        doctorName: _doctorNameController.text.trim(),
        doctorPhone: _doctorPhoneController.text.trim(),
        doctorHospital: _doctorHospitalController.text.trim(),
        organDonor: _organDonor,
        notes: _notesController.text.trim(),
      );

      await HealthCardService.save(data);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sağlık kartı güncellendi')),
        );
        if (context.mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _doctorHospitalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: ScreenHeader(
          title: 'Sağlık Kartını Düzenle',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Sağlık Kartını Düzenle',
        showBack: true,
        onBack: () => context.pop(),
        rightAction: TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cobalt,
                  ),
                )
              : Text(
                  'Kaydet',
                  style: TextStyle(
                    color: AppColors.cobalt,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sağlık Bilgileri
                  SettingsSection(
                    title: 'SAĞLIK BİLGİLERİ',
                    icon: Icons.health_and_safety_outlined,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kan Grubu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _bloodTypes.map((type) {
                                final selected = _bloodType == type;
                                return ChoiceChip(
                                  label: Text(type),
                                  selected: selected,
                                  selectedColor: AppColors.error,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.dark),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _bloodType = type),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      _buildInput(
                        label: 'Alerjiler',
                        controller: _allergiesController,
                        hint: 'Örn: yer fıstığı, polen, antibiyotik',
                        icon: Icons.healing_outlined,
                      ),
                      _buildInput(
                        label: 'Kronik Hastalıklar',
                        controller: _conditionsController,
                        hint: 'Örn: astım, diyabet, hipertansiyon',
                        icon: Icons.medical_services_outlined,
                      ),
                      _buildInput(
                        label: 'İlaçlar',
                        controller: _medicationsController,
                        hint: 'Örn: Aspirin (100mg), Metformin (500mg)',
                        icon: Icons.medication_outlined,
                      ),
                      _buildSwitch(
                        label: 'Organ Bağışçısı',
                        value: _organDonor,
                        onChanged: (v) => setState(() => _organDonor = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Acil Durum Kişisi
                  SettingsSection(
                    title: 'ACİL DURUM KİŞİSİ',
                    icon: Icons.emergency_outlined,
                    children: [
                      _buildInput(
                        label: 'Ad Soyad',
                        controller: _emergencyNameController,
                        icon: Icons.person_outline,
                      ),
                      _buildInput(
                        label: 'Telefon',
                        controller: _emergencyPhoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildInput(
                        label: 'Yakınlık Derecesi',
                        controller: _emergencyRelationController,
                        hint: 'Örn: Eş, Anne, Baba, Kardeş',
                        icon: Icons.people_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Doktor Bilgileri
                  SettingsSection(
                    title: 'DOKTOR BİLGİLERİ',
                    icon: Icons.local_hospital_outlined,
                    children: [
                      _buildInput(
                        label: 'Doktor Adı',
                        controller: _doctorNameController,
                        icon: Icons.person_outline,
                      ),
                      _buildInput(
                        label: 'Telefon',
                        controller: _doctorPhoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildInput(
                        label: 'Hastane / Klinik',
                        controller: _doctorHospitalController,
                        icon: Icons.local_hospital_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Ek Notlar
                  SettingsSection(
                    title: 'EK NOTLAR',
                    icon: Icons.notes_outlined,
                    children: [
                      _buildInput(
                        label: 'Notlar',
                        controller: _notesController,
                        hint: 'Eklemek istediğiniz sağlık notları...',
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightGray,
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.error,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
