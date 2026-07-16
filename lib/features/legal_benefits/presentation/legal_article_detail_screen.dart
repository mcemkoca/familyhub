import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../domain/legal_article.dart';

/// Zengin yasal makale detayı — sade açıklama, kimler başvurabilir, koşullar,
/// avantajlar, başvuru adımları, gerekli belgeler, uyarılar ve resmî kaynaklar.
/// Kesin hak garantisi vermez; disclaimer + kaynak zorunludur.
class LegalArticleDetailScreen extends StatelessWidget {
  final LegalArticle article;
  const LegalArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final a = article;
    final verified = a.lastVerifiedAt != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(a.lastVerifiedAt!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: a.title,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (a.summary.isNotEmpty)
            Text(a.summary,
                style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final r in a.regionCodes) _badge(r, const Color(0xFF6366F1)),
            if (a.isStale) _badge(t.legalStale, const Color(0xFFF59E0B)),
          ]),
          const SizedBox(height: 16),
          if (a.plainExplanation.isNotEmpty)
            _section(t.legalArtOverview, Icons.article_outlined,
                body: a.plainExplanation),
          if (a.whoCanApply.isNotEmpty)
            _section(t.legalArtWhoCanApply, Icons.people_outline,
                body: a.whoCanApply),
          if (a.conditions.isNotEmpty)
            _section(t.legalArtConditions, Icons.rule, items: a.conditions),
          if (a.benefits.isNotEmpty)
            _section(t.legalArtBenefits, Icons.card_giftcard_outlined,
                items: a.benefits, accent: const Color(0xFF10B981)),
          if (a.applicationSteps.isNotEmpty)
            _section(t.legalArtSteps, Icons.format_list_numbered,
                numbered: a.applicationSteps),
          if (a.requiredDocuments.isNotEmpty)
            _section(t.legalArtDocuments, Icons.folder_open_outlined,
                items: a.requiredDocuments),
          if (a.importantWarnings.isNotEmpty)
            _section(t.legalArtWarnings, Icons.warning_amber_rounded,
                items: a.importantWarnings, accent: const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          // Eligibility dili — kesin garanti değil.
          Text(t.legalPossibleEligibility,
              style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          _sourcesBlock(context, t, a, verified),
          const SizedBox(height: 12),
          _disclaimer(t),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon,
      {String? body,
      List<String>? items,
      List<String>? numbered,
      Color accent = const Color(0xFF9CA3AF)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          if (body != null)
            Text(body,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB), fontSize: 13, height: 1.45)),
          if (items != null)
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                        width: 5,
                        height: 5,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle)),
                  ),
                  Expanded(
                    child: Text(it,
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ]),
              ),
          if (numbered != null)
            for (var i = 0; i < numbered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(40),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                  Expanded(
                    child: Text(numbered[i],
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ]),
              ),
        ],
      ),
    );
  }

  Widget _sourcesBlock(BuildContext context, AppLocalizations t,
      LegalArticle a, String? verified) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2210B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.verified_outlined,
                size: 17, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(t.legalArtSources,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          for (final s in a.sources)
            InkWell(
              onTap: () => _open(s.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  const Icon(Icons.open_in_new,
                      size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.authority,
                            style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        if (s.title.isNotEmpty)
                          Text(s.title,
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 11.5)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          if (verified != null) ...[
            const SizedBox(height: 6),
            Text(t.legalLastVerified(verified),
                style:
                    const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
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
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.legalDisclaimer,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB), fontSize: 11.5, height: 1.4)),
          ),
        ]),
      );

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
