// lib/presentation/screens/crash/crash_family_alert_screen.dart
// Family member view when a crash is detected for another member

import 'package:flutter/material.dart';
import '../../../domain/models/crash_event.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CrashFamilyAlertScreen extends StatelessWidget {
  final CrashEvent event;
  const CrashFamilyAlertScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: Text(AppLocalizations.of(context).acilDurumBildirimi),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Victim card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(76),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${event.memberName} KAZA GEÇİRDİ!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Olay: ${_fmt(event.detection.timestamp)} (${_ago(event.detection.timestamp)})',
                                style: TextStyle(color: Colors.red.shade100, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row(Icons.location_on, 'Konum: D100 Karayolu, 15. km'),
                    _row(Icons.directions_car, 'Durum: Araç hareketsiz'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _actionChip(Icons.map, 'Haritada Gör', Colors.blue),
                        _actionChip(Icons.directions, 'Yol Tarifi', Colors.green),
                        _actionChip(Icons.phone, '${event.memberName}\'i Ara', Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(76),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_searching, color: Colors.greenAccent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Canlı Konum',
                                style: TextStyle(color: Colors.greenAccent.shade100, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '● Güncel: ${_fmt(DateTime.now())}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '${event.sensorData.gps.latitude.toStringAsFixed(4)}°N, ${event.sensorData.gps.longitude.toStringAsFixed(4)}°E',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Response checklist
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YAPILACAKLAR',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _checkItem(true, 'Aile üyelerine bildirildi'),
                      _checkItem(true, 'Acil kontaklara SMS gönderildi'),
                      _checkItem(false, '112 aranıyor...', active: true),
                      _checkItem(true, 'Konum paylaşımı aktif'),
                      _checkItem(true, 'Sağlık kartı paylaşıldı'),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.article),
                          label: Text(AppLocalizations.of(context).detayliRapor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B7280),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.emergency),
                      label: Text(AppLocalizations.of(context).yardimCagir),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_forwarded),
                      label: Text(AppLocalizations.of(context).aileyiBilgilendir),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color.withAlpha(178),
      onPressed: () {},
    );
  }

  Widget _checkItem(bool done, String text, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : (active ? Icons.timelapse : Icons.radio_button_unchecked),
            color: done ? Colors.green : (active ? Colors.orange : Colors.white38),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: done ? Colors.green.shade100 : Colors.white.withAlpha(204),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    return '${diff.inHours} sa önce';
  }
}
