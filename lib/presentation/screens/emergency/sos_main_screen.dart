// lib/presentation/screens/emergency/sos_main_screen.dart
// SOS main screen with panic button and quick categories

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../domain/models/emergency_action.dart';
import '../../../services/emergency_auto_actions_engine.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SosMainScreen extends StatefulWidget {
  const SosMainScreen({super.key});

  @override
  State<SosMainScreen> createState() => _SosMainScreenState();
}

class _SosMainScreenState extends State<SosMainScreen>
    with SingleTickerProviderStateMixin {
  final _engine = EmergencyAutoActionsEngine();
  bool _isHolding = false;
  bool _triggering = false;
  Timer? _holdTimer;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _onHoldComplete();
    });

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  // Basılı tutma başladı — 3 sn ilerleme + haptic geri bildirim.
  void _startHold() {
    if (_triggering) return;
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _progress
      ..reset()
      ..forward();
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(seconds: 3), _onHoldComplete);
  }

  // Parmak erken kalktı/iptal — sıfırla.
  void _cancelHold() {
    if (_triggering) return;
    setState(() => _isHolding = false);
    _holdTimer?.cancel();
    _progress.reset();
  }

  void _onHoldComplete() {
    if (_triggering) return;
    _triggering = true;
    _holdTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _isHolding = false);
    _triggerSOS(EmergencyCategory.accident);
  }

  void _triggerSOS(EmergencyCategory category, {String? description}) async {
    await _engine.triggerSOS(
      triggeredBy: 'current_user',
      triggerType: 'panic_button',
      description: description ?? category.name,
      category: category,
      initialSeverity: EmergencySeverity.high,
    );
    if (mounted) {
      _triggering = false;
      context.push(AppRoutes.sosActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).acilDurumSos),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panic button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTapDown: (_) => _startHold(),
                    onTapUp: (_) => _cancelHold(),
                    onTapCancel: _cancelHold,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                    // Basılı tutma ilerleme halkası (3 sn'de dolar).
                    SizedBox(
                      width: 236,
                      height: 236,
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, _) => CircularProgressIndicator(
                          value: _progress.value == 0 ? null : _progress.value,
                          strokeWidth: 6,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(
                            _isHolding ? Colors.redAccent : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isHolding ? Colors.red.shade700 : Colors.red.shade900,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(_isHolding ? 153 : 77),
                            blurRadius: _isHolding ? 40 : 20,
                            spreadRadius: _isHolding ? 10 : 5,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 64),
                          SizedBox(height: 8),
                          Text(
                            'KAZA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'BASILI TUT (3 sn)',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick categories
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).hizliSosKategorileri,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _categoryChip(Icons.local_hospital, 'SAĞLIK', Colors.red, EmergencyCategory.medical),
                        _categoryChip(Icons.car_crash, 'KAZA', Colors.red, EmergencyCategory.accident),
                        _categoryChip(Icons.fire_truck, 'YANGIN', Colors.orange, EmergencyCategory.fire),
                        _categoryChip(Icons.security, 'GÜVENLİK', Colors.amber, EmergencyCategory.security),
                        _categoryChip(Icons.flood, 'DOĞAL AFET', Colors.blue, EmergencyCategory.naturalDisaster),
                        _categoryChip(Icons.person, 'DİĞER', Colors.grey, EmergencyCategory.other),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recent history
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).sonSosGecmisi,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Henüz SOS kaydı yok.',
                      style: TextStyle(color: Colors.white70, fontSize: 13.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.sosSettings),
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      label: Text(AppLocalizations.of(context).sosAyarlari, style: const TextStyle(color: Colors.white70)),
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

  Widget _categoryChip(IconData icon, String label, Color color, EmergencyCategory category) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      onPressed: () => _triggerSOS(category),
    );
  }

}
