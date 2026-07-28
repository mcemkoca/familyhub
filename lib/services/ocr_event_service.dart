import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/entities.dart';

/// OCR + heuristic parser to create CalendarEvent from a photo.
class OcrEventService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  static Future<CalendarEvent?> pickAndParse() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final input = InputImage.fromFilePath(picked.path);
    final result = await _textRecognizer.processImage(input);
    final text = result.text;
    await _textRecognizer.close();

    return _parseEvent(text);
  }

  static CalendarEvent? _parseEvent(String text) {
    if (text.trim().isEmpty) return null;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // Heuristic: first non-empty line is title
    String title = lines.first;
    String? location;
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(hours: 1));

    // Try to find date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2})[/.](\d{1,2})[/.](\d{2,4})'),           // 15/05/2026
      RegExp(r'(\d{1,2})\s+([A-Za-zÀ-ÿİıŞşĞğÜüÖöÇç]+)\s+(\d{4})', caseSensitive: false),
    ];

    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (match.groupCount >= 3) {
              final day = int.parse(match.group(1)!);
              final monthStr = match.group(2)!;
              final year = int.parse(match.group(3)!);
              int month;
              if (RegExp(r'^\d+$').hasMatch(monthStr)) {
                month = int.parse(monthStr);
              } else {
                month = _parseMonth(monthStr);
              }
              start = DateTime(year < 100 ? 2000 + year : year, month, day);
              end = start.add(const Duration(hours: 1));
            }
          } catch (e) { debugPrint('OCR error: $e'); }
        }
      }

      final timeMatch = timePattern.firstMatch(line);
      if (timeMatch != null) {
        try {
          final hour = int.parse(timeMatch.group(1)!);
          final minute = int.parse(timeMatch.group(2)!);
          start = DateTime(start.year, start.month, start.day, hour, minute);
          end = start.add(const Duration(hours: 1));
        } catch (e) { debugPrint('OCR error: $e'); }
      }

      // Location heuristic: lines containing common location keywords
      final locationKeywords = ['kafe', 'restoran', 'otel', 'hastane', 'okul', 'salon', 'sokak', 'cadde', 'mahallesi', 'caddesi', 'no:', 'kat:', 'daire', 'ofis', 'merkez', 'cafe', 'restaurant', 'hotel', 'hospital', 'school', 'street', 'avenue', 'office', 'center', 'centrum', 'ziekenhuis', 'school', 'straat', 'laan', 'bureau', 'centre', 'hôpital', 'école', 'rue'];
      final lower = line.toLowerCase();
      if (locationKeywords.any((k) => lower.contains(k))) {
        location = line;
      }
    }

    return CalendarEvent(
      id: '',
      title: title,
      start: start,
      end: end,
      location: location,
      description: text.length > 200 ? '${text.substring(0, 200)}...' : text,
    );
  }

  static int _parseMonth(String month) {
    final map = {
      'ocak': 1, 'şubat': 2, 'mart': 3, 'nisan': 4, 'mayıs': 5, 'haziran': 6,
      'temmuz': 7, 'ağustos': 8, 'eylül': 9, 'ekim': 10, 'kasım': 11, 'aralık': 12,
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'januari': 1, 'februari': 2, 'maart': 3, 'mei': 5, 'juni': 6,
      'juli': 7, 'augustus': 8, 'oktober': 10,
      'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
      'juillet': 7, 'août': 8, 'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12,
    };
    return map[month.toLowerCase()] ?? 1;
  }
}
