import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'weather_service.dart';
import 'localization/locale_service.dart';

class LocationWeatherService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  static Future<WeatherData> getCurrentLocationWeather({bool celsius = true}) async {
    // 1. Konum izni kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(_text(const {'tr': 'Konum izni reddedildi', 'en': 'Location permission was denied', 'nl': 'Locatietoestemming is geweigerd', 'fr': 'L’autorisation de localisation a été refusée'}));
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(_text(const {'tr': 'Konum izni kalıcı olarak reddedildi. Ayarlardan etkinleştirin.', 'en': 'Location permission was permanently denied. Enable it in Settings.', 'nl': 'Locatietoestemming is permanent geweigerd. Schakel deze in via Instellingen.', 'fr': 'L’autorisation de localisation a été définitivement refusée. Activez-la dans les réglages.'}));
    }

    // 2. GPS konum al — timeout'lu (emülatör/kapalı GPS'te sonsuz beklemeyi önler).
    //    Zaman aşımında son bilinen konuma düşer; o da yoksa hata fırlatır.
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw LocationException(_text(const {'tr': 'Konum alınamadı (GPS zaman aşımı)', 'en': 'Could not get the location (GPS timed out)', 'nl': 'De locatie kon niet worden bepaald (GPS-time-out)', 'fr': 'Impossible d’obtenir la position (délai GPS dépassé)'}));
      }
      position = last;
    }

    // 3. Reverse geocoding (şehir adı için)
    // ignore: unused_local_variable
    String city = _unknown;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            _unknown;
      }
    } catch (e) {
      // Geocoding başarısız olursa sessizce devam et
    }

    // 4. Hava durumu verisini al ve şehir adını ekle
    final weather = await WeatherService.fetchWeather(
      position.latitude,
      position.longitude,
      celsius: celsius,
    );

    return weather;
  }

  static Future<String> getCityName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            _unknown;
      }
    } catch (e) { debugPrint('Location weather error: $e'); }
    return _unknown;
  }

  static String get _unknown => _text(const {'tr': 'Bilinmiyor', 'en': 'Unknown', 'nl': 'Onbekend', 'fr': 'Inconnu'});
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
