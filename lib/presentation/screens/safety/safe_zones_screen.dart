import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../domain/models/safety_models.dart';
import '../../../services/safe_zone_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key});

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  List<Map<String, dynamic>> _zoneStatus = [];
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkZones();
  }

  Future<void> _checkZones() async {
    final status = await SafeZoneService.checkAllZones();
    setState(() {
      _zoneStatus = status;
      _checking = false;
    });
  }

  IconData _iconForType(SafeZoneType type) {
    return switch (type) {
      SafeZoneType.home => Icons.home,
      SafeZoneType.work => Icons.work,
      SafeZoneType.school => Icons.school,
      SafeZoneType.danger => Icons.warning,
      SafeZoneType.custom => Icons.place,
    };
  }

  Color _colorForType(SafeZoneType type) {
    return switch (type) {
      SafeZoneType.home => const Color(0xFF6366F1),
      SafeZoneType.work => const Color(0xFF8B5CF6),
      SafeZoneType.school => const Color(0xFF10B981),
      SafeZoneType.danger => AppColors.error,
      SafeZoneType.custom => AppColors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).guvenliBolgeler),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _checkZones,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Geofence aktif bölgelerinizi yönetin ve konum durumunu kontrol edin.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            if (_checking)
              const Center(child: CircularProgressIndicator())
            else
              ..._zoneStatus.map((item) {
                final zone = item['zone'] as SafeZone;
                final inside = item['inside'] as bool;
                final distance = item['distance'] as double;
                final color = _colorForType(zone.type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconForType(zone.type), color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  zone.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (zone.address != null)
                                  Text(
                                    zone.address!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: inside
                                  ? const Color(0xFF10B981).withAlpha(30)
                                  : const Color(0xFFF59E0B).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              inside ? 'İçerde' : 'Dışarda',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: inside ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.radar, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text('Çap: ${zone.radiusMeters.toInt()}m'),
                          const SizedBox(width: 16),
                          Icon(Icons.social_distance, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text('Mesafe: ${distance < 1000 ? '${distance.round()}m' : '${(distance / 1000).toStringAsFixed(1)}km'}'),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yeni bölge ekleme yakında geliyor (harita seçici)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).yeniBolgeEkle),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
