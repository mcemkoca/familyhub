import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/supabase_client.dart';

class SyncOperation {
  final String id;
  final String table;
  final String operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'operation': operation,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'retry_count': retryCount,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    table: json['table'] as String,
    operation: json['operation'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    createdAt: DateTime.parse(json['created_at'] as String),
    retryCount: (json['retry_count'] as int?) ?? 0,
  );
}

class SyncService {
  static late Box<dynamic> _queueBox;
  static late Box<dynamic> _cacheBox;
  static bool _isSyncing = false;
  static StreamSubscription<dynamic>? _connectivitySub;
  static Timer? _periodicSyncTimer;

  static Future<Box<dynamic>> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<dynamic>(name);
    }
    return await Hive.openBox<dynamic>(name);
  }

  static Future<void> initialize() async {
    _queueBox = await _openBox('sync_queue');
    _cacheBox = await _openBox('sync_cache');
    _listenConnectivity();
    startPeriodicSync();
  }

  static void _listenConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (hasNet) sync();
    });
  }

  static void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) => sync());
  }

  static void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  static Future<void> queue({
    required String table,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final op = SyncOperation(
      id: '${table}_${operation}_${DateTime.now().millisecondsSinceEpoch}',
      table: table,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    await _queueBox.put(op.id, op.toJson());

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isNotEmpty && !connectivity.contains(ConnectivityResult.none)) {
      await sync();
    }
  }

  static Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final operations = _queueBox.values
          .map((v) => SyncOperation.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final op in operations) {
        try {
          await _executeRemote(op);
          await _queueBox.delete(op.id);
        } catch (e) {
          op.retryCount++;
          if (op.retryCount >= 5) {
            await _handlePermanentFailure(op);
            await _queueBox.delete(op.id);
          } else {
            // Exponential backoff: wait longer before next retry
            await _queueBox.put(op.id, op.toJson());
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _executeRemote(SyncOperation op) async {
    final supabase = SupabaseConfig.safeClient;
    if (supabase == null) throw StateError('Supabase not initialized');

    switch (op.operation) {
      case 'insert':
        await supabase.from(op.table).insert(op.data);
        break;
      case 'update':
        await supabase.from(op.table).update(op.data).eq('id', op.data['id'] as Object);
        break;
      case 'delete':
        await supabase.from(op.table).delete().eq('id', op.data['id'] as Object);
        break;
    }
  }

  static Future<void> _handlePermanentFailure(SyncOperation op) async {
    await _cacheBox.put('failed_${op.id}', op.toJson());
  }

  static Future<void> cache<T>(
    String key,
    T data, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    await _cacheBox.put(key, {
      'data': data,
      'expires_at': DateTime.now().add(ttl).millisecondsSinceEpoch,
    });
  }

  static Future<void> dispose() async {
    _connectivitySub?.cancel();
    _periodicSyncTimer?.cancel();
  }

  static Future<T?> getCached<T>(String key) async {
    final entry = _cacheBox.get(key);
    if (entry == null) return null;

    final map = entry as Map<dynamic, dynamic>;
    final expiresAt = map['expires_at'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await _cacheBox.delete(key);
      return null;
    }

    return map['data'] as T?;
  }
}
