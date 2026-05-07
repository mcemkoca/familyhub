// lib/presentation/screens/location_tracking/profile_editor_screen.dart
// Motion profile editor with interval, accuracy, provider, transition rules

import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  int _updateInterval = 10;
  int _distanceFilter = 10;
  String _accuracy = 'high';

  bool _limitGpsTime = true;
  int _maxGpsSearch = 5;
  bool _quickFix = true;
  bool _motionTrigger = true;

  String _transitionType = 'speed';
  int _speedThreshold = 15;
  int _stabilizationDelay = 30;
  int _exitDuration = 60;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final label = args?['label'] as String? ?? 'Profil';
    final color = args?['color'] as Color? ?? Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Düzenle: $label'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
          IconButton(icon: const Icon(Icons.restore), onPressed: _reset),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General
          _section(
            'GENEL',
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'İsim'),
                controller: TextEditingController(text: label),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(
                      'İkon: ${args?['icon'] ?? Icons.directions_car}',
                    ),
                    backgroundColor: color.withAlpha(51),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Renk: $color'),
                    backgroundColor: color.withAlpha(51),
                  ),
                ],
              ),
            ],
          ),

          // Update settings
          _section(
            'GÜNCELLEME AYARLARI',
            children: [
              _numberField(
                'Sıklık (saniye)',
                _updateInterval.toString(),
                (v) => _updateInterval = int.tryParse(v) ?? 10,
              ),
              const Text(
                '5-60 sn arası',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _numberField(
                'Mesafe filtresi (metre)',
                _distanceFilter.toString(),
                (v) => _distanceFilter = int.tryParse(v) ?? 10,
              ),
              const Text(
                'Konum değişmeden güncelleme yok',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: true,
                onChanged: (_) {},
                title: Text(AppLocalizations.of(context).zamanlayiciYedek),
                subtitle: const Text(
                  'Konum değişmese bile zorunlu güncelleme',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Accuracy
          _section(
            'HASSASİYET',
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'high', label: Text('Yüksek (10m)')),
                  ButtonSegment(value: 'medium', label: Text('Orta (50m)')),
                  ButtonSegment(value: 'low', label: Text('Düşük (100m+)')),
                ],
                selected: {_accuracy},
                onSelectionChanged: (s) => setState(() => _accuracy = s.first),
              ),
              const SizedBox(height: 12),
              const Text(
                'GPS kalitesi düşükse:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioListTile(
                title: const Text('WiFi + Cellular dene'),
                value: 'fallback',
                groupValue: 'fallback',
                onChanged: (_) {},
              ),
              RadioListTile(
                title: const Text('Son bilinen konumu kullan'),
                value: 'cached',
                groupValue: 'fallback',
                onChanged: (_) {},
              ),
            ],
          ),

          // Power management
          _section(
            'GÜÇ YÖNETİMİ',
            children: [
              SwitchListTile(
                value: _limitGpsTime,
                onChanged: (v) => setState(() => _limitGpsTime = v),
                title: Text(AppLocalizations.of(context).gpsAcikKalmaSuresiniSinirla),
              ),
              if (_limitGpsTime)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: _numberField(
                    'Max konum araması (sn)',
                    _maxGpsSearch.toString(),
                    (v) => _maxGpsSearch = int.tryParse(v) ?? 5,
                  ),
                ),
              SwitchListTile(
                value: _quickFix,
                onChanged: (v) => setState(() => _quickFix = v),
                title: const Text('Hızlı fix (önceki konumdan)'),
              ),
              SwitchListTile(
                value: _motionTrigger,
                onChanged: (v) => setState(() => _motionTrigger = v),
                title: Text(AppLocalizations.of(context).hareketAlgilayiciIleTetikle),
                subtitle: const Text(
                  'Telefon sallanınca aktif ol',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Transition rules
          _section(
            'GEÇİŞ KURALLARI',
            children: [
              const Text(
                'Bu profile geçiş:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'speed', label: Text(AppLocalizations.of(context).hizEsigi)),
                  ButtonSegment(value: 'activity', label: Text('Aktivite')),
                  ButtonSegment(value: 'manual', label: Text('Manuel')),
                ],
                selected: {_transitionType},
                onSelectionChanged: (s) =>
                    setState(() => _transitionType = s.first),
              ),
              if (_transitionType == 'speed') ...[
                const SizedBox(height: 12),
                _numberField(
                  'Hız eşiği (km/h)',
                  _speedThreshold.toString(),
                  (v) => _speedThreshold = int.tryParse(v) ?? 15,
                ),
                _numberField(
                  'Stabil süre (sn)',
                  _stabilizationDelay.toString(),
                  (v) => _stabilizationDelay = int.tryParse(v) ?? 30,
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Bu profilden çıkış:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _numberField(
                'Durma süresi (sn)',
                _exitDuration.toString(),
                (v) => _exitDuration = int.tryParse(v) ?? 60,
              ),
              const Text(
                'Bu süre boyunca hareketsiz kalınca düşük profil',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
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

  Widget _section(String title, {required List<Widget> children}) {
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

  Widget _numberField(
    String label,
    String initial,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: initial),
      onChanged: onChanged,
    );
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil kaydedildi')));
  }

  void _reset() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).varsayilanaSifirlandi)));
  }
}
