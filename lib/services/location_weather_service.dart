import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'weather_service.dart';

class LocationWeatherService {
  static Future<WeatherData> getCurrentLocationWeather({bool celsius = true}) async {
    // 1. Konum izni kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Konum izni reddedildi');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Konum izni kalıcı olarak reddedildi. Ayarlardan etkinleştirin.');
    }

    // 2. GPS konum al
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // 3. Reverse geocoding (şehir adı için)
    String city = 'Bilinmiyor';
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
            'Bilinmiyor';
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
            'Bilinmiyor';
      }
    } catch (_) {}
    return 'Bilinmiyor';
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
