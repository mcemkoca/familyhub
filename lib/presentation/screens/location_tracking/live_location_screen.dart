// lib/presentation/screens/location_tracking/live_location_screen.dart
// Live location tracking view with status summary

import 'package:flutter/material.dart';
import '../../../services/battery_aware_location_tracker.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final tracker = BatteryAwareLocationTracker();

  @override
  void initState() {
    super.initState();
    tracker.lastLocationNotifier.addListener(_onLocationUpdate);
    tracker.profileNotifier.addListener(_onProfileUpdate);
  }

  void _onLocationUpdate() {
    if (mounted) setState(() {});
  }

  void _onProfileUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    tracker.lastLocationNotifier.removeListener(_onLocationUpdate);
    tracker.profileNotifier.removeListener(_onProfileUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastLoc = tracker.lastLocationNotifier.value;
    final profile = tracker.profileNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).canliKonumTakibi),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Map placeholder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.white38),
                  SizedBox(height: 8),
                  Text('Harita Görünümü', style: TextStyle(color: Colors.white38)),
                  SizedBox(height: 4),
                  Text('🟢 Aktif rota gösteriliyor', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANLIK DURUM',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _statusRow(Icons.location_on, 'Konum', lastLoc != null
                    ? '${lastLoc.latitude.toStringAsFixed(4)}°, ${lastLoc.longitude.toStringAsFixed(4)}°'
                    : 'Bekleniyor...'),
                _statusRow(Icons.directions_walk, 'Hareket', 'Yürüyüş (4.2 km/h)'),
                _statusRow(Icons.settings, 'Profil', profile),
                _statusRow(Icons.timer, 'Güncelleme', '1 dk\'da bir'),
                const Divider(color: Colors.white24, height: 20),
                _statusRow(Icons.battery_full, 'Batarya', '%58 | Tahmini: 18 saat'),
                _statusRow(Icons.network_cell, 'Sağlayıcı', 'GPS + WiFi'),
                _statusRow(Icons.signal_cellular_alt, 'Sinyal', 'İyi'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Daily summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GÜN İÇİ ÖZET',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _statRow('Toplam mesafe', '8.5 km'),
                _statRow('Aktif süre', '2 saat 15 dk'),
                _statRow('Durağan süre', '5 saat 30 dk'),
                _statRow('Konum kaydı', '45 nokta'),
                _statRow('Batarya kullanımı', '%12'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/battery-analytics'),
                  icon: const Icon(Icons.assessment),
                  label: Text(AppLocalizations.of(context).detayliRapor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_location),
                  label: Text(AppLocalizations.of(context).konumPaylas),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
