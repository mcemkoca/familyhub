import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../services/emergency_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _holding = false;
  double _progress = 0;

  void _startHold() {
    setState(() => _holding = true);
    _animateProgress();
  }

  void _cancelHold() {
    setState(() {
      _holding = false;
      _progress = 0;
    });
  }

  void _animateProgress() async {
    while (_holding && _progress < 1) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && _holding) {
        setState(() => _progress += 0.05);
      }
    }
    if (_progress >= 1 && _holding) {
      setState(() {
        _holding = false;
        _progress = 0;
      });
      _showEmergencySent();
    }
  }

  void _showEmergencySent() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.red), SizedBox(width: 8), Text(AppLocalizations.of(context).emergency)]),
        content: Text(AppLocalizations.of(context).emergencySent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).ok)),
        ],
      ),
    );
  }

  Future<void> _call112() async {
    HapticFeedback.heavyImpact();
    final ok = await EmergencyService.callEmergency();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).telefonUygulamasiAcilamiyor)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).emergency), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Acil Durum Butonu', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('Butona 3 saniye basılı tutarak acil durum bildirimi gönderebilirsin.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray)),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startHold(),
              onTapUp: (_) => _cancelHold(),
              onTapCancel: _cancelHold,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: _progress, strokeWidth: 8, backgroundColor: AppColors.red.withAlpha(30), valueColor: const AlwaysStoppedAnimation(AppColors.red)),
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.red, Color(0xFFFBBF24)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.red, blurRadius: 30, offset: Offset(0, 10))]),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sos, color: Colors.white, size: 48), SizedBox(height: 8), Text('SOS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _call112,
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text('112 Ara', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }
}
