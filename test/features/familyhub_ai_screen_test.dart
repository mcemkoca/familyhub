import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:familyhub/features/family_intelligence/application/family_intelligence_providers.dart';
import 'package:familyhub/features/family_intelligence/application/family_intelligence_engine.dart';
import 'package:familyhub/features/familyhub_ai/application/familyhub_ai_providers.dart';
import 'package:familyhub/features/familyhub_ai/domain/ai_action.dart';
import 'package:familyhub/features/familyhub_ai/presentation/familyhub_ai_screen.dart';

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('tr'),
        home: FamilyHubAIScreen(),
      ),
    );

void main() {
  testWidgets('başlık + bağlam özeti + hızlı aksiyon görünür', (tester) async {
    await tester.pumpWidget(_wrap([
      familySnapshotProvider.overrideWithValue(
          const FamilySnapshot(pendingTasks: 2, memberCount: 3)),
      aiQuickActionsProvider.overrideWithValue(const [
        AIQuickAction(
          labelKey: 'fhaQuickBudget',
          action: AIAction(
              type: AIActionType.summarizeBudget, route: '/budget'),
        ),
      ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('FamilyHub AI'), findsOneWidget);
    expect(find.text('Bugünün bağlamı'), findsOneWidget);
    expect(find.text('Bütçeyi özetle'), findsOneWidget);
    // Güvenlik/gizlilik disclaimer'ı görünür
    expect(find.textContaining('kesin tavsiye değildir'), findsOneWidget);
  });

  testWidgets('onay gerektiren aksiyona dokununca preview dialogu açılır',
      (tester) async {
    await tester.pumpWidget(_wrap([
      familySnapshotProvider
          .overrideWithValue(const FamilySnapshot(memberCount: 2)),
      aiQuickActionsProvider.overrideWithValue(const [
        AIQuickAction(
          labelKey: 'fhaQuickAddItems',
          action: AIAction(
            type: AIActionType.addShoppingItems,
            route: '/shopping',
            payload: {'items': ['Süt', 'Ekmek']},
          ),
        ),
      ]),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Önerilen ürünleri ekle'));
    await tester.pumpAndSettle();

    // Onay dialogu + önizlenen ürünler
    expect(find.text('Bu işlemi onaylıyor musun?'), findsOneWidget);
    expect(find.text('Süt'), findsOneWidget);
    expect(find.text('Ekmek'), findsOneWidget);
    expect(find.text('Onayla'), findsOneWidget);

    // İptal → dialog kapanır (kritik işlem onaysız yapılmaz)
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.text('Bu işlemi onaylıyor musun?'), findsNothing);
  });
}
