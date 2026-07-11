import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../domain/entities.dart';
import '../../../domain/models/safety_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/emergency_service.dart';
import '../../../services/location_service.dart';
import '../../../services/location_tracking_service.dart';
import '../../../services/safety_service.dart';
import '../../widgets/safety/sos_button.dart';
import '../../widgets/safety/quick_action_button.dart';
import '../../widgets/safety/family_safety_status.dart';
import '../../widgets/safety/safety_tools_section.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with WidgetsBindingObserver {
  bool _sosActive = false;
  double _sosProgress = 0;
  Timer? _sosTimer;
  DateTime? _sosStartTime;

  Position? _currentLocation;
  LocationModel? _currentAddress;
  bool _locationSharing = false;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<SafetyAlert>? _alertSub;
  List<SafetyAlert> _alerts = [];
  Timer? _locationRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
    _startLocationRefresh();
    LocationTrackingService.startTracking();
    SafetyService.startMonitoring();
    _alertSub = SafetyService.alertStream.listen((alert) {
      if (mounted) {
        setState(() => _alerts = [alert, ..._alerts]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛡️ ${alert.message}'),
            backgroundColor: alert.severity == AlertSeverity.critical
                ? AppColors.error
                : const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _initLocation() async {
    final granted = await LocationService.requestPermissionsWithFallback(
      onDeniedForever: () async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).sfLocationDenied),
            backgroundColor: const Color(0xFF13131A),
            action: SnackBarAction(
              label: AppLocalizations.of(context).sfSettings,
              textColor: const Color(0xFF6366F1),
              onPressed: openAppSettings,
            ),
          ),
        );
      },
    );
    if (granted) {
      final pos = await LocationService.getCurrentLocation();
      final addr = await LocationService.getCurrentAddress();
      if (mounted) {
        setState(() {
          _currentLocation = pos;
          _currentAddress = addr;
        });
      }
    }
  }

  void _startLocationRefresh() {
    _locationRefreshTimer?.cancel();
    _locationRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLocationSilent();
    });
  }

  Future<void> _refreshLocationSilent() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      final addr = await LocationService.getCurrentAddress();
      if (mounted) {
        setState(() {
          _currentLocation = pos;
          _currentAddress = addr;
        });
      }
    } catch (e) { debugPrint('Safety screen error: $e'); }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosTimer?.cancel();
    _locationSub?.cancel();
    _alertSub?.cancel();
    _locationRefreshTimer?.cancel();
    LocationTrackingService.stopTracking();
    super.dispose();
  }

  // SOS Handlers
  void _handleSOSPressIn() {
    if (_sosActive) return;
    setState(() => _sosProgress = 0);

    _sosStartTime = DateTime.now();
    _sosTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(_sosStartTime!).inMilliseconds;
      final progress = (elapsed / 3000).clamp(0.0, 1.0);

      if (mounted) setState(() => _sosProgress = progress);

      // Haptic every 500ms
      if (elapsed % 500 < 60) {
        HapticFeedback.lightImpact();
      }

      if (progress >= 1.0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  void _handleSOSPressOut() {
    if (_sosActive) return;
    _sosTimer?.cancel();
    if (mounted) setState(() => _sosProgress = 0);
  }

  Future<void> _activateSOS() async {
    setState(() {
      _sosActive = true;
      _sosProgress = 0;
    });

    // SOS vibration pattern: ... --- ...
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();

    final location = await LocationService.getCurrentLocation();
    setState(() => _currentLocation = location);

    final user = AuthService.currentUser;
    final userName = user?.userMetadata?['display_name'] as String? ?? 'Kullanıcı';
    final familyId = AuthService.currentUser?.userMetadata?['family_id'] as String?;
    if (familyId != null && familyId.isNotEmpty) {
      await EmergencyService.triggerSOS(
        familyId: familyId,
        senderId: AuthService.currentUserId ?? '',
        senderName: userName,
        senderType: 'parent',
        location: location,
        message: '$userName acil durum butonunu kullandı!',
      );
    }
    await EmergencyService.sendSOSAlert(
      userName: userName,
      location: location,
      message: '$userName acil durum butonunu kullandı!',
    );

    // Start live location sharing
    _toggleLocationSharing(force: true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).sfEmergencyActive),
            ],
          ),
          content: const Text(
            'Aile üyelerine bildirim gönderildi. Canlı konum paylaşılıyor.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _callEmergency();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('112 Ara'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).sfUpdateLocation),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelSOS();
              },
              child: Text(AppLocalizations.of(context).iptalEt),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cancelSOS() async {
    setState(() {
      _sosActive = false;
      _sosProgress = 0;
    });

    _toggleLocationSharing(force: false);

    final user = AuthService.currentUser;
    final userName = user?.userMetadata?['display_name'] as String? ?? 'Kullanıcı';
    await EmergencyService.sendSOSCancel(
      userName: userName,
      familyId: AuthService.currentUserId ?? '',
      message: '$userName acil durumu iptal etti.',
    );

    HapticFeedback.heavyImpact();
  }

  // Location
  Future<void> _toggleLocationSharing({bool? force}) async {
    final newValue = force ?? !_locationSharing;
    if (newValue == _locationSharing) return;

    setState(() => _locationSharing = newValue);

    if (newValue) {
      LocationService.startLiveSharing();
      _locationSub = LocationService.locationStream.listen((pos) async {
        if (mounted) setState(() => _currentLocation = pos);
        try {
          final addr = await LocationService.getAddressFromCoords(
            pos.latitude,
            pos.longitude,
          );
          if (mounted) setState(() => _currentAddress = addr);
        } catch (e) { debugPrint('Safety screen error: $e'); }
      });
    } else {
      LocationService.stopLiveSharing();
      await _locationSub?.cancel();
      _locationSub = null;
    }
  }

  // Emergency Call
  Future<void> _callEmergency() async {
    final ok = await EmergencyService.callEmergency();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).telefonUygulamasiAcilamiyor)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final safeTop = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: safeTop > 0 ? 8 : 16)),
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).safety,
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context).ailenizinKorumaKalkani,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // SOS Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Acil Durum Butonu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sosActive
                          ? 'Acil durum aktif — aile bilgilendirildi'
                          : 'Butona 3 saniye basılı tutun',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SOSButton(
                      active: _sosActive,
                      progress: _sosProgress,
                      onPressIn: _handleSOSPressIn,
                      onPressOut: _handleSOSPressOut,
                      onCancel: _cancelSOS,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Live Status Bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(16),
                  border: _locationSharing
                      ? Border.all(
                          color: const Color(0xFF10B981).withAlpha(80), width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _locationSharing
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).canliKonum,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _locationSharing
                                ? const Color(0xFF10B981)
                                : (const Color(0xFFE5E7EB)),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _locationSharing
                                ? const Color(0xFF10B981)
                                : const Color(0xFF9CA3AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _locationSharing ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _locationSharing
                                ? const Color(0xFF10B981)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_currentAddress != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentAddress!.fullAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_currentLocation?.latitude.toStringAsFixed(4) ?? '-'}, '
                            'Lng: ${_currentLocation?.longitude.toStringAsFixed(4) ?? '-'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(AppLocalizations.of(context).konumAliniyor,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Real-time family status loaded via SafetyService.stream
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(AppLocalizations.of(context).hizliIslemler,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    QuickActionButton(
                      icon: Icons.location_on_outlined,
                      iconBg: const Color(0xFF6366F1).withAlpha(30),
                      iconColor: const Color(0xFF6366F1),
                      label: AppLocalizations.of(context).konumumuPaylas,
                      description: _locationSharing
                          ? 'Canlı konum aktif'
                          : 'Canlı konum gönder',
                      isActive: _locationSharing,
                      pulse: _locationSharing,
                      onPress: () => _toggleLocationSharing(),
                    ),
                    const SizedBox(height: 12),
                    QuickActionButton(
                      icon: Icons.call,
                      iconBg: const Color(0xFF10B981).withAlpha(30),
                      iconColor: const Color(0xFF10B981),
                      label: "112'yi Ara",
                      description: AppLocalizations.of(context).acilCagriMerkezi,
                      danger: true,
                      onPress: _callEmergency,
                    ),
                    const SizedBox(height: 12),
                    QuickActionButton(
                      icon: Icons.health_and_safety_outlined,
                      iconBg: const Color(0xFF8B5CF6).withAlpha(30),
                      iconColor: const Color(0xFF7C3AED),
                      label: AppLocalizations.of(context).saglikKartim,
                      description: AppLocalizations.of(context).alerjiVeIlacBilgileri,
                      badge: 'Güncel',
                      onPress: () => context.push(AppRoutes.healthCard),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Family Safety Status
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FamilySafetyStatus(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Safety Tools
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SafetyToolsSection(
                  tools: [
                    SafetyTool(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF6366F1),
                      label: AppLocalizations.of(context).guvenliBolgeler,
                      description: AppLocalizations.of(context).evOkulIsIcinGeofence,
                      onTap: () => context.push(AppRoutes.safeZones),
                    ),
                    SafetyTool(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF10B981),
                      label: AppLocalizations.of(context).guvenliVaris,
                      description: AppLocalizations.of(context).belirliSuredeVarisKontrolu,
                      onTap: () => context.push(AppRoutes.safeArrival),
                    ),
                    SafetyTool(
                      icon: Icons.mic_none,
                      iconColor: const Color(0xFFF59E0B),
                      label: AppLocalizations.of(context).sfAmbientListen,
                      description: AppLocalizations.of(context).acilDurumdaSesKaydi,
                      onTap: () => context.push(AppRoutes.ambientListening),
                    ),
                    SafetyTool(
                      icon: Icons.flashlight_on_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      label: AppLocalizations.of(context).sfFlashlight,
                      description: AppLocalizations.of(context).telefonFeneriniAc,
                      onTap: () => context.push(AppRoutes.flashlight),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            // Bottom padding for safe area + nav
            SliverToBoxAdapter(
              child: SizedBox(height: safeBottom + 120),
            ),
          ],
        ),
      ),
    );
  }
}
