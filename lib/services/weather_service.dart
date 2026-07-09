import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static Future<WeatherData> fetchWeather(double lat, double lon, {bool celsius = true}) async {
    final unit = celsius ? 'celsius' : 'fahrenheit';
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,wind_speed_10m,pressure_msl'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=auto'
      '&temperature_unit=$unit'
      '&wind_speed_unit=kmh'
      '&pressure_unit=hpa',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData.fromJson(data);
    }
    throw Exception('Hava durumu alınamadı');
  }

  static Future<WeatherData> fetchWeatherForLocation({bool celsius = true}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 8)),
      );
      return fetchWeather(pos.latitude, pos.longitude, celsius: celsius);
    } catch (e) {
      throw Exception('Konum alınamadı: $e');
    }
  }

  static String weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '☀️';
  }

  static IconData weatherIconData(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code <= 48) return Icons.foggy;
    if (code <= 67) return Icons.water_drop;
    if (code <= 77) return Icons.ac_unit;
    if (code <= 82) return Icons.water_drop;
    if (code <= 86) return Icons.ac_unit;
    if (code <= 99) return Icons.thunderstorm;
    return Icons.wb_sunny;
  }

  static Color weatherColor(int code) {
    if (code == 0) return const Color(0xFFF97316);
    if (code <= 3) return const Color(0xFF94A3B8);
    if (code <= 48) return const Color(0xFF6B7280);
    if (code <= 67) return const Color(0xFF3B82F6);
    if (code <= 77) return const Color(0xFF06B6D4);
    if (code <= 82) return const Color(0xFF3B82F6);
    if (code <= 86) return const Color(0xFF06B6D4);
    if (code <= 99) return const Color(0xFF8B5CF6);
    return const Color(0xFFF97316);
  }

  static String weatherDescription(int code) {
    if (code == 0) return 'Güneşli';
    if (code <= 3) return 'Parçalı Bulutlu';
    if (code <= 48) return 'Sisli';
    if (code <= 67) return 'Yağmurlu';
    if (code <= 77) return 'Karlı';
    if (code <= 82) return 'Sağanak Yağışlı';
    if (code <= 86) return 'Kar Fırtınası';
    if (code <= 99) return 'Gök Gürültülü';
    return 'Bilinmiyor';
  }

  /// Anlık hava koşullarına göre aile için pratik uyarı (yoksa null).
  /// WMO kodu + sıcaklık + rüzgâr esas alınır. Emoji ile döner.
  static String? weatherWarning(WeatherData w) {
    final c = w.weatherCode;
    if (c >= 95) return '⛈️ Gök gürültülü fırtına — dışarı çıkmadan önce dikkat.';
    if (c >= 85) return '🌨️ Kar fırtınası — yollar kapanabilir, erken çıkın.';
    if (c >= 80) return '🌧️ Sağanak yağış — şemsiye ve su geçirmez montu alın.';
    if (c >= 71) return '❄️ Kar yağışı — çocukları sıcak giydirin, yol kaygan olabilir.';
    if (c >= 51) return '☔ Yağmur bekleniyor — şemsiyeyi unutmayın.';
    if (c >= 45) return '🌫️ Sisli hava — trafikte görüş mesafesi düşük, dikkatli olun.';
    if (w.windSpeed >= 45) return '💨 Kuvvetli rüzgâr — gevşek nesnelere dikkat.';
    if (w.temperature <= 0) return '🥶 Donma riski — sıcak giyinin, buzlanmaya dikkat.';
    if (w.temperature >= 32) return '🥵 Aşırı sıcak — bol su için, güneşten korunun.';
    return null;
  }

  static final List<Map<String, dynamic>> cities = [
    // Belçika (varsayılan pazar)
    {'name': 'Brüksel', 'lat': 50.8503, 'lon': 4.3517},
    {'name': 'Antwerp', 'lat': 51.2194, 'lon': 4.4025},
    {'name': 'Gent', 'lat': 51.0543, 'lon': 3.7174},
    {'name': 'Charleroi', 'lat': 50.4108, 'lon': 4.4446},
    {'name': 'Liège', 'lat': 50.6326, 'lon': 5.5797},
    {'name': 'Brugge', 'lat': 51.2093, 'lon': 3.2247},
    {'name': 'Namur', 'lat': 50.4674, 'lon': 4.8720},
    {'name': 'Leuven', 'lat': 50.8798, 'lon': 4.7005},
    // Türkiye
    {'name': 'İstanbul', 'lat': 41.0082, 'lon': 28.9784},
    {'name': 'Ankara', 'lat': 39.9334, 'lon': 32.8597},
    {'name': 'İzmir', 'lat': 38.4192, 'lon': 27.1287},
    {'name': 'Bursa', 'lat': 40.1826, 'lon': 29.0669},
    {'name': 'Antalya', 'lat': 36.8969, 'lon': 30.7133},
    {'name': 'Adana', 'lat': 37.0000, 'lon': 35.3213},
    {'name': 'Konya', 'lat': 37.8713, 'lon': 32.4846},
    {'name': 'Gaziantep', 'lat': 37.0662, 'lon': 37.3833},
    {'name': 'Şanlıurfa', 'lat': 37.1591, 'lon': 38.7969},
    {'name': 'Mersin', 'lat': 36.8121, 'lon': 34.6415},
    {'name': 'Diyarbakır', 'lat': 37.9143, 'lon': 40.2306},
    {'name': 'Kayseri', 'lat': 38.7205, 'lon': 35.4826},
    {'name': 'Eskişehir', 'lat': 39.7767, 'lon': 30.5206},
    {'name': 'Samsun', 'lat': 41.2867, 'lon': 36.3300},
    {'name': 'Trabzon', 'lat': 41.0015, 'lon': 39.7178},
    {'name': 'Erzurum', 'lat': 39.9043, 'lon': 41.2679},
    {'name': 'Malatya', 'lat': 38.3554, 'lon': 38.3337},
    {'name': 'Kocaeli', 'lat': 40.8533, 'lon': 29.8815},
    {'name': 'Tekirdağ', 'lat': 40.9781, 'lon': 27.5112},
    {'name': 'Van', 'lat': 38.5014, 'lon': 43.3727},
    // Avrupa
    {'name': 'Berlin', 'lat': 52.5200, 'lon': 13.4050},
    {'name': 'Paris', 'lat': 48.8566, 'lon': 2.3522},
    {'name': 'Londra', 'lat': 51.5074, 'lon': -0.1278},
    {'name': 'Roma', 'lat': 41.9028, 'lon': 12.4964},
    {'name': 'Madrid', 'lat': 40.4168, 'lon': -3.7038},
    {'name': 'Amsterdam', 'lat': 52.3676, 'lon': 4.9041},
    {'name': 'Viyana', 'lat': 48.2082, 'lon': 16.3738},
    {'name': 'Zürih', 'lat': 47.3769, 'lon': 8.5417},
    {'name': 'Stockholm', 'lat': 59.3293, 'lon': 18.0686},
    {'name': 'Kopenhag', 'lat': 55.6761, 'lon': 12.5683},
    {'name': 'Barselona', 'lat': 41.3851, 'lon': 2.1734},
    {'name': 'Münih', 'lat': 48.1351, 'lon': 11.5820},
    {'name': 'Milano', 'lat': 45.4642, 'lon': 9.1900},
    {'name': 'Prag', 'lat': 50.0755, 'lon': 14.4378},
    {'name': 'Budapeşte', 'lat': 47.4979, 'lon': 19.0402},
    {'name': 'Lizbon', 'lat': 38.7223, 'lon': -9.1393},
    {'name': 'Dublin', 'lat': 53.3498, 'lon': -6.2603},
    {'name': 'Brüksel', 'lat': 50.8476, 'lon': 4.3572},
    {'name': 'Varşova', 'lat': 52.2297, 'lon': 21.0122},
    {'name': 'Helsinki', 'lat': 60.1699, 'lon': 24.9384},
  ];
}

class WeatherData {
  final double temperature;
  final int weatherCode;
  final int humidity;
  final double feelsLike;
  final double windSpeed;
  final double pressure;
  final List<DailyForecast> daily;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.feelsLike,
    required this.windSpeed,
    required this.pressure,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    final daily = json['daily'] as Map<String, dynamic>?;
    final List<DailyForecast> forecast = [];
    
    if (daily != null) {
      final codes = (daily['weather_code'] as List<dynamic>);
      final maxTemps = (daily['temperature_2m_max'] as List<dynamic>);
      final minTemps = (daily['temperature_2m_min'] as List<dynamic>);
      final times = (daily['time'] as List<dynamic>);
      
      for (int i = 0; i < codes.length && i < 7; i++) {
        forecast.add(DailyForecast(
          date: DateTime.parse(times[i] as String),
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          weatherCode: codes[i] as int,
        ));
      }
    }

    return WeatherData(
      temperature: (current!['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      humidity: current['relative_humidity_2m'] as int,
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      pressure: (current['pressure_msl'] as num?)?.toDouble() ?? 0.0,
      daily: forecast,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });
}
