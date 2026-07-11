import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'child_development_screen.dart' show ChildProfile;
import 'child_dev_content.dart';
import 'child_dev_store.dart';

/// Ekran 2 — Gelişim Gözlemi Ekle.
class ObservationInputScreen extends StatefulWidget {
  final ChildProfile child;
  const ObservationInputScreen({super.key, required this.child});

  @override
  State<ObservationInputScreen> createState() => _ObservationInputScreenState();
}

class _ObservationInputScreenState extends State<ObservationInputScreen> {
  String _area = 'dil';
  final _note = TextEditingController();
  String _mood = 'cok_iyi';
  String _skill = 'kolay';
  final List<String> _media = [];

  static const _moods = [
    ('cok_iyi', 'Çok İyi', '😄', Color(0xFF22C55E)),
    ('iyi', 'İyi', '🙂', Color(0xFF84CC16)),
    ('orta', 'Orta', '😐', Color(0xFFF59E0B)),
    ('zor', 'Zor', '🙁', Color(0xFFF97316)),
    ('cok_zor', 'Çok Zor', '😣', Color(0xFFEF4444)),
  ];

  static const _skills = [
    ('kolay', 'Kolay yaptı', Icons.check_circle, Color(0xFF22C55E)),
    ('zorlandi', 'Zorlandı', Icons.trending_up, Color(0xFFF59E0B)),
    ('yardimla', 'Yardımla yaptı', Icons.groups, Color(0xFF3B82F6)),
    ('yapmadi', 'Yapmadı', Icons.cancel, Color(0xFFEF4444)),
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final files = await ImagePicker().pickMultipleMedia(imageQuality: 80);
      if (files.isEmpty) return;
      setState(() {
        for (final f in files.take(5 - _media.length)) {
          _media.add(f.path);
        }
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    await DevStore.addObservation(
      widget.child.id,
      Observation(
        area: _area,
        note: _note.text.trim(),
        mood: _mood,
        skill: _skill,
        dateIso: DateTime.now().toIso8601String(),
        media: List.of(_media),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).obsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: AppLocalizations.of(context).obsAdd,
              subtitle: '${widget.child.name} için gelişim kaydı',
              trailing: const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _label(AppLocalizations.of(context).obsDevArea),
                  const SizedBox(height: 10),
                  _areaGrid(),
                  const SizedBox(height: 20),
                  _label(AppLocalizations.of(context).obsYourObs),
                  const SizedBox(height: 10),
                  _noteField(),
                  const SizedBox(height: 20),
                  _label(AppLocalizations.of(context).obsMood),
                  const SizedBox(height: 10),
                  _moodRow(),
                  const SizedBox(height: 20),
                  _label(AppLocalizations.of(context).obsSkillStatus),
                  const SizedBox(height: 10),
                  _skillRow(),
                  const SizedBox(height: 16),
                  _mediaCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLocalizations.of(context).save,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800));

  Widget _areaGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: devAreas.map((a) {
        final sel = _area == a.key;
        return GestureDetector(
          onTap: () => setState(() => _area = a.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? a.gradient.first : const Color(0x14FFFFFF),
                width: sel ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: a.gradient),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(a.icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(a.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
                if (sel)
                  Icon(Icons.check_circle, size: 15, color: a.gradient.first),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _note,
      maxLines: 4,
      maxLength: 500,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).obsHint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFF13131A),
        counterStyle: const TextStyle(color: Color(0xFF6B7280)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _moodRow() {
    return Row(
      children: _moods.map((m) {
        final sel = _mood == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _mood = m.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? m.$4 : const Color(0x14FFFFFF),
                  width: sel ? 1.6 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(m.$3, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(m.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _skillRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skills.map((s) {
        final sel = _skill == s.$1;
        return GestureDetector(
          onTap: () => setState(() => _skill = s.$1),
          child: Container(
            width: (MediaQuery.of(context).size.width - 40 - 8) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? s.$4 : const Color(0x14FFFFFF),
                width: sel ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(s.$3, color: s.$4, size: 18),
                const SizedBox(width: 8),
                Text(s.$2,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mediaCard() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0x22FFFFFF),
              width: 1,
              style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.perm_media_outlined,
                  color: Color(0xFF8B5CF6), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _media.isEmpty
                          ? 'Fotoğraf / Video Ekle'
                          : '${_media.length} dosya seçildi',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(AppLocalizations.of(context).obsMaxFiles,
                      style:
                          const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

