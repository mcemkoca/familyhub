import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../domain/entities.dart';

class LocationService {
  static Stream<Position>? _locationStream;

  static Future<LocationPermissionStatus> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  static Future<bool> requestPermissions() async {
    final status = await checkPermission();
    return status == LocationPermissionStatus.granted;
  }

  /// Returns true if granted, false if denied.
  /// Calls [onDeniedForever] when permanently denied so the caller can show
  /// an "Open Settings" dialog without duplicating Geolocator logic.
  static Future<bool> requestPermissionsWithFallback({
    required Future<void> Function() onDeniedForever,
  }) async {
    final status = await checkPermission();
    if (status == LocationPermissionStatus.granted) return true;
    if (status == LocationPermissionStatus.deniedForever) {
      await onDeniedForever();
    }
    return false;
  }

  static Future<LocationModel?> getCurrentAddress() async {
    final status = await checkPermission();
    if (status != LocationPermissionStatus.granted) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );

    return getAddressFromCoords(pos.latitude, pos.longitude);
  }

  static Future<LocationModel?> getAddressFromCoords(double lat, double lon) async {
    try {
      final placemarks = await compute(
        _placemarkFromCoordinates,
        (lat, lon),
      );
      if (placemarks.isEmpty) return null;

      final pm = placemarks.first;
      final addressParts = <String>[];
      if (pm.thoroughfare != null && pm.thoroughfare!.isNotEmpty) {
        addressParts.add(pm.thoroughfare!);
      }
      if (pm.subThoroughfare != null && pm.subThoroughfare!.isNotEmpty) {
        addressParts.add(pm.subThoroughfare!);
      }
      if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
        addressParts.add(pm.subLocality!);
      }

      final address = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : (pm.locality ?? '');

      final fullParts = <String>[];
      if (pm.thoroughfare != null && pm.thoroughfare!.isNotEmpty) {
        fullParts.add('${pm.thoroughfare} ${pm.subThoroughfare ?? ''}'.trim());
      }
      if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
        fullParts.add(pm.subLocality!);
      }
      if (pm.locality != null && pm.locality!.isNotEmpty) {
        fullParts.add(pm.locality!);
      }
      if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) {
        fullParts.add(pm.administrativeArea!);
      }
      if (pm.country != null && pm.country!.isNotEmpty) {
        fullParts.add(pm.country!);
      }

      return LocationModel(
        latitude: lat,
        longitude: lon,
        address: address,
        city: pm.locality ?? pm.administrativeArea ?? '',
        country: pm.country ?? '',
        fullAddress: fullParts.join(', '),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<geo.Placemark>> _placemarkFromCoordinates((double, double) coords) async {
    return geo.placemarkFromCoordinates(coords.$1, coords.$2);
  }

  static Future<Position?> getCurrentPosition() async {
    final status = await checkPermission();
    if (status != LocationPermissionStatus.granted) return null;
    // Timeout'lu — GPS fix yoksa (emülatör) sonsuz bekleme yerine son bilinen
    // konuma düşer.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  static Future<Position?> getCurrentLocation() async {
    return getCurrentPosition();
  }

  static Stream<Position> get locationStream {
    _locationStream ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
    return _locationStream!;
  }

  static void startLiveSharing() {
    // Stream is accessed via locationStream getter
  }

  static void stopLiveSharing() {
    _locationStream = null;
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}
