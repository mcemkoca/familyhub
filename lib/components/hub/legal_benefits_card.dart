import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../config/routes.dart';
import '../../presentation/providers/app_providers.dart';

/// Hub'daki Yasal Haklar girişi — yalnızca NAVIGATION entry.
/// Feature logic ve içerik bağımsız modüle taşındı
/// (lib/features/legal_benefits). Karta dokununca /legal-benefits açılır.
class LegalBenefitsCard extends ConsumerWidget {
  const LegalBenefitsCard({super.key});

  static String _countryLabel(String code) => switch (code) {
        'NL' => 'Nederland',
        'TR' => 'Türkiye',
        'DE' => 'Deutschland',
        'FR' => 'France',
        _ => 'België',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final country = ref.watch(countryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: InkWell(
        onTap: () => context.push(AppRoutes.legalBenefits),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102A1E), Color(0xFF0E2233)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x2A10B981)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.legalBenefitsTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    Text(t.legalBenefitsSubtitle(_countryLabel(country)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
