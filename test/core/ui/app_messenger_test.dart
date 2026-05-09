import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/ui/app_messenger.dart';

void main() {
  group('AppMessenger', () {
    testWidgets('showSuccess displays green SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppMessenger.showSuccess(context, 'Success!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Success!'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green);
    });

    testWidgets('showError displays red SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppMessenger.showError(context, 'Error!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Error!'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets('showInfo displays blue SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppMessenger.showInfo(context, 'Info!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Info!'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.blue);
    });

    testWidgets('showWarning displays orange SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppMessenger.showWarning(context, 'Warning!'),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Warning!'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.orange);
    });
  });
}
