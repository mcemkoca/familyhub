import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:familyhub/services/notification_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Brussels'));
  });

  group('NotificationService.nextInstanceOfTime', () {
    test('her zaman gelecekte bir zaman döner', () {
      final now = tz.TZDateTime.now(tz.local);
      for (var h = 0; h < 24; h++) {
        final next = NotificationService.nextInstanceOfTime(h, 0);
        expect(next.isAfter(now), true);
        expect(next.hour, h);
      }
    });

    test('saat geçmişse yarına kayar (24 saat içinde)', () {
      final now = tz.TZDateTime.now(tz.local);
      final pastHour = (now.hour - 1 + 24) % 24;
      final next = NotificationService.nextInstanceOfTime(pastHour, 0);
      expect(next.isAfter(now), true);
      expect(next.difference(now).inHours < 24, true);
    });
  });
}
