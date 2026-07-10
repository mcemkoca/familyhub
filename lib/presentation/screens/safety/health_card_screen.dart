import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../services/health_card_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  HealthCardData? _data;
  bool _loading = true;
  bool _showQR = false;
  String? _qrValue;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await HealthCardService.load();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  Future<void> _generateQR() async {
    if (_data == null) return;
    final json = jsonEncode(_data!.toJson());
    setState(() {
      _qrValue = 'FAMILYHUB:HEALTH:$json';
      _showQR = true;
    });
  }

  Future<void> _callEmergencyContact() async {
    if (_data?.emergencyContactPhone == null) return;
    final uri = Uri(scheme: 'tel', path: _data!.emergencyContactPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).healthCard),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context).edit,
            onPressed: () => context.push(AppRoutes.healthCardEdit),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppLocalizations.of(context).acilDurumlardaKullanilabilirBilgiler,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
            const SizedBox(height: 20),
            // Main Health Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.error, Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).saglikKarti,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Acil durumda okutun',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info Rows
                  _InfoRow(
                    label: 'Kan Grubu',
                    value: _data?.bloodType ?? '-',
                    highlight: true,
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _InfoRow(
                    label: 'Alerjiler',
                    value: _data?.allergies.isNotEmpty == true
                        ? _data!.allergies.join(', ')
                        : 'Yok',
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _InfoRow(
                    label: AppLocalizations.of(context).medications,
                    value: _data?.medications.isNotEmpty == true
                        ? _data!.medications
                            .map((m) => '${m.name} ${m.dosage}')
                            .join(', ')
                        : 'Yok',
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _InfoRow(
                    label: AppLocalizations.of(context).chronicConditions,
                    value: _data?.chronicConditions.isNotEmpty == true
                        ? _data!.chronicConditions.join(', ')
                        : 'Yok',
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _InfoRow(
                    label: AppLocalizations.of(context).organDonor,
                    value: (_data?.organDonor ?? false) ? 'Evet ✓' : 'Hayır',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Emergency Contact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acil Durumda Ara',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _callEmergencyContact,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.call, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _data?.emergencyContactPhone ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_data?.emergencyContactName ?? '-'} (${_data?.emergencyContactRelation ?? '-'})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DoctorRow(data: _data, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Notes
            if (_data?.notes.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _data!.notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // QR Button
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code, size: 20),
              label: Text(AppLocalizations.of(context).qrKodIlePaylas),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '⚠️ Şifrelenmiş veri — sadece yetkili okuyabilir',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(height: 40),
              ],
            ),
          ),
          // QR Modal
          if (_showQR && _qrValue != null)
        GestureDetector(
          onTap: () => setState(() => _showQR = false),
          child: Container(
            color: Colors.black.withAlpha(180),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context).qrShare,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ambulans personeli okutabilir',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: _qrValue!,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFFE5E7EB),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '⚠️ Şifrelenmiş veri',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _showQR = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context).close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? AppColors.error
                    : (const Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorRow extends StatelessWidget {
  final HealthCardData? data;
  final bool isDark;

  const _DoctorRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doktor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data?.doctorName ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                Text(
                  data?.doctorHospital ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
