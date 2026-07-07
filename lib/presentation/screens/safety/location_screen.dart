import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/constants.dart';
import '../../../services/location_service.dart';
import '../../providers/app_providers.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isSharing = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final granted = await LocationService.requestPermissionsWithFallback(
      onDeniedForever: () async {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF13131A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x1EFFFFFF), width: 0.5),
            ),
            title: const Row(children: [
              Icon(Icons.location_off, color: Color(0xFFF59E0B)),
              SizedBox(width: 12),
              Text('Konum İzni Gerekli', style: TextStyle(color: Color(0xFFE5E7EB))),
            ]),
            content: const Text(
              'Konum izni kalıcı olarak reddedildi. Ayarlar > Uygulamalar > FamilyHub > İzinler > Konum menüsünden izni etkinleştirin.',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat', style: TextStyle(color: Color(0xFF6B7280))),
              ),
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); openAppSettings(); },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ayarları Aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!granted) {
      setState(() { _loading = false; _error = 'Konum izni verilmedi.'; });
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _loading = false;
          if (pos == null) {
            _error = 'Konum alınamadı. GPS açık olduğundan emin olun.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Konum alınırken hata oluşu: $e';
        });
      }
    }
  }

  void _startSharing() {
    try {
      LocationService.startLiveSharing();
      _positionStream = LocationService.locationStream.listen(
        (pos) {
          if (mounted) setState(() => _currentPosition = pos);
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isSharing = false;
              _error = 'Canlı konum paylaşımında hata: $e';
            });
          }
        },
      );
      setState(() => _isSharing = true);
    } catch (e) {
      setState(() => _error = 'Konum paylaşımı başlatılamadı: $e');
    }
  }

  void _stopSharing() {
    LocationService.stopLiveSharing();
    _positionStream?.cancel();
    setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).canliKonum),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        actions: [
          if (_error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initLocation,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map Placeholder
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x1EFFFFFF),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CustomPaint(
                    size: Size(double.infinity, 280),
                    painter: _MapGridPainter(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        color: _isSharing
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isSharing
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Error or Coordinates
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Mevcut Konumunuz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_loading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).konumAliniyor),
                      ],
                    )
                  else ...[
                    _CoordRow(
                      label: 'Enlem',
                      value:
                          _currentPosition?.latitude.toStringAsFixed(6) ?? '-',
                      icon: Icons.north,
                    ),
                    const SizedBox(height: 12),
                    _CoordRow(
                      label: 'Boylam',
                      value:
                          _currentPosition?.longitude.toStringAsFixed(6) ?? '-',
                      icon: Icons.east,
                    ),
                    const SizedBox(height: 12),
                    _CoordRow(
                      label: 'Doğruluk',
                      value: _currentPosition?.accuracy != null
                          ? '${_currentPosition!.accuracy.toStringAsFixed(1)} m'
                          : '-',
                      icon: Icons.gps_fixed,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Family Members List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final members = ref.watch(familyMembersProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aile Üyeleri',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (members.isEmpty)
                        const Text(
                          'Henüz aile üyesi yok. Üye ekleyip konum paylaşımını '
                          'açtığınızda burada görünürler.',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13.5),
                        )
                      else
                        for (var i = 0; i < members.length; i++) ...[
                          if (i > 0) const Divider(height: 24),
                          _LocationRow(
                            name: members[i].name,
                            status: members[i].isOnline
                                ? 'Çevrimiçi'
                                : 'Çevrimdışı',
                            color: members[i].color,
                            isOnline: members[i].isOnline,
                          ),
                        ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Share Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _error != null && _error!.contains('izin')
                    ? null
                    : (_isSharing ? _stopSharing : _startSharing),
                icon: Icon(
                  _isSharing ? Icons.location_off : Icons.location_on,
                  color: Colors.white,
                ),
                label: Text(
                  _isSharing
                      ? 'Konum Paylaşımını Durdur'
                      : 'Canlı Konum Paylaş',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing
                      ? AppColors.error
                      : const Color(0xFF6366F1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1EFFFFFF).withAlpha(40)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CoordRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String name;
  final String status;
  final Color color;
  final bool isOnline;

  const _LocationRow({
    required this.name,
    required this.status,
    required this.color,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF13131A),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE5E7EB),
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
