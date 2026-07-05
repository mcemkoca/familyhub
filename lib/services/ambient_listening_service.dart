import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Ambient listening / emergency recording service.
class AmbientListeningService {
  static final _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentPath;
  static StreamSubscription<dynamic>? _accelSub;
  static Timer? _dbTimer;
  static final _dbController = StreamController<double>.broadcast();
  static final _shakeController = StreamController<void>.broadcast();

  static bool get isRecording => _isRecording;
  static Stream<double> get dbStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 200)).map((a) => a.current);
  static Stream<void> get shakeStream => _shakeController.stream;

  static Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start emergency recording (up to maxSeconds).
  static Future<String?> startRecording({int maxSeconds = 60}) async {
    if (_isRecording) return null;
    final hasPerm = await requestPermission();
    if (!hasPerm) return null;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/emergency_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    await _recorder.start(const RecordConfig(), path: path);
    _isRecording = true;

    // Auto stop
    Timer(Duration(seconds: maxSeconds), () async {
      await stopRecording();
    });

    return path;
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  static Future<void> cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
    if (_currentPath != null) {
      try {
        await File(_currentPath!).delete();
      } catch (e) { debugPrint('Ambient listening error: $e'); }
    }
  }

  /// Request sensor permission required on Android 12+ for high-rate accelerometer.
  static Future<bool> requestSensorPermission() async {
    final status = await Permission.sensors.request();
    return status.isGranted;
  }

  /// Initialize shake detection (3 strong shakes)
  static void initShakeDetection({double threshold = 25.0}) {
    _accelSub?.cancel();
    var shakeCount = 0;
    DateTime? lastShake;

    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > threshold) {
        final now = DateTime.now();
        if (lastShake == null || now.difference(lastShake!).inMilliseconds > 500) {
          shakeCount++;
          lastShake = now;
          if (shakeCount >= 3) {
            shakeCount = 0;
            _shakeController.add(null);
          }
        }
      }
    });
  }

  static void dispose() {
    _accelSub?.cancel();
    _dbTimer?.cancel();
    _dbController.close();
    _shakeController.close();
  }
}
