import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/context_memory/application/health_memory_adapter.dart';
import 'package:familyhub/features/context_memory/domain/memory_enums.dart';

/// Sağlık/çocuk adapter'ı — prompt §21 güvenlik kuralları.
void main() {
  group('KRİTİK: sağlık verisi otomatik aile paylaşımına AÇILMAZ', () {
    test('yetişkin sağlık kaydı userPrivate kalır', () {
      expect(healthScopeFor(), MemoryScope.userPrivate);
    });

    test('hiçbir durumda familyShared döndürmez', () {
      expect(healthScopeFor(), isNot(MemoryScope.familyShared));
      expect(healthScopeFor(childId: 'c1'), isNot(MemoryScope.familyShared));
    });

    test('çocuk sağlık kaydı childPrivate', () {
      expect(healthScopeFor(childId: 'c1'), MemoryScope.childPrivate);
    });
  });

  group('hassasiyet sınıflandırma', () {
    test('yetişkin sağlık verisi health', () {
      expect(healthSensitivityFor(kind: HealthDataKind.condition),
          MemorySensitivity.health);
    });

    test('KRİTİK: çocuk verisi HER ZAMAN minorData', () {
      for (final k in HealthDataKind.values) {
        expect(healthSensitivityFor(kind: k, childId: 'c1'),
            MemorySensitivity.minorData,
            reason: k.name);
      }
    });

    test('KRİTİK: kadın sağlığı confidential', () {
      expect(healthSensitivityFor(kind: HealthDataKind.womensHealth),
          MemorySensitivity.confidential);
    });

    test('hassas sınıflar açık izin gerektirir', () {
      expect(
          healthSensitivityFor(kind: HealthDataKind.allergy)
              .requiresExplicitConsent,
          isTrue);
      expect(
          healthSensitivityFor(kind: HealthDataKind.womensHealth)
              .requiresExplicitConsent,
          isTrue);
    });
  });

  group('kritik kısıtlar', () {
    test('alerji kritik kısıt', () {
      expect(isCriticalHealthRestriction(HealthDataKind.allergy), isTrue);
    });

    test('ilaç kritik kısıt', () {
      expect(isCriticalHealthRestriction(HealthDataKind.medication), isTrue);
    });

    test('randevu/ölçüm kritik kısıt değil', () {
      expect(isCriticalHealthRestriction(HealthDataKind.appointment), isFalse);
      expect(isCriticalHealthRestriction(HealthDataKind.measurement), isFalse);
    });
  });

  group('aday üretimi', () {
    test('alerji restriction + yüksek önem', () {
      final c = healthCandidates(
        kind: HealthDataKind.allergy,
        subject: 'Yer Fıstığı',
        content: 'Yer fıstığı alerjisi var',
      );
      expect(c.single.kind, MemoryKind.restriction);
      expect(c.single.importance, greaterThan(0.9));
      expect(c.single.key, 'health.allergy.yer_fistigi');
    });

    test('ilaç medication modülüne yazılır', () {
      final c = healthCandidates(
        kind: HealthDataKind.medication,
        subject: 'Ventolin',
        content: 'Günde 2 doz',
      );
      expect(c.single.module, 'medication');
    });

    test('çocuk alerjisi childPrivate + minorData', () {
      final c = healthCandidates(
        kind: HealthDataKind.allergy,
        subject: 'Fıstık',
        content: 'Alerji',
        childId: 'c1',
      );
      expect(c.single.scope, MemoryScope.childPrivate);
      expect(c.single.sensitivity, MemorySensitivity.minorData);
    });

    test('kaynak moduleRecord — kullanıcı beyanı otoritesinde değil', () {
      final c = healthCandidates(
        kind: HealthDataKind.condition,
        subject: 'Astım',
        content: 'Kayıt',
      );
      expect(c.single.sourceType, MemorySourceType.moduleRecord);
      expect(
        MemorySourceType.moduleRecord.authority,
        lessThan(MemorySourceType.userCorrection.authority),
      );
    });

    test('TUTUCU: boş konu/içerik aday üretmez', () {
      expect(
          healthCandidates(
              kind: HealthDataKind.allergy, subject: '  ', content: 'x'),
          isEmpty);
      expect(
          healthCandidates(
              kind: HealthDataKind.allergy, subject: 'x', content: '  '),
          isEmpty);
    });
  });

  group('olay üretimi', () {
    test('ilaç olayı medication modülünde', () {
      final e = healthMemoryEvent(
        eventId: 'e1',
        sourceId: 's1',
        kind: HealthDataKind.medication,
        userId: 'u1',
      );
      expect(e.module, 'medication');
    });

    test('çocuk kimliği taşınır', () {
      final e = healthMemoryEvent(
        eventId: 'e1',
        sourceId: 's1',
        kind: HealthDataKind.allergy,
        childId: 'c1',
      );
      expect(e.childId, 'c1');
    });
  });
}
