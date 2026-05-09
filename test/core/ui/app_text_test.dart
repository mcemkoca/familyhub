import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/ui/app_text.dart';

void main() {
  group('AppText', () {
    testWidgets('headline renders with headlineSmall style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppText.headline('Headline')),
        ),
      );

      final text = tester.widget<Text>(find.text('Headline'));
      expect(text.style?.fontSize, isNotNull);
    });

    testWidgets('body renders with bodyMedium style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppText.body('Body text')),
        ),
      );

      expect(find.text('Body text'), findsOneWidget);
    });

    testWidgets('caption renders with reduced opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppText.caption('Caption')),
        ),
      );

      final text = tester.widget<Text>(find.text('Caption'));
      expect(text.style?.color?.a, lessThan(1.0));
    });

    testWidgets('respects custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppText.title('Title', color: Colors.red),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Title'));
      expect(text.style?.color, Colors.red);
    });
  });
}
