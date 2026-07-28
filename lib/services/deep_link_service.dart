import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../config/routes.dart';

/// Deep link handler using app_links.
///
/// Desteklenen davet biçimleri (hepsi `/join?code=XXXX`'e yönlenir):
///   https://familyhub.app/invite/XXXX
///   https://familyhub.app/join?code=XXXX
///   com.familyhub.app://join?code=XXXX
class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static Future<void> initialize(GoRouter router) async {
    _sub?.cancel();
    // Uygulama açıkken gelen linkler.
    _sub = _appLinks.uriLinkStream.listen((uri) => _handleUri(uri, router));
    // Soğuk başlangıç — uygulama bir linkle sıfırdan açıldıysa.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial, router);
    } catch (_) {
      // initial link yoksa/okunamıyorsa sessizce geç.
    }
  }

  static void _handleUri(Uri uri, GoRouter router) {
    final path = uri.path;

    // Davet kodu — path (/invite/XXXX veya /join) ya da query (?code= / ?invite=).
    final code = _extractInviteCode(uri);
    if (code != null && code.isNotEmpty) {
      router.go('${AppRoutes.joinFamily}?code=$code');
      return;
    }

    switch (path) {
      case '/tasks':
        router.go(AppRoutes.tasks);
      case '/chat':
        router.go(AppRoutes.chat);
      case '/calendar':
        router.go(AppRoutes.calendar);
      case '/safety':
        router.go(AppRoutes.safety);
      case '/settings':
        router.go(AppRoutes.settings);
      default:
        router.go(AppRoutes.hub);
    }
  }

  /// Linkten davet kodunu çıkarır (varsa), büyük harfe çevirir.
  @visibleForTesting
  static String? extractInviteCode(Uri uri) => _extractInviteCode(uri);

  static String? _extractInviteCode(Uri uri) {
    final path = uri.path;
    if (path.startsWith('/invite/')) {
      final c = path.replaceFirst('/invite/', '').trim();
      if (c.isNotEmpty) return c.toUpperCase();
    }
    final q = uri.queryParameters['code'] ?? uri.queryParameters['invite'];
    if (q != null && q.trim().isNotEmpty) return q.trim().toUpperCase();
    return null;
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
