import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/constants.dart';
import '../main.dart';
import '../domain/entities.dart';
import '../presentation/providers/app_providers.dart';
import '../services/notification_service.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../services/billing/subscription_service.dart';
import '../services/content/content_engine.dart';
import '../services/content/family_suggestions_pool.dart';
import '../services/hub_offline_service.dart';
import '../services/encryption_service.dart';
import '../services/smart_reminder_background_service.dart';
import '../services/fcm_service.dart';
import '../services/error_service.dart';
import '../services/safety_service.dart';
import 'supabase_client.dart';
import 'config/env.dart';
import 'sentry_config.dart';
import 'ssl_pinning.dart';
import 'error/global_error_handler.dart';
import 'analytics/analytics_service.dart';
import 'analytics/heatmap_tracker.dart';
import 'firebase/firebase_crashlytics_service.dart';
import '../firebase_options.dart';

/// Result of the initialization phase containing values needed for first-frame render.
class AppInitResult {
  const AppInitResult({
    required this.themeMode,
    required this.accentColor,
    required this.fontScale,
    required this.savedTasks,
    required this.savedChatMessages,
    required this.savedStreaks,
  });

  final ThemeMode themeMode;
  final Color accentColor;
  final double fontScale;
  final List<Task> savedTasks;
  final List<ChatMessage> savedChatMessages;
  final List<StreakEntry> savedStreaks;
}

/// Centralized application initializer extracted from main.dart.
/// Handles all service bootstrapping with defensive error handling.
class AppInitializer {
  AppInitializer._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Wrap every critical init so a single failure never kills the app
    _safeCall(() => SslPinning.enable(), 'SSL Pinning');
    await _safeInit(
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      'Firebase',
    );
    await _safeInit(FirebaseCrashlyticsService.initialize, 'Crashlytics');
    await _safeInit(AnalyticsService.initializeFirebase, 'Analytics Firebase');

    await SentryConfig.init(() async {
      _safeCall(GlobalErrorHandler.initialize, 'GlobalErrorHandler');
      await _initAndRunApp();
    });
  }

  static Future<void> _initAndRunApp() async {
    var result = const AppInitResult(
      themeMode: ThemeMode.light,
      accentColor: AppColors.cobalt,
      fontScale: 1.0,
      savedTasks: [],
      savedChatMessages: [],
      savedStreaks: [],
    );

    try {
      result = await _loadCoreData();
      _openApp(result);
      _initBackgroundServices();
    } catch (e) {
      debugPrint('Fatal init error: $e');
      _runDefaultApp();
    }
  }

  static Future<AppInitResult> _loadCoreData() async {
    ThemeMode themeMode = ThemeMode.light;
    Color accentColor = AppColors.cobalt;
    double fontScale = 1.0;
    List<Task> savedTasks = [];
    List<ChatMessage> savedChatMessages = [];
    List<StreakEntry> savedStreaks = [];

    // Fast local init first
    await _safeInit(
      () => initializeDateFormatting('tr_TR', null),
      'dateFormatting',
      ms: 2000,
    );
    await _safeInit(Hive.initFlutter, 'Hive', ms: 2000);
    await _safeInit(HiveService.init, 'HiveService', ms: 2000);

    // Load settings immediately so app can open
    final savedTheme = HiveService.getSetting('themeMode') ?? 'system';
    themeMode = switch (savedTheme) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    final savedAccent = HiveService.getSetting('accentColor') ?? 'cobalt';
    accentColor = switch (savedAccent) {
      'green' => AppColors.green,
      'orange' => AppColors.orange,
      'purple' => AppColors.purple,
      'red' => AppColors.red,
      _ => AppColors.cobalt,
    };
    fontScale = HiveService.getDoubleSetting('fontScale') ?? 1.0;

    savedTasks = _safeCallSync(HiveService.getTasks, 'getTasks');
    savedChatMessages = _safeCallSync(
      HiveService.getChatMessages,
      'getChatMessages',
    );
    savedStreaks = _safeCallSync(HiveService.getStreaks, 'getStreaks');

    // Background init — app is already open, user can interact
    _safeInit(NotificationService.init, 'NotificationService', ms: 3000);
    _safeInit(HubOfflineService.init, 'HubOfflineService', ms: 2000);
    _safeInit(EncryptionService.initialize, 'EncryptionService', ms: 2000);

    // .env + Supabase (network, can be slow)
    String supabaseUrl = Env.supabaseUrl;
    if (supabaseUrl.isEmpty) {
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    }
    String supabaseKey = Env.supabaseAnonKey;
    if (supabaseKey.isEmpty) {
      supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    }
    String stripeKey = Env.stripePublishableKey;
    if (stripeKey.isEmpty) {
      stripeKey = const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    }

    if (stripeKey.isNotEmpty && !stripeKey.contains('your-publishable-key')) {
      Stripe.publishableKey = stripeKey;
    }

    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await _safeInit(
        () => Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
          debug: false,
        ),
        'Supabase',
        ms: 5000,
      );
      await _safeInit(
        AuthService.restoreSession,
        'AuthService.restoreSession',
        ms: 5000,
      );
      await _safeInit(
        AuthService.initAuthListener,
        'AuthService.initAuthListener',
        ms: 2000,
      );
      await _safeInit(
        ChildAuthService.restoreSession,
        'ChildAuthService.restoreSession',
        ms: 3000,
      );

      // Load theme/accent from profile if logged in
      if (AuthService.currentUserId != null) {
        try {
          final profile = await SupabaseConfig.safeClient
              ?.from('profiles')
              .select('theme_preference, accent_color')
              .eq('id', AuthService.currentUserId!)
              .maybeSingle();
          if (profile != null) {
            final pTheme = profile['theme_preference'] as String?;
            final pAccent = profile['accent_color'] as String?;
            if (pTheme != null) {
              themeMode = switch (pTheme) {
                'dark' => ThemeMode.dark,
                'system' => ThemeMode.system,
                _ => ThemeMode.light,
              };
            }
            if (pAccent != null) {
              accentColor = switch (pAccent) {
                'green' => AppColors.green,
                'orange' => AppColors.orange,
                'purple' => AppColors.purple,
                'red' => AppColors.red,
                _ => AppColors.cobalt,
              };
            }
          }
        } catch (_) {
          // fallback to Hive values already loaded
        }
      }
    }

    return AppInitResult(
      themeMode: themeMode,
      accentColor: accentColor,
      fontScale: fontScale,
      savedTasks: savedTasks,
      savedChatMessages: savedChatMessages,
      savedStreaks: savedStreaks,
    );
  }

  static void _openApp(AppInitResult result) {
    ErrorService.initialize();

    runApp(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => result.themeMode),
          accentColorProvider.overrideWith((ref) => result.accentColor),
          fontScaleProvider.overrideWith((ref) => result.fontScale),
          tasksProvider.overrideWith((ref) => result.savedTasks),
          chatMessagesProvider.overrideWith((ref) => result.savedChatMessages),
          streakEntriesProvider.overrideWith((ref) => result.savedStreaks),
        ],
        child: const FamilyHubApp(),
      ),
    );
  }

  static void _runDefaultApp() {
    runApp(const ProviderScope(child: FamilyHubApp()));
  }

  static void _initBackgroundServices() {
    _safeInit(AnalyticsService.initialize, 'AnalyticsService', ms: 3000);
    _safeInit(SubscriptionService.initialize, 'SubscriptionService', ms: 3000);
    _safeInit(ContentEngine.initialize, 'ContentEngine', ms: 5000);
    _safeInit(
      FamilySuggestionsPool.initialize,
      'FamilySuggestionsPool',
      ms: 5000,
    );
    _safeInit(
      SmartReminderBackgroundService.initialize,
      'SmartReminderBackground',
      ms: 3000,
    );
    _safeInit(FcmService.initialize, 'FcmService', ms: 5000);
    _safeInit(
      () async => SafetyService.startMonitoring(),
      'SafetyService',
      ms: 2000,
    );
    HeatmapTracker.initialize();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<void> _safeInit(
    Future<void> Function() fn,
    String name, {
    int ms = 3000,
  }) async {
    try {
      await fn().timeout(Duration(milliseconds: ms));
    } catch (e) {
      debugPrint('$name init error: $e');
    }
  }

  static void _safeCall(void Function() fn, String name) {
    try {
      fn();
    } catch (e) {
      debugPrint('$name init error: $e');
    }
  }

  static List<T> _safeCallSync<T>(List<T> Function() fn, String name) {
    try {
      return fn();
    } catch (e) {
      debugPrint('$name load error: $e');
      return <T>[];
    }
  }
}
