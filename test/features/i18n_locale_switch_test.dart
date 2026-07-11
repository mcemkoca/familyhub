import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/l10n/app_localizations.dart';

/// Dil değişiminin dönüştürülmüş ekran metinlerine yansıdığının KANITI.
/// Orijinal hata: dil değişince bazı metinler aynı kalıyordu (hard-coded).
/// Bu test locale değişince aynı anahtarın farklı dilde render edildiğini
/// ve beklenen çeviriyi verdiğini doğrular (tr/en/fr/nl).
void main() {
  // Her modülden temsili, bu oturumda dönüştürülmüş anahtarlar.
  final cases = <String, String Function(AppLocalizations)>{
    'setAccount': (t) => t.setAccount, // ayarlar
    'cdCreateProfile': (t) => t.cdCreateProfile, // çocuk gelişim
    'fhFamilyDoctor': (t) => t.fhFamilyDoctor, // aile sağlığı
    'eduTitle': (t) => t.eduTitle, // eğitim
    'kitNewFoodIdea': (t) => t.kitNewFoodIdea, // mutfak
    'chatCreatePoll': (t) => t.chatCreatePoll, // sohbet
    'subHomeExpenses': (t) => t.subHomeExpenses, // ev giderleri
    'srBasicInfo': (t) => t.srBasicInfo, // hatırlatıcı
    'budIncome': (t) => t.budIncome, // bütçe
  };

  final expected = <String, Map<String, String>>{
    'setAccount': {'tr': 'HESAP', 'en': 'ACCOUNT', 'fr': 'COMPTE', 'nl': 'ACCOUNT'},
    'fhFamilyDoctor': {
      'tr': 'Aile Hekimi',
      'en': 'Family Doctor',
      'fr': 'Medecin de famille',
      'nl': 'Huisarts'
    },
    'budIncome': {'tr': 'Gelir', 'en': 'Income', 'fr': 'Revenu', 'nl': 'Inkomsten'},
  };

  Future<AppLocalizations> load(WidgetTester tester, Locale locale) async {
    late AppLocalizations t;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        t = AppLocalizations.of(context);
        return const SizedBox();
      }),
    ));
    await tester.pump();
    return t;
  }

  testWidgets('her dönüştürülmüş anahtar 4 dilde de boş olmayan değer döndürür',
      (tester) async {
    for (final code in ['tr', 'en', 'fr', 'nl']) {
      final t = await load(tester, Locale(code));
      for (final entry in cases.entries) {
        final value = entry.value(t);
        expect(value.trim(), isNotEmpty,
            reason: '$code/${entry.key} boş olmamalı');
      }
    }
  });

  testWidgets('locale değişince aynı anahtar FARKLI dilde metin verir',
      (tester) async {
    // setAccount: tr=HESAP, en=ACCOUNT, fr=COMPTE → hepsi farklı
    final tr = await load(tester, const Locale('tr'));
    final en = await load(tester, const Locale('en'));
    final fr = await load(tester, const Locale('fr'));
    expect(tr.setAccount, isNot(equals(en.setAccount)));
    expect(en.setAccount, isNot(equals(fr.setAccount)));
    expect(tr.fhFamilyDoctor, isNot(equals(en.fhFamilyDoctor)));
  });

  testWidgets('beklenen çeviriler birebir doğru', (tester) async {
    for (final code in ['tr', 'en', 'fr', 'nl']) {
      final t = await load(tester, Locale(code));
      expected.forEach((key, byLocale) {
        expect(cases[key]!(t), byLocale[code],
            reason: '$code/$key beklenen çeviriyle eşleşmeli');
      });
    }
  });

  testWidgets('placeholder çevirileri locale-aware çalışır', (tester) async {
    final tr = await load(tester, const Locale('tr'));
    final en = await load(tester, const Locale('en'));
    expect(tr.cdDevGroup('A'), contains('grubu'));
    expect(en.cdDevGroup('A'), contains('group'));
    expect(tr.subAmount('€'), contains('Tutar'));
    expect(en.subAmount('€'), contains('Amount'));
  });
}
