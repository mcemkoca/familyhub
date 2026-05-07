import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../domain/entities.dart';
import '../../../services/location_service.dart';
import '../../../services/hive_service.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _mapController = MapController();
  LatLng? _selectedLatLng;
  LocationModel? _locationInfo;
  bool _isLoadingAddress = false;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final saved = HiveService.getLocation();
    if (saved != null) {
      setState(() {
        _selectedLatLng = LatLng(saved.latitude, saved.longitude);
        _locationInfo = saved;
      });
    } else {
      await _goToCurrentLocation();
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    final pos = await LocationService.getCurrentPosition();
    setState(() => _isLoadingCurrentLocation = false);

    if (pos != null) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 16);
      await _onMapTapped(latLng);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).konumAlinamadiIzinleriKontrolEdin)),
        );
      }
    }
  }

  Future<void> _onMapTapped(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _isLoadingAddress = true;
      _locationInfo = null;
    });

    final location = await LocationService.getAddressFromCoords(
      latLng.latitude,
      latLng.longitude,
    );

    setState(() {
      _locationInfo = location;
      _isLoadingAddress = false;
    });
  }

  Future<void> _saveLocation() async {
    if (_locationInfo == null) return;

    await HiveService.saveLocation(_locationInfo!);
    await HiveService.saveUseCurrentLocation(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum kaydedildi: ${_locationInfo!.address}')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cloudWhite,
      appBar: ScreenHeader(
        title: 'Konum Seç',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLatLng ?? const LatLng(41.0082, 28.9784),
              initialZoom: _selectedLatLng != null ? 16 : 11,
              onTap: (_, latLng) => _onMapTapped(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familyhub.app',
              ),
              if (_selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLatLng!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.error,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Current location FAB
          Positioned(
            right: 16,
            bottom: _locationInfo != null ? 200 : 32,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              onPressed: _isLoadingCurrentLocation ? null : _goToCurrentLocation,
              backgroundColor: AppColors.cobalt,
              child: _isLoadingCurrentLocation
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Address bottom sheet
          if (_selectedLatLng != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cobalt.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.cobalt,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoadingAddress
                                    ? 'Adres aranıyor...'
                                    : (_locationInfo?.address.isNotEmpty == true
                                        ? _locationInfo!.address
                                        : 'Bilinmeyen Adres'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.dark,
                                ),
                              ),
                              if (!_isLoadingAddress && _locationInfo != null)
                                Text(
                                  '${_locationInfo!.city}${_locationInfo!.country.isNotEmpty ? ', ${_locationInfo!.country}' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.slate,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_locationInfo != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _locationInfo!.fullAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _locationInfo != null ? _saveLocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cobalt,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor: AppColors.cobalt.withAlpha(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Bu Konumu Kullan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
