import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/registration_wizard_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/hub/hub_screen.dart';
import '../presentation/screens/kitchen/kitchen_screen.dart';
import '../presentation/screens/education/education_screen.dart';
import '../presentation/screens/organizer/tasks_screen.dart';
import '../presentation/screens/organizer/calendar_screen.dart';
import '../presentation/screens/organizer/shopping_list_screen.dart';
import '../presentation/screens/organizer/smart_rotation_screen.dart';
import '../presentation/screens/organizer/calendar_sync_screen.dart';
import '../presentation/screens/reminders/smart_reminders_screen.dart';
import '../presentation/screens/reminders/smart_reminder_create_screen.dart';
import '../presentation/screens/reminders/smart_reminder_detail_screen.dart';
import '../presentation/screens/routines/routines_screen.dart';
import '../presentation/screens/routines/routine_detail_screen.dart';
import '../presentation/screens/crash/crash_screens.dart';
import '../presentation/screens/location_tracking/location_tracking_screens.dart';
import '../presentation/screens/emergency/emergency_screens.dart';
import '../presentation/screens/budget/budget_screen.dart';
import '../presentation/screens/family/family_screen.dart';
import '../presentation/screens/call/call_contact_list_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/chat/mood_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/appearance_settings_screen.dart';
import '../presentation/screens/settings/hub_customize_screen.dart';
import '../presentation/screens/settings/cloud_backup_screen.dart';
import '../presentation/screens/settings/weather_settings_screen.dart';
import '../presentation/screens/safety/safety_screen.dart';
import '../presentation/screens/safety/location_screen.dart';

import '../presentation/screens/safety/health_card_screen.dart';
import '../presentation/screens/safety/safe_zones_screen.dart';
import '../presentation/screens/safety/safe_arrival_screen.dart';
import '../presentation/screens/safety/ambient_listening_screen.dart';
import '../presentation/screens/safety/flashlight_screen.dart';
import '../presentation/screens/memories/memories_screen.dart';
import '../presentation/screens/memories/album_screen.dart';
import '../presentation/screens/memories/memory_create_screen.dart';
import '../presentation/screens/memories/growth_screen.dart';
import '../presentation/screens/contacts/contacts_screen.dart';
import '../presentation/screens/gallery/gallery_screen.dart';
import '../presentation/screens/documents/documents_screen.dart';
import '../presentation/screens/settings/premium_screen.dart';
import '../presentation/screens/settings/family_manage_screen.dart';
import '../presentation/screens/settings/profile_edit_screen.dart';
import '../presentation/screens/settings/leaderboard_screen.dart';
import '../presentation/screens/settings/notification_settings_screen.dart';
import '../presentation/screens/settings/privacy_settings_screen.dart';
import '../presentation/screens/settings/language_settings_screen.dart';
import '../presentation/screens/settings/backup_settings_screen.dart';
import '../presentation/screens/settings/user_guide_screen.dart';
import '../presentation/screens/settings/about_app_screen.dart';
import '../presentation/screens/settings/invite_code_screen.dart';
import '../presentation/screens/settings/join_family_screen.dart';
import '../presentation/screens/settings/terms_of_service_screen.dart';
import '../presentation/screens/settings/privacy_policy_screen.dart';
import '../presentation/screens/settings/screen_time_settings_screen.dart';
import '../presentation/screens/settings/security_settings_screen.dart';
import '../presentation/screens/settings/security_questions_setup_screen.dart';
import '../presentation/screens/settings/family_permissions_screen.dart';
import '../presentation/screens/settings/family_suggestion_settings_screen.dart';
import '../presentation/screens/auth/child_login_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/child/add_task_screen.dart';
import '../presentation/screens/child/child_dashboard_screen.dart';
import '../presentation/screens/child/child_detail_screen.dart';
import '../presentation/screens/child/child_management_screen.dart';
import '../presentation/screens/activities/activities_screen.dart';
import '../presentation/screens/streak/streak_screen.dart';
import '../presentation/screens/main_shell.dart';
import '../presentation/screens/health/health_dashboard.dart';
import '../presentation/screens/budget/subscription_screen.dart';
import '../presentation/screens/child/child_dev_dashboard.dart';
import '../presentation/screens/ai/ai_assistant_screen.dart';
import '../services/auth_service.dart';
import '../services/child_auth_service.dart';
import '../domain/models/crash_event.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String hub = '/';
  static const String tasks = '/tasks';
  static const String smartRotation = '/smart-rotation';
  static const String calendarSync = '/calendar-sync';
  static const String calendar = '/calendar';
  static const String shopping = '/shopping';
  static const String budget = '/budget';
  static const String family = '/family';
  static const String familyDetail = '/family/detail';
  static const String chat = '/chat';
  static const String mood = '/mood';
  static const String settings = '/settings';
  static const String safety = '/safety';
  static const String location = '/location';
  static const String emergency = '/emergency';
  static const String healthCard = '/health-card';
  static const String healthCardEdit = '/health-card/edit';
  static const String safeZones = '/safe-zones';
  static const String safeArrival = '/safe-arrival';
  static const String ambientListening = '/ambient-listening';
  static const String flashlight = '/flashlight';
  static const String memories = '/memories';
  static const String album = '/album';
  static const String memoryCreate = '/memory-create';
  static const String growth = '/growth';
  static const String premium = '/premium';
  static const String familyManage = '/family-manage';
  static const String profileEdit = '/profile-edit';
  static const String notificationSettings = '/notifications';
  static const String privacySettings = '/privacy-settings';
  static const String languageSettings = '/language-settings';
  static const String backupSettings = '/backup-settings';
  static const String appearanceSettings = '/appearance-settings';
  static const String hubCustomize = '/hub-customize';
  static const String googleDriveBackup = '/cloud-backup';
  static const String weatherSettings = '/weather-settings';
  static const String userGuide = '/user-guide';
  static const String aboutApp = '/about-app';
  static const String inviteCode = '/invite-code';
  static const String joinFamily = '/join';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
  static const String screenTimeSettings = '/settings/screen-time';
  static const String securitySettings = '/settings/security';
  static const String securityQuestionsSetup = '/settings/security-questions';
  static const String familyPermissions = '/settings/family-permissions';
  static const String familySuggestionsSettings = '/settings/family-suggestions';
  static const String activities = '/activities';
  static const String streak = '/streak';
  static const String leaderboard = '/leaderboard';
  static const String smartReminders = '/smart-reminders';
  static const String smartReminderCreate = '/smart-reminder/create';
  static const String smartReminderDetail = '/smart-reminder/:id';
  static const String routines = '/routines';
  static const String routineCreate = '/routine/create';
  static const String routineDetail = '/routine/:id';
  static const String crashSettings = '/crash-settings';
  static const String crashHistory = '/crash-history';
  static const String crashConfirmation = '/crash-confirmation';
  static const String crashFamilyAlert = '/crash-family-alert';
  static const String locationTrackingSettings = '/location-tracking-settings';
  static const String liveLocation = '/live-location';
  static const String batteryAnalytics = '/battery-analytics';
  static const String sosMain = '/sos';
  static const String sosActive = '/sos-active';
  static const String sosSettings = '/sos-settings';
  static const String sosTemplateEditor = '/sos-template-editor';
  static const String forgotPassword = '/forgot-password';
  static const String childLogin = '/child-login';
  static const String childDashboard = '/child-dashboard';
  static const String childManagement = '/child-management';
  static const String childDetail = '/child/:id';
  static const String addTask = '/add-task';
  static const String callContactList = '/call/contact-list';
  static const String contacts = '/contacts';
  static const String gallery = '/gallery';
  static const String kitchen = '/kitchen';
  static const String education = '/education';
  static const String documents = '/documents';
  static const String familyMap = '/family-map';
  static const String familyHealth = '/family-health';
  static const String subscriptions = '/subscriptions';
  static const String childDevelopment = '/child-development';
  static const String aiAssistant = '/ai-assistant';
}

final _publicRoutes = <String>{
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.childLogin,
  AppRoutes.childDashboard,
  AppRoutes.termsOfService,
  AppRoutes.privacyPolicy,
};

String? _authGuard(BuildContext context, GoRouterState state) {
  final isLoggedIn = AuthService.currentUserId != null || ChildAuthService.isChildMode;
  final isPublic = _publicRoutes.contains(state.matchedLocation);

  if (!isLoggedIn && !isPublic) {
    return AppRoutes.login;
  }
  if (isLoggedIn && (state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register)) {
    return AppRoutes.hub;
  }
  return null;
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: _authGuard,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
    GoRoute(path: AppRoutes.register, builder: (context, state) => const RegistrationWizardScreen()),
    GoRoute(path: AppRoutes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.hub, builder: (context, state) => const HubScreen()),
        GoRoute(path: AppRoutes.tasks, builder: (context, state) => const TasksScreen()),
        GoRoute(path: AppRoutes.smartRotation, builder: (context, state) => SmartRotationScreen(familyId: state.extra as String?)),
        GoRoute(path: AppRoutes.calendarSync, builder: (context, state) => const CalendarSyncScreen()),
        GoRoute(path: AppRoutes.calendar, builder: (context, state) => const CalendarScreen()),
        GoRoute(path: AppRoutes.shopping, builder: (context, state) => const ShoppingListScreen()),
        GoRoute(path: AppRoutes.budget, builder: (context, state) => const BudgetScreen()),
        GoRoute(path: AppRoutes.family, builder: (context, state) => const FamilyScreen()),
        GoRoute(path: AppRoutes.chat, builder: (context, state) => const ChatScreen()),
        GoRoute(path: AppRoutes.mood, builder: (context, state) => const MoodScreen()),
        GoRoute(path: AppRoutes.safety, builder: (context, state) => const SafetyScreen()),
        GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
        GoRoute(path: AppRoutes.memories, builder: (context, state) => const MemoriesScreen()),
        GoRoute(path: AppRoutes.kitchen, builder: (context, state) => const KitchenScreen()),
        GoRoute(path: AppRoutes.education, builder: (context, state) => const EducationScreen()),
        GoRoute(path: AppRoutes.familyMap, builder: (context, state) => const FamilyMapScreen()),
      ],
    ),
    GoRoute(path: AppRoutes.location, builder: (context, state) => const LocationScreen()),
    GoRoute(path: AppRoutes.emergency, builder: (context, state) => const SosMainScreen()),
    GoRoute(path: AppRoutes.healthCard, builder: (context, state) => const HealthCardScreen()),
    GoRoute(path: AppRoutes.safeZones, builder: (context, state) => const SafeZonesScreen()),
    GoRoute(path: AppRoutes.safeArrival, builder: (context, state) => const SafeArrivalScreen()),
    GoRoute(path: AppRoutes.ambientListening, builder: (context, state) => const AmbientListeningScreen()),
    GoRoute(path: AppRoutes.flashlight, builder: (context, state) => const FlashlightScreen()),
    GoRoute(path: AppRoutes.album, builder: (context, state) => const AlbumScreen()),
    GoRoute(path: AppRoutes.memoryCreate, builder: (context, state) => const MemoryCreateScreen()),
    GoRoute(path: AppRoutes.growth, builder: (context, state) => const GrowthScreen()),
    GoRoute(path: AppRoutes.premium, builder: (context, state) => const PremiumScreen()),
    GoRoute(path: AppRoutes.familyManage, builder: (context, state) => const FamilyManageScreen()),
    GoRoute(path: AppRoutes.profileEdit, builder: (context, state) => const ProfileEditScreen()),
    GoRoute(path: AppRoutes.notificationSettings, builder: (context, state) => const NotificationSettingsScreen()),
    GoRoute(path: AppRoutes.privacySettings, builder: (context, state) => const PrivacySettingsScreen()),
    GoRoute(path: AppRoutes.languageSettings, builder: (context, state) => const LanguageSettingsScreen()),
    GoRoute(path: AppRoutes.backupSettings, builder: (context, state) => const BackupSettingsScreen()),
    GoRoute(path: AppRoutes.appearanceSettings, builder: (context, state) => const AppearanceSettingsScreen()),
    GoRoute(path: AppRoutes.hubCustomize, builder: (context, state) => const HubCustomizeScreen()),
    GoRoute(path: AppRoutes.googleDriveBackup, builder: (context, state) => const CloudBackupScreen()),
    GoRoute(path: AppRoutes.weatherSettings, builder: (context, state) => const WeatherSettingsScreen()),
    GoRoute(path: AppRoutes.userGuide, builder: (context, state) => const UserGuideScreen()),
    GoRoute(path: AppRoutes.aboutApp, builder: (context, state) => const AboutAppScreen()),
    GoRoute(path: AppRoutes.inviteCode, builder: (context, state) => const InviteCodeScreen()),
    GoRoute(
      path: AppRoutes.joinFamily,
      builder: (context, state) => JoinFamilyScreen(
        initialCode: state.uri.queryParameters['code'],
      ),
    ),
    GoRoute(path: AppRoutes.termsOfService, builder: (context, state) => const TermsOfServiceScreen()),
    GoRoute(path: AppRoutes.privacyPolicy, builder: (context, state) => const PrivacyPolicyScreen()),
    GoRoute(path: AppRoutes.screenTimeSettings, builder: (context, state) => const ScreenTimeSettingsScreen()),
    GoRoute(path: AppRoutes.securitySettings, builder: (context, state) => const SecuritySettingsScreen()),
    GoRoute(path: AppRoutes.securityQuestionsSetup, builder: (context, state) => const SecurityQuestionsSetupScreen()),
    GoRoute(path: AppRoutes.familyPermissions, builder: (context, state) => const FamilyPermissionsScreen()),
    GoRoute(path: AppRoutes.familySuggestionsSettings, builder: (context, state) => const FamilySuggestionSettingsScreen()),
    GoRoute(path: AppRoutes.activities, builder: (context, state) => const ActivitiesScreen()),
    GoRoute(path: AppRoutes.streak, builder: (context, state) => const StreakScreen()),
    GoRoute(path: AppRoutes.leaderboard, builder: (context, state) => const LeaderboardScreen()),
    GoRoute(path: AppRoutes.smartReminders, builder: (context, state) => const SmartRemindersScreen()),
    GoRoute(path: AppRoutes.smartReminderCreate, builder: (context, state) => const SmartReminderCreateScreen()),
    GoRoute(
      path: AppRoutes.smartReminderDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SmartReminderDetailScreen(reminderId: id);
      },
    ),
    GoRoute(path: AppRoutes.routines, builder: (context, state) => const RoutinesScreen()),
    GoRoute(
      path: AppRoutes.routineDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RoutineDetailScreen(routineId: id);
      },
    ),
    GoRoute(path: AppRoutes.routineCreate, builder: (context, state) => const RoutineDetailScreen(routineId: '')),
    GoRoute(path: AppRoutes.crashSettings, builder: (context, state) => const CrashSettingsScreen()),
    GoRoute(path: AppRoutes.crashHistory, builder: (context, state) => const CrashHistoryScreen()),
    GoRoute(
      path: AppRoutes.crashConfirmation,
      builder: (context, state) {
        final event = state.extra;
        if (event is! CrashEvent) {
          return const Scaffold(body: Center(child: Text('Geçersiz kaza verisi')));
        }
        return CrashConfirmationScreen(event: event);
      },
    ),
    GoRoute(
      path: AppRoutes.crashFamilyAlert,
      builder: (context, state) {
        final event = state.extra;
        if (event is! CrashEvent) {
          return const Scaffold(body: Center(child: Text('Geçersiz kaza verisi')));
        }
        return CrashFamilyAlertScreen(event: event);
      },
    ),
    GoRoute(path: AppRoutes.locationTrackingSettings, builder: (context, state) => const LocationTrackingSettingsScreen()),
    GoRoute(path: AppRoutes.liveLocation, builder: (context, state) => const LiveLocationScreen()),
    GoRoute(path: AppRoutes.batteryAnalytics, builder: (context, state) => const BatteryAnalyticsScreen()),
    GoRoute(path: AppRoutes.sosMain, builder: (context, state) => const SosMainScreen()),
    GoRoute(path: AppRoutes.sosActive, builder: (context, state) => const SosActiveScreen()),
    GoRoute(path: AppRoutes.sosSettings, builder: (context, state) => const SosSettingsScreen()),
    GoRoute(path: AppRoutes.sosTemplateEditor, builder: (context, state) => const SosTemplateEditorScreen()),
    GoRoute(path: AppRoutes.childLogin, builder: (context, state) => const ChildLoginScreen()),
    GoRoute(path: AppRoutes.childDashboard, builder: (context, state) => const ChildDashboardScreen()),
    GoRoute(path: AppRoutes.childManagement, builder: (context, state) => const ChildManagementScreen()),
    GoRoute(
      path: AppRoutes.childDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ChildDetailScreen(childId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.addTask,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Map<String, dynamic>) {
          return const Scaffold(body: Center(child: Text('Invalid parameters')));
        }
        return AddTaskScreen(
          childId: extra['childId'] as String? ?? '',
          familyId: extra['familyId'] as String? ?? '',
        );
      },
    ),
    GoRoute(path: AppRoutes.callContactList, builder: (context, state) => const CallContactListScreen()),
    GoRoute(path: AppRoutes.contacts, builder: (context, state) => const ContactsScreen()),
    GoRoute(path: AppRoutes.gallery, builder: (context, state) => const GalleryScreen()),
    GoRoute(path: AppRoutes.documents, builder: (context, state) => const DocumentsScreen()),
    GoRoute(path: AppRoutes.familyHealth, builder: (context, state) => const HealthDashboard()),
    GoRoute(path: AppRoutes.subscriptions, builder: (context, state) => const SubscriptionScreen()),
    GoRoute(path: AppRoutes.childDevelopment, builder: (context, state) => const ChildDevelopmentHome()),
    GoRoute(path: AppRoutes.aiAssistant, builder: (context, state) => const AIAssistantScreen()),
  ],
);
