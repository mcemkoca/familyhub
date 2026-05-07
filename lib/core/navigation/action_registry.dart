import '../../core/analytics/analytics_service.dart';
import '../../core/error/global_error_handler.dart';
import '../../services/auth_service.dart';
import '../../services/billing/subscription_service.dart';
import '../../services/growth/referral_service.dart';

/// Central registry mapping action identifiers to executable functions.
///
/// Usage:
/// ```dart
/// await ActionRegistry.execute('login', {'email': 'a@b.com', 'password': '...'});
/// ```
class ActionRegistry {
  ActionRegistry._();

  static final Map<String, _ActionDef> _actions = {};
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // ── Auth Actions ─────────────────────────────────────────────────────
    _actions['login'] = _ActionDef(
      handler: (params) => AuthService.signIn(
        email: params?['email'] as String? ?? '',
        password: params?['password'] as String? ?? '',
      ),
      requiresAuth: false,
    );

    _actions['register'] = _ActionDef(
      handler: (params) => AuthService.signUp(
        email: params?['email'] as String? ?? '',
        password: params?['password'] as String? ?? '',
        name: params?['name'] as String? ?? '',
        familyName: params?['family_name'] as String?,
      ),
      requiresAuth: false,
    );

    _actions['logout'] = _ActionDef(
      handler: (_) => AuthService.signOut(),
      requiresAuth: true,
    );

    _actions['forgot_password'] = _ActionDef(
      handler: (params) =>
          AuthService.resetPassword(params?['email'] as String? ?? ''),
      requiresAuth: false,
    );

    // ── Billing Actions ──────────────────────────────────────────────────
    _actions['upgrade_premium'] = _ActionDef(
      handler: (params) async {
        final offering = await SubscriptionService.getOfferings();
        final packages = offering?.availablePackages;
        if (packages != null && packages.isNotEmpty) {
          await SubscriptionService.purchasePackage(packages.first);
        }
      },
      requiresAuth: true,
    );

    _actions['restore_purchases'] = _ActionDef(
      handler: (_) => SubscriptionService.restorePurchases(),
      requiresAuth: true,
    );

    // ── Growth Actions ───────────────────────────────────────────────────
    _actions['invite_member'] = _ActionDef(
      handler: (params) => ReferralService.generateInviteLink(
        params?['family_id'] as String? ?? '',
      ),
      requiresAuth: true,
    );

    // ── Settings Actions ─────────────────────────────────────────────────
    _actions['change_theme'] = _ActionDef(
      handler: (params) async {
        // Theme changes are handled by Riverpod providers, not async
        // This action is reserved for future analytics tracking
      },
      requiresAuth: false,
    );
  }

  /// Executes an action by name with optional parameters.
  ///
  /// Throws [UnimplementedError] if the action is not registered.
  /// Retries transient failures automatically.
  static Future<void> execute(
    String action, [
    Map<String, dynamic>? params,
  ]) async {
    _ensureInitialized();

    final def = _actions[action];
    if (def == null) {
      throw UnimplementedError('Action not found: $action');
    }

    // Track action
    AnalyticsService.track(
      'action_executed',
      properties: {
        'action': action,
        'has_params': params != null && params.isNotEmpty,
      },
    );

    try {
      await withRetry(
        operation: () => def.handler(params),
        maxRetries: 2,
        retryIf: (e) => e is Exception && !_isAuthError(e),
      );
    } catch (e) {
      AnalyticsService.track(
        'action_failed',
        properties: {'action': action, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Checks if an action is registered.
  static bool hasAction(String action) {
    _ensureInitialized();
    return _actions.containsKey(action);
  }

  /// Returns the list of all registered action names.
  static List<String> get registeredActions {
    _ensureInitialized();
    return _actions.keys.toList();
  }

  static bool _isAuthError(Object error) {
    return error.toString().toLowerCase().contains('auth') ||
        error.toString().toLowerCase().contains('giriş') ||
        error.toString().toLowerCase().contains('yetki');
  }
}

// ── Internal ────────────────────────────────────────────────────────────

typedef _ActionHandler = Future<void> Function(Map<String, dynamic>? params);

class _ActionDef {
  final _ActionHandler handler;
  final bool requiresAuth;

  _ActionDef({required this.handler, this.requiresAuth = true});
}
