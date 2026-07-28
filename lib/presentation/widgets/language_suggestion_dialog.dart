import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../services/localization/locale_service.dart';
import '../providers/app_providers.dart';

/// İlk açılışta (kullanıcı henüz dil kararı vermediyse) cihaz dilini ONAYLA
/// dialogu. Sessiz otomatik değişiklik YAPMAZ — kullanıcı açıkça karar verir.
/// Meta-dialog olduğundan metinler iç lokalize haritayla (cihaz diline göre) verilir.
class LanguageSuggestionDialog {
  LanguageSuggestionDialog._();

  /// Gerekliyse dialogu gösterir (karar verilmemiş + kayıtlı dil yoksa).
  /// Bir kez gösterildikten sonra kararı kalıcılaştırır → tekrar gösterilmez.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (!LocaleService.shouldSuggestLanguage()) return;
    // İlk frame sonrası, güvenli göster.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;

    final code = LocaleService.deviceSupportedCode();
    final uiCode = code ?? 'tr'; // dialog metinleri hangi dilde
    final t = _strings[uiCode] ?? _strings['tr']!;
    final langName = LocaleService.deviceLanguageLabel();
    final supported = code != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Text(t.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          supported ? t.body(langName) : t.unsupported,
          style: const TextStyle(color: Color(0xFFD1D5DB), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          if (supported)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1)),
                onPressed: () async {
                  await LocaleService.acceptDeviceLocale();
                  ref.read(localeProvider.notifier).state =
                      LocaleService.localeForLabel(langName);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(t.useDevice(langName)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await LocaleService.dismissSuggestion();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  context.push(AppRoutes.languageSettings);
                }
              },
              child: Text(t.pickOther,
                  style: const TextStyle(color: Color(0xFF8B5CF6))),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await LocaleService.dismissSuggestion();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(t.keep,
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
            ),
          ),
        ],
      ),
    );
  }
}

class _T {
  final String title;
  final String Function(String lang) body;
  final String Function(String lang) useDevice;
  final String pickOther;
  final String keep;
  final String unsupported;
  const _T({
    required this.title,
    required this.body,
    required this.useDevice,
    required this.pickOther,
    required this.keep,
    required this.unsupported,
  });
}

const _strings = <String, _T>{
  'tr': _T(
    title: 'Dil tercihi',
    body: _bodyTr,
    useDevice: _useTr,
    pickOther: 'Başka bir dil seç',
    keep: 'Şimdilik mevcut dille devam et',
    unsupported:
        'Cihaz diliniz henüz desteklenmiyor. Kullanmak istediğiniz dili seçin.',
  ),
  'en': _T(
    title: 'Language preference',
    body: _bodyEn,
    useDevice: _useEn,
    pickOther: 'Choose another language',
    keep: 'Continue with the current language',
    unsupported:
        'Your device language is not supported yet. Please choose a language.',
  ),
  'fr': _T(
    title: 'Preference de langue',
    body: _bodyFr,
    useDevice: _useFr,
    pickOther: 'Choisir une autre langue',
    keep: 'Continuer avec la langue actuelle',
    unsupported:
        "La langue de votre appareil n'est pas encore prise en charge. Choisissez une langue.",
  ),
  'nl': _T(
    title: 'Taalvoorkeur',
    body: _bodyNl,
    useDevice: _useNl,
    pickOther: 'Kies een andere taal',
    keep: 'Doorgaan met de huidige taal',
    unsupported:
        'De taal van je apparaat wordt nog niet ondersteund. Kies een taal.',
  ),
};

String _bodyTr(String l) =>
    'Cihaz diliniz $l olarak algılandı. FamilyHub\'ı $l kullanmak ister misiniz?';
String _bodyEn(String l) =>
    'Your device language is $l. Would you like to use FamilyHub in $l?';
String _bodyFr(String l) =>
    'La langue de votre appareil est $l. Souhaitez-vous utiliser FamilyHub en $l ?';
String _bodyNl(String l) =>
    'De taal van je apparaat is $l. Wil je FamilyHub in $l gebruiken?';
String _useTr(String l) => '$l kullan';
String _useEn(String l) => 'Use $l';
String _useFr(String l) => 'Utiliser $l';
String _useNl(String l) => '$l gebruiken';
