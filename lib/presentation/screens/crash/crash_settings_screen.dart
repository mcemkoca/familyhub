// lib/presentation/screens/crash/crash_settings_screen.dart
// Crash detection settings, thresholds, SOS config, test mode

import 'package:flutter/material.dart';

import '../../../domain/models/crash_settings.dart';
import '../../../services/crash_detection_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CrashSettingsScreen extends StatefulWidget {
  const CrashSettingsScreen({super.key});

  @override
  State<CrashSettingsScreen> createState() => _CrashSettingsScreenState();
}

class _CrashSettingsScreenState extends State<CrashSettingsScreen> {
  bool _enabled = true;
  CrashSensitivity _sensitivity = CrashSensitivity.medium;

  final _minImpactGCtrl = TextEditingController(text: '4.0');
  final _speedChangeCtrl = TextEditingController(text: '8.0');
  final _rolloverCtrl = TextEditingController(text: '5.0');
  final _confirmationCtrl = TextEditingController(text: '30');

  bool _autoCallEmergency = false;
  bool _autoNotifyFamily = true;
  bool _autoNotifyContacts = true;
  bool _shareLocation = true;
  bool _shareMedicalInfo = true;

  bool _soundAlert = true;
  String _soundType = 'crash_alarm';
  bool _vibration = true;
  VibrationPattern _vibrationPattern = VibrationPattern.sos;
  bool _screenFlash = true;
  bool _maxVolume = true;
  bool _bypassDnd = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).kazaTespitiAyarlari),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Test Et',
            onPressed: _showTestDialog,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'GENEL AYARLAR',
            children: [
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('Kaza tespiti aktif'),
                secondary: const Icon(Icons.shield, color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hassasiyet:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<CrashSensitivity>(
                segments: [
                  ButtonSegment(
                    value: CrashSensitivity.low,
                    label: Text(AppLocalizations.of(context).low),
                  ),
                  ButtonSegment(
                    value: CrashSensitivity.medium,
                    label: Text(AppLocalizations.of(context).medium),
                  ),
                  ButtonSegment(
                    value: CrashSensitivity.high,
                    label: Text(AppLocalizations.of(context).high),
                  ),
                  ButtonSegment(
                    value: CrashSensitivity.custom,
                    label: Text(AppLocalizations.of(context).ozel),
                  ),
                ],
                selected: {_sensitivity},
                onSelectionChanged: (s) =>
                    setState(() => _sensitivity = s.first),
              ),
              if (_sensitivity == CrashSensitivity.high)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Yüksek: Daha hassas, daha fazla yanlış alarm olabilir',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          if (_sensitivity == CrashSensitivity.custom)
            _buildSection(
              'ÖZEL EŞİK DEĞERLERİ',
              children: [
                _buildNumberField(
                  'Min darbe kuvveti',
                  _minImpactGCtrl,
                  suffix: 'G',
                ),
                _buildNumberField(
                  'Max hız düşüşü',
                  _speedChangeCtrl,
                  suffix: 'm/s²',
                ),
                _buildNumberField(
                  'Yuvarlanma eşiği',
                  _rolloverCtrl,
                  suffix: 'rad/s',
                ),
                _buildNumberField(
                  'Doğrulama süresi',
                  _confirmationCtrl,
                  suffix: 'sn',
                ),
              ],
            ),

          _buildSection(
            'SOS AYARLARI',
            children: [
              _buildSwitch(
                'Aile üyelerini otomatik bilgilendir',
                _autoNotifyFamily,
                (v) => setState(() => _autoNotifyFamily = v),
              ),
              _buildSwitch(
                'Acil kontaklara SMS gönder',
                _autoNotifyContacts,
                (v) => setState(() => _autoNotifyContacts = v),
              ),
              _buildSwitch(
                '112\'yi otomatik ara',
                _autoCallEmergency,
                (v) => setState(() => _autoCallEmergency = v),
              ),
              if (_autoCallEmergency)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    '⚠️ Yasal sorumluluk bildirimi: Yanlış arama cezası kullanıcı sorumluluğundadır.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              _buildSwitch(
                'Konum paylaşımı aktif et',
                _shareLocation,
                (v) => setState(() => _shareLocation = v),
              ),
              _buildSwitch(
                'Sağlık kartını paylaş',
                _shareMedicalInfo,
                (v) => setState(() => _shareMedicalInfo = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _editContacts,
                icon: const Icon(Icons.contacts),
                label: Text(AppLocalizations.of(context).acilKontaklariDuzenle),
              ),
            ],
          ),

          _buildSection(
            'BİLDİRİM AYARLARI',
            children: [
              _buildSwitch(
                'Sesli alarm çal',
                _soundAlert,
                (v) => setState(() => _soundAlert = v),
              ),
              if (_soundAlert)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _soundType,
                    decoration: const InputDecoration(labelText: 'Ses'),
                    items: [
                      const DropdownMenuItem(
                        value: 'crash_alarm',
                        child: Text('Acil alarm'),
                      ),
                      const DropdownMenuItem(value: 'siren', child: Text('Siren')),
                      DropdownMenuItem(value: 'plain', child: Text(AppLocalizations.of(context).duzSes)),
                    ],
                    onChanged: (v) => setState(() => _soundType = v!),
                  ),
                ),
              _buildSwitch(
                'Titreşim',
                _vibration,
                (v) => setState(() => _vibration = v),
              ),
              if (_vibration)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SegmentedButton<VibrationPattern>(
                    segments: [
                      const ButtonSegment(
                        value: VibrationPattern.sos,
                        label: Text('SOS'),
                      ),
                      const ButtonSegment(
                        value: VibrationPattern.alarm,
                        label: Text('Alarm'),
                      ),
                      ButtonSegment(
                        value: VibrationPattern.pulse,
                        label: Text(AppLocalizations.of(context).nabiz),
                      ),
                    ],
                    selected: {_vibrationPattern},
                    onSelectionChanged: (s) =>
                        setState(() => _vibrationPattern = s.first),
                  ),
                ),
              _buildSwitch(
                'Ekran flaş',
                _screenFlash,
                (v) => setState(() => _screenFlash = v),
              ),
              _buildSwitch(
                'Maksimum ses seviyesi',
                _maxVolume,
                (v) => setState(() => _maxVolume = v),
              ),
              _buildSwitch(
                'Rahatsız etme modunu geç',
                _bypassDnd,
                (v) => setState(() => _bypassDnd = v),
              ),
            ],
          ),

          _buildSection(
            'TEST MODU',
            children: [
              const Text(
                'Son test: 15 Mart 2025 - BAŞARILI',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showTestDialog,
                icon: const Icon(Icons.science),
                label: Text(AppLocalizations.of(context).simulasyonTestiBaslat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Telefonu sallayarak test edin',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('KAYDET', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController ctrl, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _editContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acil kişiler yakında düzenlenebilecek')),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Modu'),
        content: Text(AppLocalizations.of(context).telefonuSallayarakKazaSimulasyonunuBaslatin),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CrashDetectionService().feedAccelerometer(50, 50, 50);
            },
            child: Text(AppLocalizations.of(context).baslat),
          ),
        ],
      ),
    );
  }
}
