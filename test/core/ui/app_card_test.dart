import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/ui/app_card.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(child: const Text('Card Content')),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: const EdgeInsets.all(32),
              child: const Text('Padded'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(Card), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.all(32));
    });

    testWidgets('onTap callback works', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });
  });
}
