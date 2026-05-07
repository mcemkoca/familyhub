import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:familyhub/main.dart' as app;

/// Automated login and app walkthrough test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FamilyHub Auto Login & Walkthrough', () {
    testWidgets('Login with admin credentials and explore screens', (tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 2. Skip onboarding if present
      final hasOnboarding = find.text('Güvende Kalın').evaluate().isNotEmpty;
      if (hasOnboarding) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        final startButton = find.text('Başla');
        if (startButton.evaluate().isNotEmpty) {
          await tester.tap(startButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // 3. Should be on login screen
      expect(find.text('Giriş Yap').evaluate().isNotEmpty, isTrue,
          reason: 'Should see login screen');

      // 4. Enter credentials
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      const testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
      const testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
      if (testEmail.isEmpty || testPassword.isEmpty) {
        fail('TEST_EMAIL and TEST_PASSWORD must be set via --dart-define');
      }
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);
      await tester.pumpAndSettle();

      // 5. Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 6. Verify we're past login (Hub or main shell should appear)
      // Look for hub-specific text or bottom nav
      final hasHub = find.text('Aile Takvimi').evaluate().isNotEmpty ||
                     find.text('Hub').evaluate().isNotEmpty ||
                     find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      
      expect(hasHub, isTrue, reason: 'Should reach main app after login');

      // 7. Navigate through bottom tabs if available
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Tap each tab
        final icons = find.descendant(
          of: bottomNav,
          matching: find.byType(Icon),
        );
        final count = icons.evaluate().length;
        for (var i = 0; i < count.clamp(0, 5); i++) {
          await tester.tap(icons.at(i));
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      // 8. Try to open safety screen
      final safetyIcon = find.byIcon(Icons.shield_outlined);
      if (safetyIcon.evaluate().isNotEmpty) {
        await tester.tap(safetyIcon.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 9. Try to open calendar
      final calendarIcon = find.byIcon(Icons.calendar_today);
      if (calendarIcon.evaluate().isNotEmpty) {
        await tester.tap(calendarIcon.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 10. Try to open budget
      final budgetIcon = find.byIcon(Icons.account_balance_wallet);
      if (budgetIcon.evaluate().isNotEmpty) {
        await tester.tap(budgetIcon.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    });
  });
}
