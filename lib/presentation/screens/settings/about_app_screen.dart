import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../widgets/settings/screen_header.dart';
import 'package:go_router/go_router.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.cloudWhite;

    return Scaffold(
      backgroundColor: bg,
      appBar: ScreenHeader(
        title: 'Hakkında',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cobalt,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  'FH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'FamilyHub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v2.1.0 (Build 2100)',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightGray,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Güncel',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoTile(
            context,
            label: 'Geliştirici',
            value: 'FamilyHub Inc.',
          ),
          _buildInfoTile(
            context,
            label: 'Lisans',
            value: 'MIT License',
          ),
          _buildInfoTile(
            context,
            label: 'Flutter',
            value: '3.27.0',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 FamilyHub Inc.\nTüm hakları saklıdır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
