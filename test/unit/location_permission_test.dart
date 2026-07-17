import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:familyhub/services/location_service.dart';

/// FH-07 / spec §11 — granüler konum izin durumları.
void main() {
  group('mapGeolocatorPermission', () {
    test('servis kapalıysa izin ne olursa olsun serviceDisabled', () {
      for (final p in LocationPermission.values) {
        expect(mapGeolocatorPermission(p, serviceEnabled: false),
            LocationPermissionStatus.serviceDisabled,
            reason: '$p');
      }
    });

    test('always → always (arka plan izinli)', () {
      final s = mapGeolocatorPermission(LocationPermission.always,
          serviceEnabled: true);
      expect(s, LocationPermissionStatus.always);
      expect(s.canTrackInBackground, isTrue);
      expect(s.isGranted, isTrue);
    });

    test('whileInUse → whileInUse (arka plan İZİNSİZ)', () {
      final s = mapGeolocatorPermission(LocationPermission.whileInUse,
          serviceEnabled: true);
      expect(s, LocationPermissionStatus.whileInUse);
      expect(s.isGranted, isTrue);
      // Kritik ayrım: ön plan izni arka plan takibi anlamına GELMEZ.
      expect(s.canTrackInBackground, isFalse);
    });

    test('denied → tekrar sorulabilir, ayarlar gerekmez', () {
      final s = mapGeolocatorPermission(LocationPermission.denied,
          serviceEnabled: true);
      expect(s, LocationPermissionStatus.denied);
      expect(s.isAskable, isTrue);
      expect(s.needsSettings, isFalse);
      expect(s.isGranted, isFalse);
    });

    test('deniedForever → ayarlar gerekir, tekrar sorulamaz', () {
      final s = mapGeolocatorPermission(LocationPermission.deniedForever,
          serviceEnabled: true);
      expect(s, LocationPermissionStatus.deniedForever);
      expect(s.isAskable, isFalse);
      expect(s.needsSettings, isTrue);
      expect(s.isGranted, isFalse);
    });

    test('unableToDetermine → unknown (granted sayılmaz)', () {
      final s = mapGeolocatorPermission(LocationPermission.unableToDetermine,
          serviceEnabled: true);
      expect(s, LocationPermissionStatus.unknown);
      expect(s.isGranted, isFalse);
    });
  });

  group('serviceDisabled davranışı', () {
    test('ayarlar gerekir ve granted değil', () {
      const s = LocationPermissionStatus.serviceDisabled;
      expect(s.needsSettings, isTrue);
      expect(s.isGranted, isFalse);
      expect(s.canTrackInBackground, isFalse);
    });
  });

  group('legacy granted geriye-uyum', () {
    test('granted isGranted sayılır', () {
      expect(LocationPermissionStatus.granted.isGranted, isTrue);
    });
  });
}
