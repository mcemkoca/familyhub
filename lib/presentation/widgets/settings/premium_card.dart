import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  final String tier;
  final String? expiry;
  final List<String> features;
  final VoidCallback onManage;

  const PremiumCard({
    super.key,
    required this.tier,
    this.expiry,
    required this.features,
    required this.onManage,
  });

  bool get _isPremium => expiry != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPremium
              ? const [Color(0xFF6366F1), Color(0xFF4F46E5)]
              : const [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPremium
              ? const Color(0xFF6366F1).withAlpha(80)
              : const Color(0x1EFFFFFF),
          width: 0.5,
        ),
        boxShadow: _isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(_isPremium ? 25 : 15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isPremium) ...[
                      const Icon(Icons.star, color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (expiry != null)
                Text(
                  expiry!,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                )
              else
                TextButton(
                  onPressed: onManage,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Premium\'a Geç →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: _isPremium ? Colors.white : const Color(0xFF6B7280),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    f,
                    style: TextStyle(
                      color: _isPremium ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onManage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aboneliği Yönet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
