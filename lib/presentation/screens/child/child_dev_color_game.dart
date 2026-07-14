import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'child_dev_content.dart' show DevHeader;

/// Renkleri Eşleştirme — günlük rotasyonlu, interaktif renk oyunu.
/// 30 farklı "tur teması" havuzundan her gün farklı bir set gelir.
/// Oyun: hedef rengi, seçenekler arasından doğru olanı bulup dokun.

class _ColorItem {
  final String name;
  final Color color;
  const _ColorItem(this.name, this.color);
}

const List<_ColorItem> _palette = [
  _ColorItem('Kırmızı', Color(0xFFEF4444)),
  _ColorItem('Turuncu', Color(0xFFF97316)),
  _ColorItem('Sarı', Color(0xFFEAB308)),
  _ColorItem('Yeşil', Color(0xFF22C55E)),
  _ColorItem('Mavi', Color(0xFF3B82F6)),
  _ColorItem('Mor', Color(0xFF8B5CF6)),
  _ColorItem('Pembe', Color(0xFFEC4899)),
  _ColorItem('Kahverengi', Color(0xFF92400E)),
  _ColorItem('Turkuaz', Color(0xFF14B8A6)),
  _ColorItem('Lacivert', Color(0xFF1E3A8A)),
  _ColorItem('Gri', Color(0xFF6B7280)),
  _ColorItem('Siyah', Color(0xFF111827)),
];

/// 30 günlük tema: (başlık, seçenek sayısı, tur sayısı).
const List<(String, int, int)> _dailyThemes = [
  ('Ana Renkler', 3, 8),
  ('Sıcak Renkler', 3, 8),
  ('Soğuk Renkler', 3, 8),
  ('Gökkuşağı', 4, 10),
  ('Doğa Renkleri', 3, 8),
  ('Meyve Renkleri', 4, 10),
  ('Deniz Renkleri', 3, 8),
  ('Bahar Renkleri', 4, 10),
  ('Karışık Kolay', 3, 8),
  ('Karışık Orta', 4, 10),
  ('Renk Ustası', 4, 12),
  ('Pastel Keşif', 4, 10),
  ('Canlı Renkler', 4, 10),
  ('Toprak Tonları', 3, 8),
  ('Gün Batımı', 3, 8),
  ('Orman', 3, 8),
  ('Balon Partisi', 4, 10),
  ('Şeker Dünyası', 4, 10),
  ('Uzay', 4, 10),
  ('Çiçek Bahçesi', 4, 10),
  ('Kelebekler', 4, 10),
  ('Deniz Altı', 3, 8),
  ('Mevsimler', 4, 10),
  ('Trafik Işıkları', 3, 6),
  ('Meyve Sepeti', 4, 10),
  ('Kış Masalı', 3, 8),
  ('Yaz Güneşi', 3, 8),
  ('Renk Dedektifi', 4, 12),
  ('Süper Renkler', 4, 12),
  ('Büyük Final', 4, 12),
];

class ColorGameScreen extends StatefulWidget {
  const ColorGameScreen({super.key});

  @override
  State<ColorGameScreen> createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen> {
  late (String, int, int) _theme;
  late int _optionCount;
  late int _totalRounds;
  final _rnd = Random();

  int _round = 0;
  int _score = 0;
  late _ColorItem _target;
  late List<_ColorItem> _options;
  bool _answered = false;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;
    _theme = _dailyThemes[dayIndex % _dailyThemes.length];
    _optionCount = _theme.$2;
    _totalRounds = _theme.$3;
    _newRound();
  }

  void _newRound() {
    final pool = List<_ColorItem>.from(_palette)..shuffle(_rnd);
    _options = pool.take(_optionCount).toList();
    _target = _options[_rnd.nextInt(_options.length)];
    _answered = false;
    _wrongIndex = null;
  }

  void _pick(int i) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    final correct = _options[i].name == _target.name;
    setState(() {
      _answered = true;
      if (correct) {
        _score++;
      } else {
        _wrongIndex = i;
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_round + 1 >= _totalRounds) {
        _showResult();
      } else {
        setState(() {
          _round++;
          _newRound();
        });
      }
    });
  }

  void _showResult() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _score >= _totalRounds * 0.7 ? '🎉' : '👍',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              '$_score / $_totalRounds doğru',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.devColorGameWin,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _round = 0;
                        _score = 0;
                        _newRound();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l.commonPlayAgain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l.commonFinish,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: l.devColorGameTitle,
              subtitle: l.devColorGameToday(_theme.$1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l.devColorGameRound(_round + 1, _totalRounds),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFEAB308),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Hedef
            Text(
              l.devColorGameFindColor,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _target.color,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _target.color.withAlpha(120),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _target.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            // Seçenekler
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: List.generate(_options.length, (i) {
                  final o = _options[i];
                  final correct = _answered && o.name == _target.name;
                  final wrong = _wrongIndex == i;
                  return GestureDetector(
                    onTap: () => _pick(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: o.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: correct
                              ? Colors.white
                              : wrong
                              ? Colors.red
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: correct
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 40,
                            )
                          : wrong
                          ? const Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
