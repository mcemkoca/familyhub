// ignore_for_file: deprecated_member_use
// lib/presentation/screens/location_tracking/profile_editor_screen.dart
// Motion profile editor with interval, accuracy, provider, transition rules

import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../core/settings_store.dart';

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
        title: Text(AppLocalizations.of(context).peTitle(label)),
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
                decoration: InputDecoration(labelText: AppLocalizations.of(context).isim),
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
                    label: Text(AppLocalizations.of(context).peColor(color)),
                    backgroundColor: color.withAlpha(51),
                  ),
                ],
              ),
            ],
          ),

          // Update settings
          _section(AppLocalizations.of(context).guncellemeAyarlari,
            children: [
              _numberField(
                'Sıklık (saniye)',
                _updateInterval.toString(),
                (v) => _updateInterval = int.tryParse(v) ?? 10,
              ),
              Text(AppLocalizations.of(context).snArasi,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _numberField(
                'Mesafe filtresi (metre)',
                _distanceFilter.toString(),
                (v) => _distanceFilter = int.tryParse(v) ?? 10,
              ),
              Text(AppLocalizations.of(context).konumDegismedenGuncellemeYok,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: true,
                onChanged: (_) {},
                title: Text(AppLocalizations.of(context).zamanlayiciYedek),
                subtitle: Text(AppLocalizations.of(context).konumDegismeseBileZorunluGuncelleme,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Accuracy
          _section(AppLocalizations.of(context).hassasiyet,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'high', label: Text(AppLocalizations.of(context).peHigh)),
                  ButtonSegment(value: 'medium', label: Text(AppLocalizations.of(context).peMedium)),
                  ButtonSegment(value: 'low', label: Text(AppLocalizations.of(context).peLow)),
                ],
                selected: {_accuracy},
                onSelectionChanged: (s) => setState(() => _accuracy = s.first),
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).gpsKalitesiDusukse,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioListTile(
                title: Text(AppLocalizations.of(context).peWifiCellular),
                value: 'fallback',
                groupValue: 'fallback',
                onChanged: (_) {},
              ),
              RadioListTile(
                title: Text(AppLocalizations.of(context).peLastKnown),
                value: 'cached',
                groupValue: 'fallback',
                onChanged: (_) {},
              ),
            ],
          ),

          // Power management
          _section(AppLocalizations.of(context).gucYonetimi,
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
                title: Text(AppLocalizations.of(context).peFastFix),
              ),
              SwitchListTile(
                value: _motionTrigger,
                onChanged: (v) => setState(() => _motionTrigger = v),
                title: Text(AppLocalizations.of(context).hareketAlgilayiciIleTetikle),
                subtitle: Text(AppLocalizations.of(context).telefonSallanincaAktifOl,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Transition rules
          _section(AppLocalizations.of(context).gecisKurallari,
            children: [
              Text(AppLocalizations.of(context).buProfileGecis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'speed', label: Text(AppLocalizations.of(context).hizEsigi)),
                  ButtonSegment(value: 'activity', label: Text(AppLocalizations.of(context).peActivity)),
                  ButtonSegment(value: 'manual', label: Text(AppLocalizations.of(context).peManual)),
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
              Text(AppLocalizations.of(context).buProfildenCikis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _numberField(
                'Durma süresi (sn)',
                _exitDuration.toString(),
                (v) => _exitDuration = int.tryParse(v) ?? 60,
              ),
              Text(AppLocalizations.of(context).buSureBoyuncaHareketsizKalincaDusukProfil,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context).crashSaveUpper, style: const TextStyle(fontSize: 16)),
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

  static const _storeName = 'location_profile';

  /// Profili GERÇEKTEN kaydeder (önceden yalnızca mesaj gösteriliyordu).
  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final okMsg = AppLocalizations.of(context).peSaved;
    final failMsg = AppLocalizations.of(context).settingsSaveFailed;
    final ok = await SettingsStore.save(_storeName, {
      'updateInterval': _updateInterval,
      'distanceFilter': _distanceFilter,
      'accuracy': _accuracy,
      'limitGpsTime': _limitGpsTime,
      'maxGpsSearch': _maxGpsSearch,
      'quickFix': _quickFix,
      'motionTrigger': _motionTrigger,
      'transitionType': _transitionType,
      'speedThreshold': _speedThreshold,
      'stabilizationDelay': _stabilizationDelay,
      'exitDuration': _exitDuration,
    });
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? okMsg : failMsg),
      backgroundColor: ok ? null : const Color(0xFFB42318),
    ));
  }

  void _loadProfile() {
    final j = SettingsStore.load(_storeName);
    if (j.isEmpty) return;
    setState(() {
      _updateInterval = (j['updateInterval'] as num?)?.toInt() ?? _updateInterval;
      _distanceFilter = (j['distanceFilter'] as num?)?.toInt() ?? _distanceFilter;
      _accuracy = j['accuracy'] as String? ?? _accuracy;
      _limitGpsTime = j['limitGpsTime'] as bool? ?? _limitGpsTime;
      _maxGpsSearch = (j['maxGpsSearch'] as num?)?.toInt() ?? _maxGpsSearch;
      _quickFix = j['quickFix'] as bool? ?? _quickFix;
      _motionTrigger = j['motionTrigger'] as bool? ?? _motionTrigger;
      _transitionType = j['transitionType'] as String? ?? _transitionType;
      _speedThreshold = (j['speedThreshold'] as num?)?.toInt() ?? _speedThreshold;
      _stabilizationDelay = (j['stabilizationDelay'] as num?)?.toInt() ?? _stabilizationDelay;
      _exitDuration = (j['exitDuration'] as num?)?.toInt() ?? _exitDuration;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _reset() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).varsayilanaSifirlandi)));
  }
}
