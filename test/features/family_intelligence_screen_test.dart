import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:familyhub/features/family_intelligence/application/family_intelligence_providers.dart';
import 'package:familyhub/features/family_intelligence/domain/family_insight.dart';
import 'package:familyhub/features/family_intelligence/presentation/family_intelligence_screen.dart';

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('tr'),
        home: FamilyIntelligenceScreen(),
      ),
    );

void main() {
  testWidgets('içgörü varsa başlık + kart görünür', (tester) async {
    await tester.pumpWidget(_wrap([
      familyInsightsProvider.overrideWithValue(const [
        FamilyInsight(
          id: 'overdue_tasks',
          type: InsightType.warning,
          module: InsightModule.tasks,
          priority: InsightPriority.high,
          titleKey: 'fiInsightOverdueTitle',
          bodyKey: 'fiInsightOverdueBody',
          args: {'count': '3'},
          reasonKey: 'fiReasonOverdue',
        ),
      ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Aile Zekası'), findsOneWidget); // AppBar başlığı
    expect(find.text('Geciken görevler'), findsOneWidget); // içgörü başlığı
    expect(find.textContaining('Öne çıkanı bildir'), findsOneWidget);
  });

  testWidgets('içgörü yoksa boş durum görünür', (tester) async {
    await tester.pumpWidget(_wrap([
      familyInsightsProvider.overrideWithValue(const []),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Şu an öne çıkan bir şey yok'), findsOneWidget);
  });

  testWidgets('"neden gösterildi" genişletilince sebep görünür', (tester) async {
    await tester.pumpWidget(_wrap([
      familyInsightsProvider.overrideWithValue(const [
        FamilyInsight(
          id: 'overdue_tasks',
          type: InsightType.warning,
          module: InsightModule.tasks,
          priority: InsightPriority.high,
          titleKey: 'fiInsightOverdueTitle',
          bodyKey: 'fiInsightOverdueBody',
          args: {'count': '2'},
          reasonKey: 'fiReasonOverdue',
        ),
      ]),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Neden gösterildi'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Bitiş tarihi geçmiş'), findsOneWidget);
  });
}
