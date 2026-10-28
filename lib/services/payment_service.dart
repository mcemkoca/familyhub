import '../core/errors.dart';

/// Legacy Stripe entry point.
///
/// Mobile subscriptions use RevenueCat. Keeping this fail-closed prevents an
/// unverified client callback from granting premium access.
class PaymentService {
  static Future<bool> presentPaymentSheet(String priceId) async {
    throw AppAuthException(
      'Bu ödeme yöntemi devre dışı. Lütfen mağaza aboneliğini kullanın.',
    );
  }
}
