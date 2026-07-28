import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../domain/entities.dart';

class LocationService {
  static Stream<Position>? _locationStream;

  /// YAN ETKİSİZ durum sorgusu (FH-07): izin DIALOGU AÇMAZ.
  ///
  /// Eski [checkPermission] "check" adına rağmen izin istiyordu; bu yüzden
  /// salt-okunur çağrılar beklenmedik sistem dialogu tetikliyordu ve
  /// whileInUse/always ayrımı görünmüyordu. Yeni kod bunu kullanmalı.
  static Future<LocationPermissionStatus> checkPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    return mapGeolocatorPermission(permission, serviceEnabled: serviceEnabled);
  }

  /// AÇIKÇA izin ister (kullanıcı eylemiyle çağrılmalı).
  static Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;
    final permission = await Geolocator.requestPermission();
    return mapGeolocatorPermission(permission, serviceEnabled: true);
  }

  /// Cihaz konum ayarlarını açar (deniedForever / serviceDisabled akışı).
  static Future<bool> openSettings({bool locationSettings = false}) {
    return locationSettings
        ? Geolocator.openLocationSettings()
        : Geolocator.openAppSettings();
  }

  /// Geriye-uyum: mevcut çağıranlar için korunur (reddedilmişse izin ister).
  /// Yeni kod [checkPermissionStatus] + [requestPermission] kullanmalı.
  static Future<LocationPermissionStatus> checkPermission() async {
    var status = await checkPermissionStatus();
    if (status == LocationPermissionStatus.denied) {
      status = await requestPermission();
    }
    if (status.isGranted) return LocationPermissionStatus.granted;
    return status;
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

/// Konum izni durumları (FH-07 / spec §11 — granüler).
///
/// [granted] geriye-uyum içindir; yeni kod [whileInUse]/[always] ayrımını
/// kullanmalıdır (arka plan takibi yalnızca [always] ile çalışır).
enum LocationPermissionStatus {
  granted, // legacy — whileInUse|always çatısı
  whileInUse, // yalnızca uygulama açıkken
  always, // arka planda da izinli
  denied, // reddedildi, tekrar sorulabilir
  deniedForever, // kalıcı red → cihaz ayarları gerekir
  serviceDisabled, // konum servisi kapalı
  unknown, // belirlenemedi
}

extension LocationPermissionStatusX on LocationPermissionStatus {
  /// Konum okunabilir mi? (ön plan yeterli)
  bool get isGranted =>
      this == LocationPermissionStatus.granted ||
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;

  /// Arka planda konum takibi yapılabilir mi? (yalnızca 'always')
  bool get canTrackInBackground => this == LocationPermissionStatus.always;

  /// Kullanıcı tekrar sorulabilir mi? (deniedForever → hayır, ayarlar gerekir)
  bool get isAskable => this == LocationPermissionStatus.denied;

  /// Cihaz ayarlarına yönlendirme gerekiyor mu?
  bool get needsSettings =>
      this == LocationPermissionStatus.deniedForever ||
      this == LocationPermissionStatus.serviceDisabled;
}

/// Geolocator izni → uygulama durumu (SAF fonksiyon — test edilebilir).
LocationPermissionStatus mapGeolocatorPermission(
  LocationPermission permission, {
  required bool serviceEnabled,
}) {
  if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;
  return switch (permission) {
    LocationPermission.always => LocationPermissionStatus.always,
    LocationPermission.whileInUse => LocationPermissionStatus.whileInUse,
    LocationPermission.denied => LocationPermissionStatus.denied,
    LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
    LocationPermission.unableToDetermine => LocationPermissionStatus.unknown,
  };
}
