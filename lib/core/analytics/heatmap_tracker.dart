import 'dart:async';

import 'package:flutter/material.dart';

import '../supabase_client.dart';
import 'analytics_service.dart';

class HeatmapEvent {
  final String type; // 'tap' | 'scroll'
  final String screen;
  final String? elementId;
  final double? x; // normalized 0-1
  final double? y;
  final double? scrollDepth;
  final DateTime timestamp;

  HeatmapEvent({
    required this.type,
    required this.screen,
    this.elementId,
    this.x,
    this.y,
    this.scrollDepth,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'screen': screen,
        'element_id': elementId,
        'x': x,
        'y': y,
        'scroll_depth': scrollDepth,
        'timestamp': timestamp.toIso8601String(),
      };
}

class HeatmapTracker {
  static final List<HeatmapEvent> _buffer = [];
  static Timer? _flushTimer;

  static void initialize() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
  }

  static void dispose() {
    _flushTimer?.cancel();
    _flush();
  }

  static void trackTap(String screen, String elementId, Offset position, Size screenSize) {
    _buffer.add(HeatmapEvent(
      type: 'tap',
      screen: screen,
      elementId: elementId,
      x: position.dx / screenSize.width,
      y: position.dy / screenSize.height,
      timestamp: DateTime.now(),
    ));
  }

  static void trackScroll(String screen, double scrollDepth) {
    _buffer.add(HeatmapEvent(
      type: 'scroll',
      screen: screen,
      scrollDepth: scrollDepth.clamp(0.0, 1.0),
      timestamp: DateTime.now(),
    ));
  }

  static void trackTimeOnScreen(String screen, Duration duration) {
    AnalyticsService.track('screen_time', properties: {
      'screen': screen,
      'duration_ms': duration.inMilliseconds,
    });
  }

  static Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<HeatmapEvent>.from(_buffer);
    _buffer.clear();

    try {
      await SupabaseConfig.client.from('heatmaps').insert(batch.map((e) => e.toJson()).toList());
    } catch (_) {
      // Silently drop heatmap events on failure
    }
  }
}

/// Wraps a widget to track taps for heatmap analysis.
class TrackedWidget extends StatelessWidget {
  final String elementId;
  final Widget child;

  const TrackedWidget({super.key, required this.elementId, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final size = MediaQuery.sizeOf(context);
        final route = ModalRoute.of(context)?.settings.name ?? 'unknown';
        HeatmapTracker.trackTap(route, elementId, details.globalPosition, size);
      },
      child: child,
    );
  }
}
