import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../application/legal_benefits_providers.dart';
import '../data/legal_benefits_repository.dart';
import '../data/legal_reminder_service.dart';
import '../domain/legal_benefit.dart';

/// Yasal Haklar ve Avantajlar — bağımsız bölüm ekranı.
/// Resmî kaynak bağlantısı, doğrulama tarihi, süre işareti ve hukuki disclaimer
/// içerir. Kesin hak garantisi vermez ("uygun olabilirsiniz" dili).
class LegalBenefitsScreen extends ConsumerWidget {
  const LegalBenefitsScreen({super.key});

  static String _countryLabel(String code) => switch (code) {
        'NL' => 'Nederland',
        'TR' => 'Türkiye',
        'DE' => 'Deutschland',
        'FR' => 'France',
        _ => 'België',
      };

  String _categoryLabel(AppLocalizations t, LegalCategory c) => switch (c) {
        LegalCategory.familySupport => t.legalCatFamilySupport,
        LegalCategory.childBenefits => t.legalCatChildBenefits,
        LegalCategory.healthRights => t.legalCatHealthRights,
        LegalCategory.educationSupport => t.legalCatEducationSupport,
        LegalCategory.taxBenefits => t.legalCatTaxBenefits,
        LegalCategory.housingSupport => t.legalCatHousingSupport,
        LegalCategory.employeeRights => t.legalCatEmployeeRights,
        LegalCategory.parentalLeave => t.legalCatParentalLeave,
        LegalCategory.residencyRights => t.legalCatResidencyRights,
        LegalCategory.disabilitySupport => t.legalCatDisabilitySupport,
        LegalCategory.socialAid => t.legalCatSocialAid,
        LegalCategory.other => t.legalCatOther,
      };

  String _regionLabel(AppLocalizations t, LegalRegion r) => switch (r) {
        LegalRegion.federal => t.legalRegionFederal,
        LegalRegion.flanders => t.legalRegionFlanders,
        LegalRegion.wallonia => t.legalRegionWallonia,
        LegalRegion.brussels => t.legalRegionBrussels,
        LegalRegion.municipality => t.legalRegionMunicipality,
        LegalRegion.other => t.legalRegionOther,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final country = ref.watch(countryProvider);
    final items = ref.watch(legalBenefitsListProvider);
    final cat = ref.watch(legalCategoryFilterProvider);
    final savedOnly = ref.watch(legalSavedOnlyProvider);
    final repo = LegalBenefitsRepository.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.legalBenefitsTitle,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              t.legalBenefitsSubtitle(_countryLabel(country)),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ),
          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  ref.read(legalSearchProvider.notifier).state = v,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: t.legalSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFF13131A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          // Kategori + kaydedilenler filtreleri
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip(t.legalSavedOnly, savedOnly, () {
                  ref.read(legalSavedOnlyProvider.notifier).state = !savedOnly;
                }, icon: Icons.bookmark_border),
                const SizedBox(width: 8),
                _filterChip(t.legalAll, cat == null, () {
                  ref.read(legalCategoryFilterProvider.notifier).state = null;
                }),
                for (final c in LegalCategory.values) ...[
                  const SizedBox(width: 8),
                  _filterChip(_categoryLabel(t, c), cat == c, () {
                    ref.read(legalCategoryFilterProvider.notifier).state =
                        cat == c ? null : c;
                  }),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _empty(t)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      for (final b in items)
                        _benefitCard(context, ref, t, b, repo),
                      const SizedBox(height: 8),
                      _disclaimer(t),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap,
      {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF10B981) : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? const Color(0xFF10B981) : const Color(0x22FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: sel ? Colors.white : const Color(0xFF9CA3AF)),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _benefitCard(BuildContext context, WidgetRef ref, AppLocalizations t,
      LegalBenefit b, LegalBenefitsRepository repo) {
    final saved = repo.isSaved(b.id);
    final dateStr = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(b.lastVerifiedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: b.isExpired
                ? const Color(0x33EF4444)
                : const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(b.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              Semantics(
                button: true,
                label: t.legalRemind,
                child: IconButton(
                  onPressed: () => _reminderSheet(context, ref, t, b),
                  icon: Icon(
                      LegalReminderService.instance.hasReminder(b.id)
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: LegalReminderService.instance.hasReminder(b.id)
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF9CA3AF),
                      size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
              Semantics(
                button: true,
                label: saved ? t.legalSaved : t.legalSave,
                child: IconButton(
                  onPressed: () async {
                    await repo.toggleSaved(b.id);
                    ref.read(legalSavedTickProvider.notifier).state++;
                  },
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                      size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
            ],
          ),
          // Rozetler: bölge + durum
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _badge(_regionLabel(t, b.region), const Color(0xFF6366F1)),
              if (b.isExpired)
                _badge(t.legalExpired, const Color(0xFFEF4444))
              else if (b.isStale)
                _badge(t.legalStale, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Text(b.description,
              style: const TextStyle(
                  color: Color(0xFFD1D5DB), fontSize: 13, height: 1.4)),
          const SizedBox(height: 6),
          Text(t.legalPossibleEligibility,
              style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(t.legalLastVerified(dateStr),
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () => _openSource(context, b.sourceUrl),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: Text(t.legalOpenSource,
                    style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );

  Widget _disclaimer(AppLocalizations t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x14F59E0B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33F59E0B)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.legalDisclaimer,
                  style: const TextStyle(
                      color: Color(0xFFD1D5DB), fontSize: 11.5, height: 1.4)),
            ),
          ],
        ),
      );

  Widget _empty(AppLocalizations t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: Color(0xFF6B7280)),
              const SizedBox(height: 12),
              Text(t.legalEmptyTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(t.legalEmptyDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
      );

  /// Hatırlatma bottom-sheet'i: hatırlatma varsa kaldır, yoksa süre seç.
  Future<void> _reminderSheet(BuildContext context, WidgetRef ref,
      AppLocalizations t, LegalBenefit b) async {
    final svc = LegalReminderService.instance;
    final messenger = ScaffoldMessenger.of(context);

    if (svc.hasReminder(b.id)) {
      await svc.cancel(b.id);
      ref.read(legalSavedTickProvider.notifier).state++;
      messenger.showSnackBar(SnackBar(
          content: Text(t.legalReminderRemoved),
          behavior: SnackBarBehavior.floating));
      return;
    }

    final notifTitle = t.legalReminderNotifTitle;
    final notifBody = t.legalReminderNotifBody(b.title);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                const Icon(Icons.notifications_active,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 10),
                Text(t.legalReminderTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            for (final opt in [
              (1, t.legalRemindIn1Day),
              (7, t.legalRemindIn7Days),
              (30, t.legalRemindIn30Days),
            ])
              ListTile(
                leading: const Icon(Icons.schedule, color: Color(0xFF9CA3AF)),
                title: Text(opt.$2,
                    style: const TextStyle(color: Color(0xFFE5E7EB))),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await svc.schedule(
                    benefitId: b.id,
                    days: opt.$1,
                    title: notifTitle,
                    body: notifBody,
                  );
                  if (!ok) return;
                  ref.read(legalSavedTickProvider.notifier).state++;
                  messenger.showSnackBar(SnackBar(
                      content: Text(t.legalReminderSet),
                      behavior: SnackBarBehavior.floating));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
