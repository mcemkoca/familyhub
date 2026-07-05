// lib/presentation/screens/location_tracking/location_tracking_settings_screen.dart
// Main settings for battery-aware location tracking

import 'package:flutter/material.dart';
import '../../../domain/models/location_tracking.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LocationTrackingSettingsScreen extends StatefulWidget {
  const LocationTrackingSettingsScreen({super.key});

  @override
  State<LocationTrackingSettingsScreen> createState() => _LocationTrackingSettingsScreenState();
}

class _LocationTrackingSettingsScreenState extends State<LocationTrackingSettingsScreen> {
  bool _enabled = true;
  TrackingPriority _priority = TrackingPriority.balanced;

  final _profiles = LocationTrackingSettings.defaultProfiles;

  bool _adaptiveBrightness = true;
  bool _backgroundRefresh = true;
  bool _networkBatching = true;
  bool _locationCache = true;
  bool _motionCoProcessor = true;
  bool _geofenceOptimization = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).konumTakipAyarlari),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Optimize Et',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Kaydet',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('GENEL MOD', children: [
            SwitchListTile(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              title: const Text('Konum takibi aktif'),
              secondary: const Icon(Icons.location_on, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text('Öncelik:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<TrackingPriority>(
              segments: [
                const ButtonSegment(value: TrackingPriority.battery, label: Text('Batarya')),
                const ButtonSegment(value: TrackingPriority.balanced, label: Text('Dengeli')),
                const ButtonSegment(value: TrackingPriority.accuracy, label: Text('Hassas')),
                ButtonSegment(value: TrackingPriority.custom, label: Text(AppLocalizations.of(context).ozel)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _priorityDescription(),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ]),

          _section('BATARYA DURUMU', children: [
            LinearProgressIndicator(
              value: 0.58,
              minHeight: 12,
              backgroundColor: const Color(0xFF374151),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
            const SizedBox(height: 8),
            const Text('58% - Tahmini kalan süre:', style: TextStyle(fontWeight: FontWeight.w600)),
            _estimateRow('Mevcut modda', '18 saat'),
            _estimateRow('Batarya dostu', '36 saat'),
            _estimateRow('Hassas modda', '8 saat'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/battery-analytics'),
              icon: const Icon(Icons.analytics),
              label: Text(AppLocalizations.of(context).detayliAnaliz),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ]),

          _section('HAREKET PROFİLLERİ', children: [
            _profileTile('stationary', 'Durağan', Icons.stop_circle, Colors.grey),
            _profileTile('walking', 'Yürüyüş', Icons.directions_walk, Colors.blue),
            _profileTile('driving', 'Araç', Icons.directions_car, Colors.orange),
            _profileTile('emergency', 'Acil Durum', Icons.emergency, Colors.red),
          ]),

          _section('GELİŞMİŞ AYARLAR', children: [
            _switchTile('Adaptif ekran parlaklığı', _adaptiveBrightness, (v) => setState(() => _adaptiveBrightness = v)),
            _switchTile('Arka plan yenileme optimizasyonu', _backgroundRefresh, (v) => setState(() => _backgroundRefresh = v)),
            _switchTile('Ağ isteklerini toplama', _networkBatching, (v) => setState(() => _networkBatching = v)),
            _switchTile('Konum önbellekleme', _locationCache, (v) => setState(() => _locationCache = v)),
            _switchTile('Yardımcı işlemci kullanımı', _motionCoProcessor, (v) => setState(() => _motionCoProcessor = v)),
            _switchTile('Geofence optimizasyonu', _geofenceOptimization, (v) => setState(() => _geofenceOptimization = v)),
          ]),

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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _estimateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _profileTile(String key, String label, IconData icon, Color color) {
    final config = _profiles[key];
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        config != null
            ? '${config.updateIntervalSeconds}s | ${config.accuracy} | ${config.providers.join('+')}'
            : '',
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
      trailing: TextButton.icon(
        onPressed: () => _editProfile(key, label, icon, color),
        icon: const Icon(Icons.edit, size: 18),
        label: Text(AppLocalizations.of(context).edit),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }

  String _priorityDescription() {
    switch (_priority) {
      case TrackingPriority.battery:
        return 'Öncelik: Maksimum pil ömrü. Tahmini: 2-3 gün konum takibi.';
      case TrackingPriority.balanced:
        return 'Öncelik: Doğru konum + pil. Tahmini: 1-2 gün konum takibi.';
      case TrackingPriority.accuracy:
        return 'Öncelik: En doğru konum. Tahmini: 8-12 saat konum takibi.';
      case TrackingPriority.custom:
        return 'Manuel ayarlar aktif.';
    }
  }

  void _editProfile(String key, String label, IconData icon, Color color) {
    Navigator.pushNamed(context, '/profile-editor', arguments: {
      'key': key,
      'label': label,
      'icon': icon,
      'color': color,
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayarlar kaydedildi')),
    );
  }
}
