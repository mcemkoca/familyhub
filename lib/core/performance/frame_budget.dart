import 'package:flutter/scheduler.dart';

/// 60 FPS frame budget helpers.
class FrameBudget {
  static const targetFrameTimeMs = 16.67; // 60 FPS

  static void ensureSmooth(VoidCallback heavyOperation) {
    final stopwatch = Stopwatch()..start();

    heavyOperation();

    final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
    if (elapsed > targetFrameTimeMs) {
      // In debug mode this could be reported to Sentry or DevTools.
      // ignore: avoid_print
      assert(() {
        // print('[FrameBudget] Frame drop: ${elapsed.toStringAsFixed(2)}ms');
        return true;
      }());
    }
  }

  /// Run heavy work in chunks, yielding to the UI thread between batches.
  static Future<void> chunked<T>({
    required List<T> items,
    required Future<void> Function(T item) process,
    required VoidCallback onProgress,
    int chunkSize = 10,
  }) async {
    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);

      await Future.wait(chunk.map(process));

      // Yield to UI thread
      await SchedulerBinding.instance.endOfFrame;
      onProgress();
    }
  }
}
