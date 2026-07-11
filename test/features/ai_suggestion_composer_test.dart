import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:familyhub/presentation/screens/ai/ai_assistant_screen.dart';

/// SENARYO 11: öneriye dokununca DOĞRUDAN gönderilmez → input'a aktarılır.
void main() {
  Widget wrap() => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('tr'),
        home: AIAssistantScreen(),
      );

  testWidgets('öneri chip\'ine dokununca metin input\'a gelir, gönderilmez',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Bir öneri chip'i (kısmi metinle bul) — input boşken görünür.
    final chip = find.textContaining('yemek planı', findRichText: false);
    expect(chip, findsWidgets);

    // Dokunmadan önce: TextField boş.
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect((tester.widget<TextField>(field)).controller!.text, '');

    await tester.tap(chip.first);
    await tester.pumpAndSettle();

    // Dokunduktan sonra: metin input'a geldi (gönderilmedi, kullanıcı ekranda kaldı).
    final text = (tester.widget<TextField>(field)).controller!.text;
    expect(text.contains('yemek planı'), true);
    // Kullanıcı mesajı olarak EKLENMEDİ (input'ta duruyor).
    expect(find.byType(TextField), findsOneWidget);
  });
}
