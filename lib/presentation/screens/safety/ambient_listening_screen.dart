import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/ambient_listening_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class AmbientListeningScreen extends StatefulWidget {
  const AmbientListeningScreen({super.key});

  @override
  State<AmbientListeningScreen> createState() => _AmbientListeningScreenState();
}

class _AmbientListeningScreenState extends State<AmbientListeningScreen> {
  bool _recording = false;
  bool _shakeEnabled = true;
  double _currentDb = 40;
  StreamSubscription<dynamic>? _dbSub;
  StreamSubscription<dynamic>? _shakeSub;
  String? _lastRecordingPath;
  int _recordingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AmbientListeningService.initShakeDetection();
    _shakeSub = AmbientListeningService.shakeStream.listen((_) {
      if (_shakeEnabled && !_recording) {
        _startRecording(trigger: 'Sallama');
      }
    });
    _dbSub = AmbientListeningService.dbStream.listen((db) {
      if (mounted) setState(() => _currentDb = db);
    });
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    _shakeSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording({String trigger = 'Manuel'}) async {
    HapticFeedback.heavyImpact();
    final path = await AmbientListeningService.startRecording(maxSeconds: 60);
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mikrofon izni gerekli')));
      return;
    }
    setState(() {
      _recording = true;
      _recordingSeconds = 0;
      _lastRecordingPath = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    final path = await AmbientListeningService.stopRecording();
    _timer?.cancel();
    setState(() {
      _recording = false;
      _lastRecordingPath = path;
      _recordingSeconds = 0;
    });
    if (path != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt kaydedildi: ${path.split('/').last}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _dbColor(double db) {
    if (db > 90) return AppColors.error;
    if (db > 70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: const Text('Ortam Dinleme'),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(20)
                        : Colors.black.withAlpha(5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _recording ? '🔴 KAYIT YAPILIYOR' : '🟢 BEKLEME MODU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _recording ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Decibel meter
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _DbMeterPainter(
                        db: _currentDb,
                        color: _dbColor(_currentDb),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentDb.toStringAsFixed(1)} dB',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_recording) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_recordingSeconds / 60 sn',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _recording
                          ? _stopRecording
                          : () => _startRecording(),
                      icon: Icon(_recording ? Icons.stop : Icons.mic),
                      label: Text(_recording ? 'Durdur' : 'Kayıt Başlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _recording
                            ? AppColors.error
                            : AppColors.cobalt,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Triggers
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tetikleyiciler',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _shakeEnabled,
                    onChanged: (v) => setState(() => _shakeEnabled = v),
                    title: const Text('3x Sallama'),
                    subtitle: const Text(
                      'Telefonu 3 kez sallayınca kayıt başlar',
                    ),
                    secondary: const Icon(Icons.vibration),
                  ),
                  ListTile(
                    leading: const Icon(Icons.touch_app),
                    title: const Text('Manuel Buton'),
                    subtitle: Text(AppLocalizations.of(context).ekrandakiButonaBasarakBaslat),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_lastRecordingPath != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Son kayıt: ${_lastRecordingPath!.split('/').last}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DbMeterPainter extends CustomPainter {
  final double db;
  final Color color;
  final bool isDark;

  _DbMeterPainter({
    required this.db,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    final barCount = 20;
    final barWidth = (size.width - 40) / barCount;
    final barHeight = size.height - 30;
    final activeCount = ((db / 120) * barCount).round().clamp(0, barCount);

    for (var i = 0; i < barCount; i++) {
      final x = 20 + i * barWidth;
      final isActive = i < activeCount;
      final barPaint = Paint()
        ..color = isActive
            ? Color.lerp(AppColors.success, AppColors.error, i / barCount)!
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 15, barWidth - 4, barHeight),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DbMeterPainter old) {
    return old.db != db || old.color != color;
  }
}
