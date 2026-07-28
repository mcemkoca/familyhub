import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/widgets/settings/screen_header.dart';
import '../data/vaccination_repository.dart';

/// Bağımsız Aşı Takvimi ekranı — çocuğa özel DEĞİL. Kategori seçiciyle
/// çocuk / yetişkin / hamilelik / seyahat aşı takvimini gösterir (spec §15).
/// Resmî kaynak bağlantısı + disclaimer; "yapıldı" durumu kişi-izole tutulur.
class VaccinationScreen extends ConsumerStatefulWidget {
  const VaccinationScreen({super.key});

  @override
  ConsumerState<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends ConsumerState<VaccinationScreen> {
  final _repo = VaccinationRepository.instance;
  List<VaccineCategory> _cats = const [];
  String? _selected;
  bool _loading = true;
  int _tick = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final country = ref.read(countryProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final cats = await _repo.forCountry(country, lang);
    if (!mounted) return;
    setState(() {
      _cats = cats;
      _selected ??= cats.isNotEmpty ? cats.first.key : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cat = _cats.where((c) => c.key == _selected).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: ScreenHeader(
        title: t.vaccTitle,
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cats.isEmpty
              ? Center(
                  child: Text(t.vaccEmpty,
                      style: const TextStyle(color: Color(0xFF9CA3AF))))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(t.vaccSubtitle,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13)),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final c in _cats) ...[
                            _chip(c.label, c.key == _selected,
                                () => setState(() => _selected = c.key)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: cat == null
                          ? const SizedBox.shrink()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              children: [
                                if (cat.desc.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(cat.desc,
                                        style: const TextStyle(
                                            color: Color(0xFFD1D5DB),
                                            fontSize: 13,
                                            height: 1.4)),
                                  ),
                                for (final v in cat.vaccines)
                                  _vaccineTile(t, cat.key, v),
                                const SizedBox(height: 8),
                                if (cat.sources.isNotEmpty)
                                  _sources(t, cat),
                                const SizedBox(height: 12),
                                _disclaimer(t),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF14B8A6) : const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel ? const Color(0xFF14B8A6) : const Color(0x22FFFFFF)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : const Color(0xFF9CA3AF))),
        ),
      );

  Widget _vaccineTile(AppLocalizations t, String catKey, VaccineItem v) {
    final key = _repo.markKey(_selected ?? '', catKey, v.id);
    final done = _repo.isDone(key);
    // _tick değişimi rebuild tetikler.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: done ? const Color(0x3314B8A6) : const Color(0x14FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: TextStyle(
                        color: done ? const Color(0xFF6EE7D6) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration:
                            done ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.schedule,
                      size: 13, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(v.timing,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                ]),
                if (v.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(v.note,
                      style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11.5,
                          height: 1.35)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: done ? t.vaccMarkUndone : t.vaccMarkDone,
            child: IconButton(
              onPressed: () async {
                await _repo.toggleDone(key);
                setState(() => _tick++);
              },
              icon: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: done
                      ? const Color(0xFF14B8A6)
                      : const Color(0xFF6B7280),
                  size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sources(AppLocalizations t, VaccineCategory cat) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A19),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x2214B8A6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_outlined,
                  size: 17, color: Color(0xFF14B8A6)),
              const SizedBox(width: 8),
              Text(t.vaccSources,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            for (final s in cat.sources)
              InkWell(
                onTap: () => _open(s.url),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.open_in_new,
                        size: 15, color: Color(0xFF14B8A6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.authority,
                          style: const TextStyle(
                              color: Color(0xFFE5E7EB), fontSize: 12.5)),
                    ),
                  ]),
                ),
              ),
          ],
        ),
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
            child: Text(t.vaccDisclaimer,
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
