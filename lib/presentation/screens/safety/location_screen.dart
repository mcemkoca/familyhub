import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/constants.dart';
import '../../../services/location_service.dart';
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

    final granted = await LocationService.requestPermissions();
    if (!granted) {
      setState(() {
        _loading = false;
        _error = 'Konum izni verilmedi. Ayarlardan izin vermeniz gerekiyor.';
      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).canliKonum),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.cloudWhite,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.dark,
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
                color: isDark ? AppColors.darkCard : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFBAE6FD),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 280),
                    painter: _MapGridPainter(isDark: isDark),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        color: _isSharing
                            ? AppColors.success
                            : AppColors.cobalt,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isSharing
                              ? AppColors.success
                              : AppColors.cobalt,
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
                  Positioned(
                    top: 60,
                    right: 50,
                    child: _MemberPin(name: 'Üye 2', color: AppColors.pink),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 60,
                    child: _MemberPin(name: 'Üye 3', color: AppColors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Error or Coordinates
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(20)
                        : Colors.black.withAlpha(5),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mevcut Konumunuz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
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
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
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
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(20)
                        : Colors.black.withAlpha(5),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aile Üyeleri',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LocationRow(
                    name: 'Üye 1',
                    status: 'Evde',
                    color: AppColors.blue,
                    isOnline: true,
                  ),
                  const Divider(height: 24),
                  _LocationRow(
                    name: 'Üye 2',
                    status: 'İşte',
                    color: AppColors.pink,
                    isOnline: true,
                  ),
                  const Divider(height: 24),
                  _LocationRow(
                    name: 'Üye 3',
                    status: 'Okulda',
                    color: AppColors.orange,
                    isOnline: false,
                  ),
                ],
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
                      : AppColors.cobalt,
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
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? AppColors.darkBorder.withAlpha(40)
          : const Color(0xFFBAE6FD).withAlpha(60)
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

class _MemberPin extends StatelessWidget {
  final String name;
  final Color color;

  const _MemberPin({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_on, size: 32, color: color),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : Colors.white,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.success : AppColors.lightGray,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
