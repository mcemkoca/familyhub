import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import '../config/routes.dart';

/// Deep link handler using app_links.
class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<dynamic>? _sub;

  static void initialize(GoRouter router) {
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, router);
    });
  }

  static void _handleUri(Uri uri, GoRouter router) {
    final path = uri.path;
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
        if (path.startsWith('/invite/')) {
          final code = path.replaceFirst('/invite/', '');
          router.go('${AppRoutes.register}?invite=$code');
        } else {
          router.go(AppRoutes.hub);
        }
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
