import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/errors.dart';
import 'localization/locale_service.dart';

class WeatherPrefsService {
  static String _text(Map<String, String> values) { final lang = LocaleService.resolveInitialLocale().languageCode; return values[lang] ?? values['tr']!; }
  static String get _notSignedIn => _text(const {'tr': 'Oturum açık değil', 'en': 'You are not signed in', 'nl': 'Je bent niet ingelogd', 'fr': 'Vous n’êtes pas connecté'});
  final Box<dynamic> _weatherBox;
  final SupabaseClient _supabase;

  WeatherPrefsService(this._weatherBox, this._supabase);

  static Future<WeatherPrefsService> create() async {
    final client = SupabaseConfig.safeClient;
    if (client == null) throw Exception(_text(const {'tr': 'Sunucu bağlantısı kurulamadı', 'en': 'Could not connect to the server', 'nl': 'Kan geen verbinding maken met de server', 'fr': 'Impossible de se connecter au serveur'}));
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
    if (userId == null) throw AppAuthException(_notSignedIn);

    await _supabase.from('weather_prefs').upsert({
      'user_id': userId,
      'city': city,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

    await _weatherBox.put('weather_city', city);
  }

  Future<void> setUnit(bool useCelsius) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw AppAuthException(_notSignedIn);

    await _supabase.from('weather_prefs').upsert({
      'user_id': userId,
      'unit': useCelsius ? 'celsius' : 'fahrenheit',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');

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
