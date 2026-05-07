# SPRINT 4: UX, L10N, POLISH
## 5 Orta Oncelikli Sorun | Hedef: Mükemmel Kullanici Deneyimi

---

## 18. flutter_localizations + .arb Dosyalari

**Sorun:** 42+ ekran hardcoded Türkce

### pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  provider: ^6.1.0

flutter:
  generate: true
```

### l10n.yaml
```yaml
arb-dir: lib/l10n
template-arb-file: app_tr.arb
output-localization-file: app_localizations.dart
```

### lib/l10n/app_tr.arb (Türkce)
```json
{
  "@@locale": "tr",
  "appTitle": "Aile Asistani",
  "@appTitle": {"description": "Uygulama basligi"},

  "smartRotationTitle": "Akilli Gorev Rotasyonu",
  "loadingTasks": "Gorevler yukleniyor...",
  "retry": "Tekrar Dene",
  "errorLoadingData": "Veriler yuklenemedi",
  "errorDatabaseSecurity": "Veritabani guvenlik ayarlari nedeniyle veriye erisilemiyor.",

  "today": "Bugun",
  "tomorrow": "Yarin",
  "yesterday": "Dun",

  "difficultyEasy": "Kolay",
  "difficultyMedium": "Orta",
  "difficultyHard": "Zor",

  "fairnessScore": "Adil Dagilim Skoru",
  "weeklyLoadBalanced": "Haftalik Yuk Dengeli",
  "weeklyLoadUnbalanced": "Haftalik Yuk Dengesiz",

  "noTasksToday": "Bugun icin gorev yok",
  "addTaskHint": "Yeni gorev eklemek icin + butonuna tiklayin",

  "family": "Aile",
  "plan": "Plan",
  "chat": "Sohbet",
  "security": "Guvenlik",
  "settings": "Ayarlar",
  "profile": "Profil",
  "notifications": "Bildirimler",

  "cancel": "Iptal",
  "save": "Kaydet",
  "delete": "Sil",
  "edit": "Duzenle",
  "confirm": "Onayla",
  "close": "Kapat",

  "emergencyContact": "Acil Durum Kisisi",
  "emergencyCall": "Acil Durum Ara",
  "sos": "SOS",

  "premiumFeature": "Premium Ozellik",
  "upgradeToPremium": "Premium'a Yukselt",

  "offlineMode": "Cevrimdisi Mod",
  "syncRequired": "Senkronizasyon Gerekli",

  "welcome": "Hos Geldiniz",
  "onboardingStep1": "Ailenizi olusturun",
  "onboardingStep2": "Gorevleri dagitin",
  "onboardingStep3": "Guvenli kalin"
}
```

### lib/l10n/app_en.arb (Ingilizce)
```json
{
  "@@locale": "en",
  "appTitle": "Family Assistant",
  "smartRotationTitle": "Smart Task Rotation",
  "loadingTasks": "Loading tasks...",
  "retry": "Retry",
  "errorLoadingData": "Failed to load data",
  "errorDatabaseSecurity": "Unable to access data due to database security settings.",
  "today": "Today",
  "tomorrow": "Tomorrow",
  "yesterday": "Yesterday",
  "difficultyEasy": "Easy",
  "difficultyMedium": "Medium",
  "difficultyHard": "Hard",
  "fairnessScore": "Fairness Score",
  "weeklyLoadBalanced": "Weekly Load Balanced",
  "weeklyLoadUnbalanced": "Weekly Load Unbalanced",
  "noTasksToday": "No tasks for today",
  "addTaskHint": "Tap + to add a new task",
  "family": "Family",
  "plan": "Plan",
  "chat": "Chat",
  "security": "Security",
  "settings": "Settings",
  "profile": "Profile",
  "notifications": "Notifications",
  "cancel": "Cancel",
  "save": "Save",
  "delete": "Delete",
  "edit": "Edit",
  "confirm": "Confirm",
  "close": "Close",
  "emergencyContact": "Emergency Contact",
  "emergencyCall": "Emergency Call",
  "sos": "SOS",
  "premiumFeature": "Premium Feature",
  "upgradeToPremium": "Upgrade to Premium",
  "offlineMode": "Offline Mode",
  "syncRequired": "Sync Required",
  "welcome": "Welcome",
  "onboardingStep1": "Create your family",
  "onboardingStep2": "Distribute tasks",
  "onboardingStep3": "Stay safe"
}
```

### lib/main.dart
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: context.watch<LocaleProvider>().currentLocale,
      // ... diger ayarlar
    );
  }
}
```

### Kullanim:
```dart
Text(AppLocalizations.of(context)!.smartRotationTitle)
```

---

## 19. Dil Degistirme Calissin

**Sorun:** `language_settings_screen` seciyor ama locale degistirmiyor

### lib/features/settings/providers/locale_provider.dart
```dart
class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('tr');
  Locale get currentLocale => _currentLocale;

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = Locale(prefs.getString('app_language') ?? 'tr');
    notifyListeners();
  }
}
```

### lib/features/settings/screens/language_settings_screen.dart
```dart
class LanguageSettingsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> languages = [
    {'code': 'tr', 'name': 'Türkce', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = localeProvider.currentLocale.languageCode == lang['code'];

          return ListTile(
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(lang['name']!),
            trailing: isSelected 
                ? const Icon(Icons.check_circle, color: Colors.blue) 
                : null,
            onTap: () => localeProvider.setLocale(lang['code']!),
          );
        },
      ),
    );
  }
}
```

---

## 20. Theme Token Tamamlama

**Sorun:** snackBarTheme, bottomSheetTheme, chipTheme, tooltipTheme, navigationBarTheme, iconTheme, sliderTheme eksik

### lib/core/theme/app_theme.dart
```dart
class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0f172a),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3b82f6),
        brightness: Brightness.dark,
        surface: const Color(0xFF1e293b),
        onSurface: const Color(0xFFf8fafc),
      ),

      // EKSIK TEMALAR:
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1e293b),
        contentTextStyle: const TextStyle(color: Color(0xFFf8fafc)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: const Color(0xFF3b82f6),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1e293b),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalBackgroundColor: const Color(0xFF0f172a).withOpacity(0.8),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        selectedColor: const Color(0xFF3b82f6),
        labelStyle: const TextStyle(color: Color(0xFFf8fafc)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Color(0xFFf8fafc), fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1e293b),
        indicatorColor: const Color(0xFF3b82f6).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Color(0xFF94a3b8)),
        ),
      ),

      iconTheme: const IconThemeData(color: Color(0xFF94a3b8)),

      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF3b82f6),
        inactiveTrackColor: const Color(0xFF334155),
        thumbColor: const Color(0xFF3b82f6),
        overlayColor: const Color(0xFF3b82f6).withOpacity(0.2),
        trackHeight: 4,
      ),

      cardTheme: CardTheme(
        color: const Color(0xFF1e293b),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1e293b),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3b82f6)),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94a3b8)),
        hintStyle: const TextStyle(color: Color(0xFF64748b)),
      ),
    );
  }
}
```

---

## 21. Background Servisleri Baslat

**Sorun:** LocationTracking, CrashDetection, Safety, AmbientListening, Call main.dart'ta baslatilmiyor

### pubspec.yaml
```yaml
dependencies:
  workmanager: ^0.5.2
  geolocator: ^13.0.0
  sensors_plus: ^6.1.0
  flutter_background_service: ^5.1.0
  audio_service: ^0.18.15
```

### lib/main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Supabase
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // 3. Error tracking (runApp ONCESI!)
  await ErrorService.initialize();

  // 4. Local cache
  await Hive.initFlutter();

  // 5. Background servisleri BASLAT
  await _initializeBackgroundServices();

  // 6. Locale yukle
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        // ... diger provider'lar
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeBackgroundServices() async {
  await LocationTrackingService.initialize();
  await CrashDetectionService.initialize();
  await SafetyMonitoringService.initialize();
  await AmbientListeningService.initialize();
  await CallMonitoringService.initialize();

  // WorkManager periyodik isler
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    'sync-task', 'periodicSync',
    frequency: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

// WorkManager callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'periodicSync':
        await SyncService.performPeriodicSync();
        break;
    }
    return Future.value(true);
  });
}
```

---

## 22. Orphan Dosyalari Temizle / Route'la

**Sorun:** leaderboard_screen.dart, profile_editor_screen.dart, emergency_screen.dart route'lanmamis

### lib/core/navigation/app_router.dart
```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      // ... mevcut route'lar

      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditorScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
    ],
  );
}
```

### Navigation baglantilari:
```dart
// Bottom navigation veya menu'den erisim:
ListTile(
  leading: const Icon(Icons.leaderboard),
  title: const Text('Liderlik Tablosu'),
  onTap: () => context.push('/leaderboard'),
)
```

---

## Kontrol Listesi

- [ ] flutter_localizations kurulu, .arb dosyalari olusturuldu
- [ ] Dil degistirme anlik calisiyor (provider + notifyListeners)
- [ ] Theme token'lari tamam (snackBar, bottomSheet, chip, tooltip, navBar, icon, slider)
- [ ] Background servisleri main.dart'ta baslatiliyor
- [ ] WorkManager periyodik sync calisiyor
- [ ] Orphan dosyalar route'landi
- [ ] Dark mode gercek cihazda test edildi

---
**Versiyon:** 1.0 | **Sprint:** 4/4 | **Hedef:** Mükemmel Kullanici Deneyimi
