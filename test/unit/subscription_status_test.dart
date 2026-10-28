import 'package:familyhub/core/utils/subscription_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 28, 12);

  group('hasActivePremium', () {
    test('rejects free users', () {
      expect(
        hasActivePremium(isPremium: false, subscriptionTier: 'free', now: now),
        isFalse,
      );
    });

    test('accepts an active paid tier', () {
      expect(
        hasActivePremium(
          isPremium: false,
          subscriptionTier: 'premium',
          expiresAt: now.add(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('accepts a family tier without an expiry date', () {
      expect(
        hasActivePremium(
          isPremium: false,
          subscriptionTier: 'family',
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects an expired subscription even with a legacy flag', () {
      expect(
        hasActivePremium(
          isPremium: true,
          subscriptionTier: 'premium',
          expiresAt: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('rejects a subscription expiring exactly now', () {
      expect(
        hasActivePremium(
          isPremium: true,
          subscriptionTier: 'premium',
          expiresAt: now,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
