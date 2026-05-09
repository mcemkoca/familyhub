import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'presentation/providers/app_providers.dart';
import 'services/notification_service.dart';
import 'services/deep_link_service.dart';
import 'core/app_initializer.dart';

void main() async {
  await AppInitializer.initialize();
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
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'FamilyHub',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
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
