import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../../../../services/child_auth_service.dart';
import '../../../../services/emergency_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/location_tracking_service.dart';
import '../../../widgets/safety/family_safety_status.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class ChildSafetyTab extends StatefulWidget {
  const ChildSafetyTab({super.key});

  @override
  State<ChildSafetyTab> createState() => _ChildSafetyTabState();
}

class _ChildSafetyTabState extends State<ChildSafetyTab> {
  bool _sosHolding = false;
  double _sosProgress = 0;
  bool _sharingLocation = false;
  bool _locationLoading = false;
  List<Map<String, dynamic>> _activeAlerts = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sosSub;

  @override
  void initState() {
    super.initState();
    _listenToFamilySOS();
    _loadActiveAlerts();
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    super.dispose();
  }

  void _listenToFamilySOS() {
    final familyId = ChildAuthService.currentFamilyId;
    if (familyId == null) return;
    _sosSub = EmergencyService.listenToFamilySOS(familyId).listen((rows) {
      if (mounted) {
        setState(
          () => _activeAlerts = rows
              .where((r) => r['status'] == 'active')
              .toList(),
        );
      }
    });
  }

  Future<void> _loadActiveAlerts() async {
    final familyId = ChildAuthService.currentFamilyId;
    if (familyId == null) return;
    final alerts = await EmergencyService.getActiveAlerts(familyId);
    if (mounted) setState(() => _activeAlerts = alerts);
  }

  void _startSOSHold() {
    setState(() => _sosHolding = true);
    _animateSOSProgress();
  }

  void _cancelSOSHold() {
    setState(() {
      _sosHolding = false;
      _sosProgress = 0;
    });
  }

  void _animateSOSProgress() async {
    while (_sosHolding && _sosProgress < 1) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && _sosHolding) {
        setState(() => _sosProgress += 0.05);
      }
    }
    if (_sosProgress >= 1 && _sosHolding) {
      setState(() {
        _sosHolding = false;
        _sosProgress = 0;
      });
      _triggerSOS();
    }
  }

  Future<void> _triggerSOS() async {
    final session = ChildAuthService.currentSession;
    if (session == null) return;

    final pos = await LocationService.getCurrentLocation().catchError(
      (_) => null,
    );

    try {
      await EmergencyService.triggerSOS(
        familyId: session.familyId,
        senderId: session.childId,
        senderName: session.childName,
        senderType: 'child',
        location: pos,
        message: 'Çocuk acil durum butonuna bastı!',
      );
    } catch (e) { debugPrint('Child safety tab error: $e'); }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.red),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).emergency),
            ],
          ),
          content: Text(AppLocalizations.of(context).emergencySent,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _locationLoading = true);
    try {
      final granted = await LocationService.requestPermissionsWithFallback(
        onDeniedForever: () async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum izni kalıcı reddedildi.'),
              backgroundColor: Color(0xFF13131A),
              action: SnackBarAction(
                label: 'Ayarlar',
                textColor: Color(0xFF6366F1),
                onPressed: openAppSettings,
              ),
            ),
          );
        },
      );
      if (!granted) return;
      final ok = await LocationTrackingService.shareCurrentLocation();
      setState(() => _sharingLocation = ok);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? '📍 Konumun ailene paylaşıldı' : 'Konum paylaşılamadı',
            ),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Konum paylaşılamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SOS Butonu
          _buildSOSCard(),
          const SizedBox(height: 20),

          // Hızlı İşlemler
          _buildQuickActions(),
          const SizedBox(height: 20),

          // Aktif Aile Uyarıları
          if (_activeAlerts.isNotEmpty) ...[
            _buildActiveAlerts(),
            const SizedBox(height: 20),
          ],

          // Aile Güvenlik Durumu (canlı konumlar)
          const FamilySafetyStatus(),
          const SizedBox(height: 20),

          // Sağlık Kartım
          _buildHealthCard(),
          const SizedBox(height: 20),

          // 112 Ara
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _call112,
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text(
                '112\'yi Ara',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Acil Durum Butonu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).butona3SaniyeBasiliTut,
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _startSOSHold(),
            onTapUp: (_) => _cancelSOSHold(),
            onTapCancel: _cancelSOSHold,
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _sosProgress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.red.withAlpha(30),
                    valueColor: const AlwaysStoppedAnimation(AppColors.red),
                  ),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.red, Color(0xFFFBBF24)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.red,
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sos, color: Colors.white, size: 40),
                          SizedBox(height: 4),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).basiliTut,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).hizliIslemler,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _locationLoading ? null : _shareLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _locationLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.location_on, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).konumumuPaylas,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _sharingLocation
                            ? 'Son konum paylaşıldı'
                            : 'Canlı konumun ailene gönder',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push(AppRoutes.safeArrival),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer, color: Colors.orange),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).guvenliVaris,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(AppLocalizations.of(context).aileVarisPlanlariniGor,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).aktifUyarilar,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.red.shade300,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ..._activeAlerts.map(
          (alert) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (alert['sender_name'] as String?) ?? 'Bilinmeyen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(AppLocalizations.of(context).aktif,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (alert['message'] as String?) ?? 'Acil durum!',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
                if (alert['lat'] != null && alert['lng'] != null)
                  Text(
                    'Konum: ${(alert['lat'] as num).toStringAsFixed(4)}, ${(alert['lng'] as num).toStringAsFixed(4)}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard() {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.healthCard);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite, color: Colors.teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).saglikKartim,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(AppLocalizations.of(context).alerjiVeSaglikBilgilerin,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
