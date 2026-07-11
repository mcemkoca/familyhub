import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/supabase_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'core/config/env.dart';
import 'core/localization/app_locale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'domain/entities.dart';
import 'presentation/providers/app_providers.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/billing/subscription_service.dart';
import 'services/content/content_engine.dart';
import 'services/content/family_suggestions_pool.dart';
import 'services/hub_offline_service.dart';
import 'services/encryption_service.dart';
import 'services/smart_reminder_background_service.dart';
import 'services/fcm_service.dart';
import 'services/error_service.dart';
import 'services/deep_link_service.dart';
import 'services/location_tracking_service.dart';
import 'services/crash_detection_service.dart';
import 'services/safety_service.dart';
import 'core/sentry_config.dart';
import 'core/ssl_pinning.dart';
import 'core/error/global_error_handler.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/heatmap_tracker.dart';
import 'core/firebase/firebase_crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Wrap every critical init so a single failure never kills the app
  try {
    SslPinning.enable();
  } catch (e) {
    debugPrint('SSL Pinning init error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await FirebaseCrashlyticsService.initialize();
  } catch (e) {
    debugPrint('Crashlytics init error: $e');
  }

  try {
    await AnalyticsService.initializeFirebase();
  } catch (e) {
    debugPrint('Analytics init error: $e');
  }

  await SentryConfig.init(() async {
    try {
      GlobalErrorHandler.initialize();
    } catch (e) {
      debugPrint('GlobalErrorHandler init error: $e');
    }
    await _initAndRunApp();
  });
}

Future<void> _initAndRunApp() async {
  ThemeMode themeMode = ThemeMode.light;
  Color accentColor = AppColors.cobalt;
  double fontScale = 1.0;
  Locale initialLocale = AppLanguage.defaultLanguage.locale;
  List<Task> savedTasks = [];
  List<ChatMessage> savedChatMessages = [];
  List<StreakEntry> savedStreaks = [];

  try {
    // Fast local init first
    await _safeInit(
      () async {
        for (final localeName in const [
          'tr_TR',
          'nl_BE',
          'fr_BE',
          'en_GB',
        ]) {
          await initializeDateFormatting(localeName, null);
        }
      },
      'dateFormatting',
      ms: 4000,
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

    final savedLanguage =
        HiveService.getSetting('languageCode') ??
        HiveService.getSetting('language');
    final appLanguage = AppLanguage.fromStoredValue(savedLanguage);
    initialLocale = appLanguage.locale;

    // Migrate legacy display-name storage to a stable language code.
    await HiveService.setSetting('languageCode', appLanguage.code);
    await HiveService.setSetting('language', appLanguage.nativeName);

    savedTasks = _safeCall(HiveService.getTasks, 'getTasks');
    savedChatMessages = _safeCall(
      HiveService.getChatMessages,
      'getChatMessages',
    );
    savedStreaks = _safeCall(HiveService.getStreaks, 'getStreaks');

    // Background init — app is already open, user can interact
    _safeInit(NotificationService.init, 'NotificationService', ms: 3000);
    _safeInit(HubOfflineService.init, 'HubOfflineService', ms: 2000);
    _safeInit(EncryptionService.initialize, 'EncryptionService', ms: 2000);

    // .env + Supabase (network, can be slow) — MUST complete before widgets use Supabase
    // SECURITY: Use envied for obfuscated environment variables.
    // Fallback to dart-define if envied values are empty.
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

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    } else {
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

      // Load theme/accent from profile if logged in (overrides local Hive settings)
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

    // Error handling MUST be initialized before runApp to catch first-frame errors
    ErrorService.initialize();

    // Open app NOW — all critical services initialized
    runApp(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => themeMode),
          accentColorProvider.overrideWith((ref) => accentColor),
          fontScaleProvider.overrideWith((ref) => fontScale),
          localeProvider.overrideWith((ref) => initialLocale),
          tasksProvider.overrideWith((ref) => savedTasks),
          // transactionsProvider intentionally not overridden — BudgetNotifier loads from repository
          chatMessagesProvider.overrideWith((ref) => savedChatMessages),
          streakEntriesProvider.overrideWith((ref) => savedStreaks),
        ],
        child: const FamilyHubApp(),
      ),
    );

    // Analytics & billing (fire-and-forget)
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
    _safeInit(
      () async => LocationTrackingService.startTracking(),
      'LocationTracking',
      ms: 2000,
    );
    _safeInit(
      () async => CrashDetectionService().startMonitoring(),
      'CrashDetection',
      ms: 2000,
    );
    HeatmapTracker.initialize();
  } catch (e) {
    debugPrint('Fatal init error: $e');
    // Ensure app opens even if everything fails
    _runDefaultApp();
  }
}

void _runDefaultApp() {
  runApp(const ProviderScope(child: FamilyHubApp()));
}

Future<void> _safeInit(
  Future<void> Function() fn,
  String name, {
  int ms = 3000,
}) async {
  try {
    await fn().timeout(Duration(milliseconds: ms));
  } catch (e) {
    debugPrint('Safe init error: $e');
  }
}

List<T> _safeCall<T>(List<T> Function() fn, String name) {
  try {
    return fn();
  } catch (e) {
    return <T>[];
  }
}

class FamilyHubApp extends ConsumerStatefulWidget {
  const FamilyHubApp({super.key});

  @override
  ConsumerState<FamilyHubApp> createState() => _FamilyHubAppState();
}

class _FamilyHubAppState extends ConsumerState<FamilyHubApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeepLinkService.initialize(router);
    NotificationService.setOnTapCallback((payload) {
      if (!mounted) return;
      if (payload == null) return;
      switch (payload) {
        case 'tasks':
          context.go(AppRoutes.tasks);
        case 'calendar':
          context.go(AppRoutes.calendar);
        case 'chat':
          context.go(AppRoutes.chat);
        case 'safety':
          context.go(AppRoutes.safety);
        default:
          context.go(AppRoutes.hub);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Force rebuild so AnnotatedRegion and custom widgets update instantly
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final accentColor = ref.watch(accentColorProvider);
    final brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        locale: ref.watch(localeProvider),
        theme: AppTheme.lightTheme(accentColor, fontScale: fontScale),
        darkTheme: AppTheme.darkTheme(accentColor, fontScale: fontScale),
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) => AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: child!,
        ),
      ),
    );
  }
}
