// ignore_for_file: avoid_slow_async_io
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/locale_service.dart';

class VoiceMessageService {
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentPath;
  static final _amplitudeController = StreamController<double>.broadcast();
  static Timer? _amplitudeTimer;

  static Stream<double> get amplitudeStream => _amplitudeController.stream;
  static bool get isRecording => _isRecording;

  static Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      final lang = LocaleService.resolveInitialLocale().languageCode;
      throw Exception(const {
        'tr': 'Mikrofon izni gerekiyor',
        'en': 'Microphone permission is required',
        'nl': 'Microfoontoestemming is vereist',
        'fr': 'L’autorisation du microphone est requise',
      }[lang] ?? 'Mikrofon izni gerekiyor');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    _isRecording = true;

    // Simulate amplitude for waveform
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (
      _,
    ) async {
      if (!_isRecording) return;
      try {
        final amp = await _recorder.getAmplitude();
        final normalized = ((amp.current + 40) / 40).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      } catch (_) {
        _amplitudeController.add(0.1);
      }
    });
  }

  static Future<({File file, int durationMs})?> stopRecording() async {
    if (!_isRecording) return null;

    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _isRecording = false;

    final path = await _recorder.stop();
    if (path == null || _currentPath == null) return null;

    final file = File(_currentPath!);
    if (!await file.exists()) return null;

    final durationMs =
        DateTime.now().millisecondsSinceEpoch -
        int.parse(_currentPath!.split('_').last.split('.').first);

    _currentPath = null;
    return (file: file, durationMs: durationMs);
  }

  static Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _isRecording = false;

    await _recorder.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentPath = null;
    }
  }

  static void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
  }
}
