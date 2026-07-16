import 'package:geolocator/geolocator.dart';
import '../core/supabase_client.dart';
import 'localization/locale_service.dart';

class LiveSupportService {
  static String _text(Map<String, String> values) {
    final lang = LocaleService.resolveInitialLocale().languageCode;
    return values[lang] ?? values['tr']!;
  }
  static Future<SupportSession> initiateLiveSupport() async {
    final user = SupabaseConfig.safeClient?.auth.currentUser;
    if (user == null) {
      throw SupportException(_text(const {'tr': 'Giriş yapmalısınız', 'en': 'You must sign in', 'nl': 'Je moet inloggen', 'fr': 'Vous devez vous connecter'}));
    }

    // 2. Konum al
    final Position? position = await _getSafePosition();
    final String locationText = position != null
        ? '${position.latitude},${position.longitude}'
        : _text(const {'tr': 'Konum alınamadı', 'en': 'Location unavailable', 'nl': 'Locatie niet beschikbaar', 'fr': 'Position indisponible'});

    // 3. Supabase Realtime'e session aç
    final session = await SupabaseConfig.safeClient!
        .from('support_sessions')
        .insert({
          'user_id': user.id,
          'status': 'waiting',
          'location': locationText,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return SupportSession.fromJson(session);
  }

  static Future<Position?> _getSafePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)),
      );
    } catch (e) {
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> watchMessages(String sessionId) {
    final client = SupabaseConfig.safeClient;
    if (client == null) return const Stream.empty();
    return client
        .from('support_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((data) {
          if (data.isEmpty) return <Map<String, dynamic>>[];
          final session = data.first;
          final messages = session['messages'];
          if (messages is List) {
            return messages.cast<Map<String, dynamic>>();
          }
          return <Map<String, dynamic>>[];
        });
  }
}

class SupportSession {
  final String id;
  final String userId;
  final String status;
  final String? location;
  final DateTime createdAt;

  SupportSession({
    required this.id,
    required this.userId,
    required this.status,
    this.location,
    required this.createdAt,
  });

  factory SupportSession.fromJson(Map<String, dynamic> json) {
    return SupportSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SupportException implements Exception {
  final String message;
  SupportException(this.message);

  @override
  String toString() => message;
}
