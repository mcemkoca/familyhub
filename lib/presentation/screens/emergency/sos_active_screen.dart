// lib/presentation/screens/emergency/sos_active_screen.dart
// Active SOS screen with status, auto-response progress, escalation chain

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/emergency_auto_actions_engine.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> {
  final _engine = EmergencyAutoActionsEngine();
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = _elapsed + const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    return '${d.inMinutes} dk ${d.inSeconds % 60} sn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(204),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emergency, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context).sosAktif,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(AppLocalizations.of(context).otomatikYardimCagrisiDevamEdiyor,
                      style: TextStyle(
                        color: Colors.red.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emergency details
                      _card('ACİL DURUM DETAYLARI', [
                        _row(Icons.car_crash, '🚗 KAZA'),
                        _row(
                          Icons.description,
                          'Yüksek şiddetli çarpma tespit edildi',
                        ),
                        const Divider(color: Colors.white24),
                        _row(
                          Icons.location_on,
                          '📍 Konum: D100 Karayolu, 15. km',
                        ),
                        _row(Icons.access_time, '⏰ Başlangıç: 14:32:15'),
                        _row(
                          Icons.timer,
                          '⏱️ Geçen süre: ${_fmtDuration(_elapsed)}',
                        ),
                        _row(
                          Icons.warning,
                          '🎯 Seviye: YÜKSEK 🔴',
                          valueColor: Colors.red,
                        ),
                      ]),

                      const SizedBox(height: 12),

                      // Auto response status
                      _card('OTOMATİK YANIT DURUMU', [
                        _checkRow(
                          true,
                          'Konum paylaşımı aktif',
                          subtitle: '● Canlı güncelleme (30 sn)',
                        ),
                        _checkRow(
                          true,
                          'Aile üyelerine bildirildi',
                          subtitle: '👨 Baba (SMS) | 👩 Anne (Push)',
                        ),
                        _checkRow(
                          true,
                          'Acil kontaklara SMS gönderildi',
                          subtitle: '📱 +90 555 123 4567',
                        ),
                        _checkRow(
                          false,
                          '112 aranıyor...',
                          subtitle: 'Deneme: 1/3',
                          active: true,
                        ),
                        _checkRow(
                          true,
                          'Ses kaydı başladı',
                          subtitle: AppLocalizations.of(context).sure3Dk12Sn,
                        ),
                      ]),

                      const SizedBox(height: 12),

                      // Escalation chain
                      _card('YÜKSELTME ZİNCİRİ', [
                        _escalationStep(1, 'Aile bildirimi (0 dk)', true),
                        _escalationStep(2, 'Acil kontaklar (2 dk)', true),
                        _escalationStep(
                          3,
                          '112 arama (5 dk)',
                          false,
                          upcoming: true,
                        ),
                        _escalationStep(4, 'Komşu alert (10 dk)', false),
                        _escalationStep(5, 'Sesli alarm (15 dk)', false),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom actions
              ElevatedButton.icon(
                onPressed: () {
                  _engine.cancelAsFalseAlarm(
                    _engine.activeAction?.actionId ?? '',
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle, size: 28),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(AppLocalizations.of(context).iyiyimSistemiDurdur,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:112')),
                icon: const Icon(Icons.emergency, size: 28),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'YARDIM LAZIM - 112 ARA',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: valueColor ?? Colors.white.withAlpha(230),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(
    bool done,
    String text, {
    String? subtitle,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle
                : (active ? Icons.timelapse : Icons.radio_button_unchecked),
            color: done
                ? Colors.green
                : (active ? Colors.orange : Colors.white38),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: done
                        ? Colors.green.shade100
                        : Colors.white.withAlpha(204),
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _escalationStep(
    int step,
    String label,
    bool done, {
    bool upcoming = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : (upcoming ? Icons.timelapse : Icons.radio_button_unchecked),
            color: done
                ? Colors.green
                : (upcoming ? Colors.orange : Colors.white38),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            '$step. $label',
            style: TextStyle(
              color: done
                  ? Colors.green.shade100
                  : Colors.white.withAlpha(178),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
