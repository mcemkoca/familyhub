// lib/presentation/screens/crash/crash_confirmation_screen.dart

import 'package:flutter/material.dart';
import '../../../domain/models/crash_event.dart';
import '../../../services/crash_detection_service.dart';
import '../../../services/location_tracking_service.dart';
import '../call/call_contact_list_screen.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class CrashConfirmationScreen extends StatefulWidget {
  final CrashEvent event;
  const CrashConfirmationScreen({super.key, required this.event});

  @override
  State<CrashConfirmationScreen> createState() =>
      _CrashConfirmationScreenState();
}

class _CrashConfirmationScreenState extends State<CrashConfirmationScreen>
    with TickerProviderStateMixin {
  final CrashDetectionService _service = CrashDetectionService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _service.countdownNotifier.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.countdownNotifier.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final countdown = _service.countdownNotifier.value;
    final progress = (1 - (countdown / 30).clamp(0, 1)).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(countdown),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDetailCard(event),
                      const SizedBox(height: 16),
                      _buildCountdownBar(progress, countdown),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _service.silenceAlarm();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alarm susturuldu')),
                        );
                      },
                      icon: const Icon(Icons.volume_off),
                      label: Text(AppLocalizations.of(context).alarmiKapat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await LocationTrackingService
                            .shareCurrentLocation();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(ok
                                    ? 'Konum aileyle paylaşıldı'
                                    : 'Konum alınamadı')),
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      label: Text(AppLocalizations.of(context).konumGuncelle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
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

  Widget _buildHeader(int countdown) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400, width: 2),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) => Transform.scale(
              scale: 1 + _pulseController.value * 0.1,
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).kazaTespitEdildi,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Otomatik SOS ${countdown}s sonra başlayacak',
            style: TextStyle(color: Colors.red.shade100, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(CrashEvent event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ UYARI',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _row(Icons.directions_car, 'Araç hareketi ani durdu'),
          _row(
            Icons.bolt,
            '${event.sensorData.accelerometer.peakG.toStringAsFixed(1)}G darbe tespit edildi',
          ),
          if (event.sensorData.gyroscope != null)
            _row(Icons.sync_problem, 'Yuvarlanma algılandı'),
          const Divider(color: Colors.white24, height: 20),
          _row(
            Icons.verified,
            'Güven skoru: ${(event.detection.confidence * 100).toStringAsFixed(0)}% 🔴',
            color: Colors.redAccent,
          ),
          _row(
            Icons.location_on,
            'Son konum:\n${event.sensorData.gps.latitude.toStringAsFixed(4)}°N, ${event.sensorData.gps.longitude.toStringAsFixed(4)}°E',
          ),
          _row(
            Icons.access_time,
            'Olay zamanı: ${_fmt(event.detection.timestamp)}',
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white.withAlpha(230),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBar(double progress, int seconds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(AppLocalizations.of(context).geriSayim,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFF374151),
              valueColor: AlwaysStoppedAnimation(
                progress > 0.7 ? Colors.red : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$seconds SANİYE',
            style: TextStyle(
              color: progress > 0.7 ? Colors.redAccent : Colors.orange,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(AppLocalizations.of(context).sosOtomatikBaslayacak,
            style: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _btn(
          'İYİYİM',
          Icons.check_circle,
          Colors.green.shade700,
          () => _service.respondImOk(),
        ),
        const SizedBox(height: 12),
        _btn(
          'YARDIM LAZIM',
          Icons.emergency,
          Colors.red.shade700,
          () => _service.respondNeedHelp(),
        ),
        const SizedBox(height: 12),
        _btn('AİLEYİ ARA', Icons.phone, Colors.blue.shade800, () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CallContactListScreen()));
        }),
      ],
    );
  }

  Widget _btn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
