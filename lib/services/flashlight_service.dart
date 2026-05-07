import 'dart:async';
import 'package:torch_light/torch_light.dart';

/// Flashlight with SOS morse and strobe modes.
class FlashlightService {
  static bool _isOn = false;
  static bool _sosMode = false;
  static bool _strobeMode = false;
  static Timer? _timer;

  static bool get isOn => _isOn;
  static bool get sosMode => _sosMode;
  static bool get strobeMode => _strobeMode;

  static Future<void> turnOn() async {
    try {
      await TorchLight.enableTorch();
      _isOn = true;
    } catch (_) {}
  }

  static Future<void> turnOff() async {
    try {
      await TorchLight.disableTorch();
      _isOn = false;
      _stopEffects();
    } catch (_) {}
  }

  static Future<void> toggle() async {
    if (_isOn) {
      await turnOff();
    } else {
      await turnOn();
    }
  }

  static void _stopEffects() {
    _sosMode = false;
    _strobeMode = false;
    _timer?.cancel();
    _timer = null;
  }

  /// SOS Morse code: ... --- ... (200ms short, 600ms long)
  static Future<void> startSos() async {
    _stopEffects();
    _sosMode = true;
    if (!_isOn) await turnOn();

    // Pattern: onDuration, offDuration, ...
    // S = 3x(200ms on, 200ms off) -> 6 entries
    // O = 3x(600ms on, 200ms off) -> 6 entries
    // S = 3x(200ms on, 200ms off) -> 6 entries
    // word gap = 1000ms off
    final pattern = <int>[
      200, 200, 200, 200, 200, 200,
      600, 200, 600, 200, 600, 200,
      200, 200, 200, 200, 200, 200,
      1000,
    ];

    var step = 0;
    var tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_sosMode) return;

      final isOnPhase = tick % 2 == 0;
      final durationTicks = (pattern[step] / 100).round();

      if (isOnPhase) {
        try { await TorchLight.enableTorch(); } catch (_) {}
      } else {
        try { await TorchLight.disableTorch(); } catch (_) {}
      }

      tick++;
      if (tick >= durationTicks * 2) {
        tick = 0;
        step = (step + 1) % pattern.length;
      }
    });
  }

  static void stopSos() {
    _sosMode = false;
    _timer?.cancel();
    _timer = null;
    turnOff();
  }

  /// Strobe mode with configurable frequency (ms)
  static Future<void> startStrobe({int frequencyMs = 100}) async {
    _stopEffects();
    _strobeMode = true;
    _timer = Timer.periodic(Duration(milliseconds: frequencyMs), (_) async {
      if (!_strobeMode) return;
      try {
        if (_isOn) {
          await TorchLight.disableTorch();
          _isOn = false;
        } else {
          await TorchLight.enableTorch();
          _isOn = true;
        }
      } catch (_) {}
    });
  }

  static void stopStrobe() {
    _strobeMode = false;
    _timer?.cancel();
    _timer = null;
    turnOff();
  }

  static void dispose() {
    _stopEffects();
  }
}
