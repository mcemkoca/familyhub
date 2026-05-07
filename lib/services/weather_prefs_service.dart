import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';

class WeatherPrefsService {
  final Box<dynamic> _weatherBox;
  final SupabaseClient _supabase;

  WeatherPrefsService(this._weatherBox, this._supabase);

  static Future<WeatherPrefsService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception('Supabase bağlantısı yok');
    final box = await Hive.openBox<dynamic>('weatherBox');
    return WeatherPrefsService(box, client);
  }

  Future<String?> getCurrentCity() async {
    // 1. Hive cache
    final cached = _weatherBox.get('weather_city');
    if (cached != null) return cached.toString();

    // 2. Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('weather_prefs')
        .select('city')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      await _weatherBox.put('weather_city', response['city']);
      return response['city'] as String?;
    }
    return null;
  }

  Future<void> setCity(String city) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException('Oturum açık değil');

    await _supabase.from('weather_prefs').upsert({
      'user_id': userId,
      'city': city,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _weatherBox.put('weather_city', city);
  }

  Future<void> setUnit(bool useCelsius) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException('Oturum açık değil');

    await _supabase.from('weather_prefs').upsert({
      'user_id': userId,
      'unit': useCelsius ? 'celsius' : 'fahrenheit',
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _weatherBox.put('weather_unit', useCelsius ? 'celsius' : 'fahrenheit');
  }

  Future<String?> getUnit() async {
    final cached = _weatherBox.get('weather_unit');
    if (cached != null) return cached.toString();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('weather_prefs')
        .select('unit')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      await _weatherBox.put('weather_unit', response['unit']);
      return response['unit'] as String?;
    }
    return null;
  }
}
