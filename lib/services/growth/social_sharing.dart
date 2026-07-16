import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics_service.dart';
import '../localization/locale_service.dart';

class SocialSharing {
  static String _text(Map<String, String> values) { final lang = LocaleService.resolveInitialLocale().languageCode; return values[lang] ?? values['tr']!; }
  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
  }

  static Future<void> shareAchievement(String achievement, String userName) async {
    final text = _text({
      'tr': '🏆 $userName, FamilyHub’da “$achievement” başarımını kazandı!\n\nAilenizi organize etmek için siz de katılın:\nhttps://familyhub.app/join',
      'en': '🏆 $userName earned the “$achievement” achievement on FamilyHub!\n\nJoin to organize your family:\nhttps://familyhub.app/join',
      'nl': '🏆 $userName heeft de prestatie ‘$achievement’ behaald op FamilyHub!\n\nDoe mee om je gezin te organiseren:\nhttps://familyhub.app/join',
      'fr': '🏆 $userName a obtenu le succès « $achievement » sur FamilyHub !\n\nRejoignez-nous pour organiser votre famille :\nhttps://familyhub.app/join',
    });
    await SharePlus.instance.share(ShareParams(text: text));

    AnalyticsService.track('share_achievement', properties: {
      'achievement': achievement,
    });
  }

  static Future<void> shareEventCard({
    required String title,
    required String date,
    required Color backgroundColor,
    required Color textColor,
  }) async {
    final bytes = await _generateCardImage(
      title: title,
      date: date,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'event_card.png')],
        text: '$title - $date #FamilyHub',
        subject: _text(const {'tr': 'Aile etkinliği', 'en': 'Family event', 'nl': 'Gezinsactiviteit', 'fr': 'Événement familial'}),
      ),
    );

    AnalyticsService.track('share_event', properties: {
      'event_title': title,
      'platform': 'native',
    });
  }

  static Future<Uint8List> _generateCardImage({
    required String title,
    required String date,
    required Color backgroundColor,
    required Color textColor,
  }) async {
    const width = 1080;
    const height = 1920;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        const Radius.circular(40),
      ),
      Paint()..color = backgroundColor,
    );

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(color: textColor, fontSize: 72, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      textAlign: TextAlign.center,
    );
    titlePainter.layout(maxWidth: width - 160);
    titlePainter.paint(canvas, const Offset(80, height * 0.35));

    // Date
    final datePainter = TextPainter(
      text: TextSpan(
        text: date,
        style: TextStyle(color: textColor.withAlpha(204), fontSize: 48),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    datePainter.layout(maxWidth: width - 160);
    datePainter.paint(canvas, Offset(80, height * 0.35 + titlePainter.height + 40));

    // Branding
    final brandPainter = TextPainter(
      text: TextSpan(
        text: 'FamilyHub',
        style: TextStyle(color: textColor.withAlpha(128), fontSize: 36),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    brandPainter.layout(maxWidth: width - 160);
    brandPainter.paint(canvas, const Offset(80, height - 160));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
