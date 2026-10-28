bool hasActivePremium({
  required bool isPremium,
  String? subscriptionTier,
  DateTime? expiresAt,
  DateTime? now,
}) {
  final hasPaidTier = subscriptionTier == 'premium' || subscriptionTier == 'family';
  if (!isPremium && !hasPaidTier) return false;

  final reference = now ?? DateTime.now();
  return expiresAt == null || expiresAt.isAfter(reference);
}
