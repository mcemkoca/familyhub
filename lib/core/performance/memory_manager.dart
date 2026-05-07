import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

/// Central registry for subscriptions, timers, and stream controllers.
/// Prevents memory leaks by tracking and disposing resources.
class MemoryManager {
  static final _subscriptions = <String, StreamSubscription>{};
  static final _timers = <String, Timer>{};
  static final _controllers = <String, StreamController>{};

  static void registerSubscription(String id, StreamSubscription sub) {
    _subscriptions[id]?.cancel();
    _subscriptions[id] = sub;
  }

  static void registerTimer(String id, Timer timer) {
    _timers[id]?.cancel();
    _timers[id] = timer;
  }

  static void registerController(String id, StreamController ctrl) {
    _controllers[id]?.close();
    _controllers[id] = ctrl;
  }

  static void dispose(String id) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);

    _timers[id]?.cancel();
    _timers.remove(id);

    _controllers[id]?.close();
    _controllers.remove(id);
  }

  static void disposeAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    for (final timer in _timers.values) {
      timer.cancel();
    }
    for (final ctrl in _controllers.values) {
      ctrl.close();
    }

    _subscriptions.clear();
    _timers.clear();
    _controllers.clear();
  }

  static void logMemoryUsage() {
    developer.postEvent('Flutter.Memory', {
      'timestamp': DateTime.now().toIso8601String(),
      'subscriptions': _subscriptions.length,
      'timers': _timers.length,
      'controllers': _controllers.length,
    });
  }
}

/// Mixin for StatefulWidget to auto-dispose registered resources.
mixin AutoDisposeMixin<T extends StatefulWidget> on State<T> {
  final _disposables = <String>{};

  void autoDispose(String id) {
    _disposables.add(id);
  }

  @override
  void dispose() {
    for (final id in _disposables) {
      MemoryManager.dispose(id);
    }
    super.dispose();
  }
}
