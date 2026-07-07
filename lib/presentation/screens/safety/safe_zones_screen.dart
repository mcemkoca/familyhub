import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../domain/models/safety_models.dart';
import '../../../services/safe_zone_service.dart';
import '../../../services/location_service.dart';
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

  Future<void> _showAddZoneSheet() async {
    final nameCtrl = TextEditingController();
    var type = SafeZoneType.home;
    var radius = 150.0;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF13131A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Güvenli Bölge Ekle',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Şu anki konumun merkez alınır.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Bölge adı',
                    hintText: 'Örn: Ev, Okul, İş',
                    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A24),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF262631)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Tür',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SafeZoneType.values.map((t) {
                    final sel = type == t;
                    return GestureDetector(
                      onTap: () => setSheet(() => type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                              ? _colorForType(t)
                              : const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? _colorForType(t)
                                  : const Color(0xFF262631)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_iconForType(t),
                              size: 16,
                              color:
                                  sel ? Colors.white : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 6),
                          Text(_zoneTypeLabel(t),
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFFD1D5DB),
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('Yarıçap: ${radius.round()} m',
                    style: const TextStyle(color: Color(0xFFD1D5DB))),
                Slider(
                  value: radius,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => setSheet(() => radius = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Lütfen bölge adı girin')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kaydet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Konum alınamadı. GPS açık olmalı.')));
      return;
    }
    await SafeZoneService.addZone(SafeZone(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtrl.text.trim(),
      type: type,
      latitude: pos.latitude,
      longitude: pos.longitude,
      radiusMeters: radius,
    ));
    if (mounted) {
      setState(() {});
      messenger.showSnackBar(
        SnackBar(content: Text('${nameCtrl.text.trim()} eklendi')),
      );
    }
  }

  String _zoneTypeLabel(SafeZoneType t) => switch (t) {
        SafeZoneType.home => 'Ev',
        SafeZoneType.work => 'İş',
        SafeZoneType.school => 'Okul',
        SafeZoneType.danger => 'Tehlike',
        SafeZoneType.custom => 'Diğer',
      };

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
              onPressed: _showAddZoneSheet,
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
