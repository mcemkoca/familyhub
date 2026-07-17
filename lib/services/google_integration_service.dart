import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../core/app_logger.dart';

/// Google ürünleriyle (Takvim, Fotoğraflar) doğrudan bağlantı.
///
/// KURULUM GEREKLİ — bu servis, `--dart-define` ile bir OAuth istemci kimliği
/// verilene kadar `isConfigured == false` döner ve tüm çağrılar güvenle boş/nul
/// sonuç verir (uygulama çökmeden çalışmaya devam eder). Adım adım kurulum için:
///   docs/GOOGLE_SETUP.md
///
/// Not: Android'de cihaz takvimi zaten OS üzerinden Google Takvim ile eşitlenir;
/// bu servis, doğrudan Google Calendar API erişimi (paylaşımlı aile takvimleri,
/// sunucu tarafı senkron) ve Google Fotoğraflar için gereklidir.
class GoogleIntegrationService {
  // Google Cloud Console > Credentials > OAuth 2.0 Client ID (Web/Android).
  // Örn: flutter run --dart-define=GOOGLE_OAUTH_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String _clientId =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');

  /// İstenen izin kapsamları: Takvim (okuma/yazma) + Fotoğraflar (yalnız okuma).
  static const List<String> _scopes = [
    gcal.CalendarApi.calendarScope,
    // Google Photos Library API — okuma erişimi (Photos Library API'yi de aç).
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ];

  static GoogleSignIn? _signIn;

  /// OAuth istemci kimliği verilmişse Google entegrasyonu kullanılabilir.
  static bool get isConfigured => _clientId.isNotEmpty;

  static GoogleSignIn _google() {
    return _signIn ??= GoogleSignIn(
      scopes: _scopes,
      clientId: _clientId.isEmpty ? null : _clientId,
    );
  }

  /// Kullanıcıyı Google ile oturum açtırır. Yapılandırılmadıysa null döner.
  static Future<GoogleSignInAccount?> signIn() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
            'GoogleIntegrationService: yapılandırılmadı (GOOGLE_OAUTH_CLIENT_ID yok).');
      }
      return null;
    }
    try {
      return await _google().signIn();
    } catch (e) {
      if (kDebugMode) debugPrint('Google signIn hata: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _google().signOut();
    } catch (e) {
      // Best-effort: Google oturumu kapanmasa da yerel oturum temizlenir.
      AppLogger.logBestEffort(e, module: 'auth', operation: 'googleSignOut');
    }
  }

  static Future<bool> isSignedIn() async {
    if (!isConfigured) return false;
    try {
      return await _google().isSignedIn();
    } catch (_) {
      return false;
    }
  }

  /// Kullanıcının Google Takvim etkinliklerini çeker (verilen aralık).
  /// Yapılandırılmadıysa veya oturum yoksa boş liste döner.
  static Future<List<gcal.Event>> fetchCalendarEvents({
    DateTime? from,
    DateTime? to,
    String calendarId = 'primary',
  }) async {
    if (!isConfigured) return const [];
    try {
      final account = await _google().signInSilently() ?? await signIn();
      if (account == null) return const [];
      final client = await _google().authenticatedClient();
      if (client == null) return const [];
      final api = gcal.CalendarApi(client);
      final events = await api.events.list(
        calendarId,
        timeMin: (from ?? DateTime.now()).toUtc(),
        timeMax: (to ?? DateTime.now().add(const Duration(days: 30))).toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? const [];
    } catch (e) {
      if (kDebugMode) debugPrint('fetchCalendarEvents hata: $e');
      return const [];
    }
  }

  /// Google Takvim'e etkinlik ekler. Başarılıysa etkinlik id'si döner.
  static Future<String?> addCalendarEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
    String calendarId = 'primary',
  }) async {
    if (!isConfigured) return null;
    try {
      final account = await _google().signInSilently() ?? await signIn();
      if (account == null) return null;
      final client = await _google().authenticatedClient();
      if (client == null) return null;
      final api = gcal.CalendarApi(client);
      final event = gcal.Event(
        summary: title,
        description: description,
        location: location,
        start: gcal.EventDateTime(dateTime: start.toUtc()),
        end: gcal.EventDateTime(dateTime: end.toUtc()),
      );
      final created = await api.events.insert(event, calendarId);
      return created.id;
    } catch (e) {
      if (kDebugMode) debugPrint('addCalendarEvent hata: $e');
      return null;
    }
  }

  // NOT: Google Fotoğraflar (Photos Library API) erişimi authenticatedClient
  // üzerinden `https://photoslibrary.googleapis.com/v1/mediaItems` çağrısıyla
  // yapılır. Uygulama içi galeri şu an cihaz galerisini (OS senkronlu Google
  // Fotoğraflar dahil) kullandığından, doğrudan Photos API entegrasyonu
  // kurulum sonrası buraya eklenecek (bkz. docs/GOOGLE_SETUP.md).
}
