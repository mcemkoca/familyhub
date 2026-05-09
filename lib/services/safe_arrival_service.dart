import 'dart:async';
import '../core/supabase_client.dart';

import '../repositories/safe_arrival_repository.dart';
import '../services/child_auth_service.dart';

/// Real-time safe arrival / ETA monitoring backed by Supabase.
/// All monitors are persisted to `safe_arrivals` table and broadcast
/// via realtime to every family member.
class SafeArrivalService {
  static final _repo = SafeArrivalRepository();
  static final _client = SupabaseConfig.client;
  static Timer? _timer;
  static StreamSubscription<dynamic>? _realtimeSub;

  static final _activeController = StreamController<List<ArrivalMonitor>>.broadcast();
  static final _historyController = StreamController<List<ArrivalMonitor>>.broadcast();

  static Stream<List<ArrivalMonitor>> get activeStream => _activeController.stream;
  static Stream<List<ArrivalMonitor>> get historyStream => _historyController.stream;

  static List<ArrivalMonitor> _activeMonitors = [];
  static List<ArrivalMonitor> _history = [];

  static List<ArrivalMonitor> get activeMonitors => _activeMonitors;
  static List<ArrivalMonitor> get history => _history;

  // ═══════════════════════════════════════════════════════════════════════════
  // START / STOP
  // ═══════════════════════════════════════════════════════════════════════════

  static void startMonitoring() {
    if (_timer != null) return;
    _loadData();
    _startRealtimeListener();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateMonitors();
    });
  }

  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  static void dispose() {
    stopMonitoring();
    _activeController.close();
    _historyController.close();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _loadData() async {
    try {
      final active = await _repo.getActiveMonitors();
      final hist = await _repo.getHistory();
      _activeMonitors = active.map(_fromJson).toList();
      _history = hist.map(_fromJson).toList();
      _emit();
    } catch (e) {
      // Keep previous data on error
    }
  }

  static void _emit() {
    _activeController.add(List.unmodifiable(_activeMonitors));
    _historyController.add(List.unmodifiable(_history));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME
  // ═══════════════════════════════════════════════════════════════════════════

  static void _startRealtimeListener() async {
    _realtimeSub?.cancel();
    String? familyId;
    final user = _client.auth.currentUser;
    if (user != null) {
      final profile = await _client.from('profiles').select('family_id').eq('id', user.id).maybeSingle();
      familyId = profile?['family_id'] as String?;
    }
    familyId ??= ChildAuthService.currentFamilyId;
    if (familyId == null) return;

    _realtimeSub = _client
        .from('safe_arrivals')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .listen((rows) {
      final all = rows.map(_fromJson).toList();
      _activeMonitors = all.where((m) => m.status == 'active' || m.status == 'delayed').toList();
      _history = all.where((m) => m.status == 'arrived' || m.status == 'cancelled').toList();
      _emit();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<ArrivalMonitor> startMonitor({
    required String memberId,
    required String memberName,
    required String destination,
    required int durationMinutes,
  }) async {
    final raw = await _repo.createMonitor(
      memberId: memberId,
      memberName: memberName,
      destination: destination,
      durationMinutes: durationMinutes,
    );
    final monitor = _fromJson(raw);
    _activeMonitors = [monitor, ..._activeMonitors];
    _emit();
    startMonitoring();
    return monitor;
  }

  static Future<void> cancelMonitor(String id) async {
    await _repo.cancelMonitor(id);
    final idx = _activeMonitors.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final m = _activeMonitors[idx];
      _activeMonitors = List.from(_activeMonitors)..removeAt(idx);
      _history = [m.copyWith(status: 'cancelled'), ..._history];
      _emit();
    }
  }

  static Future<void> _updateMonitors() async {
    final now = DateTime.now();
    for (final m in _activeMonitors.where((m) => m.status == 'active')) {
      final elapsed = now.difference(m.startedAt).inMinutes;
      final progress = (elapsed / m.durationMinutes).clamp(0.0, 1.0);

      if (elapsed >= m.durationMinutes) {
        // Arrived
        await _repo.markArrived(m.id);
      } else if (elapsed > m.durationMinutes + 5) {
        // Delayed
        await _repo.markDelayed(m.id, elapsed - m.durationMinutes);
      } else {
        // Update progress
        await _repo.updateProgress(m.id, progress);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static ArrivalMonitor _fromJson(Map<String, dynamic> json) {
    return ArrivalMonitor(
      id: json['id'] as String,
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String,
      destination: json['destination'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      estimatedArrival: DateTime.parse(json['estimated_arrival'] as String),
      actualArrival: json['actual_arrival'] != null ? DateTime.parse(json['actual_arrival'] as String) : null,
      durationMinutes: json['duration_minutes'] as int,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      delayMinutes: json['delay_minutes'] as int?,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODEL
// ═════════════════════════════════════════════════════════════════════════════

class ArrivalMonitor {
  final String id;
  final String memberId;
  final String memberName;
  final String destination;
  final DateTime startedAt;
  final DateTime estimatedArrival;
  final DateTime? actualArrival;
  final int durationMinutes;
  double progress;
  String status;
  int? delayMinutes;

  ArrivalMonitor({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.destination,
    required this.startedAt,
    required this.estimatedArrival,
    this.actualArrival,
    required this.durationMinutes,
    this.progress = 0.0,
    this.status = 'active',
    this.delayMinutes,
  });

  ArrivalMonitor copyWith({
    String? status,
    double? progress,
    DateTime? actualArrival,
    int? delayMinutes,
  }) {
    return ArrivalMonitor(
      id: id,
      memberId: memberId,
      memberName: memberName,
      destination: destination,
      startedAt: startedAt,
      estimatedArrival: estimatedArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      durationMinutes: durationMinutes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      delayMinutes: delayMinutes ?? this.delayMinutes,
    );
  }
}