import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:familyhub/features/subscription/application/subscription_providers.dart';
import 'package:familyhub/features/subscription/domain/subscription_tier.dart';
import 'package:familyhub/features/subscription/presentation/plans_screen.dart';
import 'package:familyhub/features/subscription/presentation/feature_gate.dart';

Widget _wrap(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: home,
      ),
    );

void main() {
  testWidgets('PlansScreen 3 katmanı + fiyatı gösterir, mevcut plan rozetli',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const PlansScreen(), [
      currentTierProvider.overrideWithValue(SubscriptionTier.basic),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Temel'), findsOneWidget);
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    // Aylık fiyatlar (varsayılan aylık görünüm)
    expect(find.text('€4.99/ay'), findsOneWidget);
    expect(find.text('€7.99/ay'), findsOneWidget);
    // Basic mevcut plan → MEVCUT rozeti
    expect(find.text('MEVCUT'), findsOneWidget);
    expect(find.text('POPÜLER'), findsOneWidget);
  });

  testWidgets('Yıllık toggle → yıllık fiyat ve tasarruf rozeti', (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const PlansScreen(), [
      currentTierProvider.overrideWithValue(SubscriptionTier.basic),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yıllık'));
    await tester.pumpAndSettle();

    expect(find.text('€39.99/yıl'), findsOneWidget);
    expect(find.text('%33 tasarruf'), findsOneWidget);
  });

  testWidgets('FeatureGateSheet kilitli özellik için doğru planı gösterir',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const Scaffold(body: FeatureGateSheet(feature: Feature.familyRoutines)),
      [currentTierProvider.overrideWithValue(SubscriptionTier.basic)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bu özellik kilitli'), findsOneWidget);
    // familyRoutines → complete planında açılır
    expect(find.textContaining('Complete'), findsWidgets);
    expect(find.text('Planları gör'), findsOneWidget);
  });
}
