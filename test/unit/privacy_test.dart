import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/features/privacy/domain/privacy_preferences.dart';
import 'package:familyhub/features/familyhub_ai/application/ai_guardrails.dart';

void main() {
  group('PrivacyPreferences varsayılanlar', () {
    const p = PrivacyPreferences();
    test('hassas modüller VARSAYILAN KAPALI (minimum erişim)', () {
      expect(p.aiAllows(PrivacyModule.health), false);
      expect(p.aiAllows(PrivacyModule.finance), false);
      expect(p.aiAllows(PrivacyModule.child), false);
      expect(p.aiAllows(PrivacyModule.location), false);
    });
    test('hassas olmayan modüller varsayılan açık', () {
      expect(p.aiAllows(PrivacyModule.tasks), true);
      expect(p.aiAllows(PrivacyModule.calendar), true);
      expect(p.aiAllows(PrivacyModule.shopping), true);
    });
    test('isSensitive doğru', () {
      expect(PrivacyPreferences.isSensitive(PrivacyModule.health), true);
      expect(PrivacyPreferences.isSensitive(PrivacyModule.tasks), false);
    });
  });

  group('toggle + consent', () {
    test('modül açma/kapama + consent timestamp', () {
      const p = PrivacyPreferences();
      final on = p.toggleModule(PrivacyModule.health, true);
      expect(on.aiAllows(PrivacyModule.health), true);
      expect(on.consentedAt, isNotNull);
      final off = on.toggleModule(PrivacyModule.tasks, false);
      expect(off.aiAllows(PrivacyModule.tasks), false);
    });
    test('serialization round-trip', () {
      final p = const PrivacyPreferences()
          .toggleModule(PrivacyModule.finance, true);
      final back = PrivacyPreferences.fromJson(p.toJson());
      expect(back.aiAllows(PrivacyModule.finance), true);
      expect(back.aiAllows(PrivacyModule.health), false);
    });
  });

  group('AIGuardrails privacy-aware context', () {
    test('izin kapalıysa ilgili alan context\'e girmez', () {
      final ctx = AIGuardrails.minimizedContext(
        pendingTasks: 3,
        todayEvents: 1,
        pendingShopping: 5,
        memberCount: 4,
        allowTasks: false, // görev izni kapalı
      );
      expect(ctx.containsKey('pendingTasks'), false); // sızmadı
      expect(ctx.containsKey('todayEvents'), true);
      expect(ctx.containsKey('memberCount'), true); // aile geneli hep var
    });
    test('varsayılan hepsi açık', () {
      final ctx = AIGuardrails.minimizedContext(
          pendingTasks: 1, todayEvents: 1, pendingShopping: 1, memberCount: 2);
      expect(ctx.containsKey('pendingTasks'), true);
      // Hassas ham veri hiçbir zaman yok
      expect(ctx.containsKey('health'), false);
      expect(ctx.containsKey('name'), false);
    });
  });
}
