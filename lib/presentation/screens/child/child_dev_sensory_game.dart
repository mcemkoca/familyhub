import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'child_dev_content.dart' show DevHeader;

/// Duyusal Keşif — günlük rotasyonlu, interaktif duyu oyunu.
/// Çocuk, ipucundan (duyu + nesne adı) doğru emojiyi bulup dokunur.
/// 30 farklı günlük tema havuzu; görsel ayırt etme ve duyusal eşleştirme.

class _SenseItem {
  final String name;
  final String emoji;
  const _SenseItem(this.name, this.emoji);
}

/// Duyu kategorileri — her tema bir duyuya odaklanır.
const Map<String, List<_SenseItem>> _senseGroups = {
  'Görme': [
    _SenseItem('Güneş', '☀️'),
    _SenseItem('Yıldız', '⭐'),
    _SenseItem('Gökkuşağı', '🌈'),
    _SenseItem('Balon', '🎈'),
    _SenseItem('Ay', '🌙'),
    _SenseItem('Şimşek', '⚡'),
  ],
  'İşitme': [
    _SenseItem('Zil', '🔔'),
    _SenseItem('Davul', '🥁'),
    _SenseItem('Gitar', '🎸'),
    _SenseItem('Trompet', '🎺'),
    _SenseItem('Kuş', '🐦'),
    _SenseItem('Piyano', '🎹'),
  ],
  'Dokunma': [
    _SenseItem('Kaktüs', '🌵'),
    _SenseItem('Tüy', '🪶'),
    _SenseItem('Taş', '🪨'),
    _SenseItem('Kar', '❄️'),
    _SenseItem('Pamuk', '☁️'),
    _SenseItem('Yaprak', '🍃'),
  ],
  'Tatma': [
    _SenseItem('Elma', '🍎'),
    _SenseItem('Limon', '🍋'),
    _SenseItem('Çilek', '🍓'),
    _SenseItem('Bal', '🍯'),
    _SenseItem('Dondurma', '🍦'),
    _SenseItem('Karpuz', '🍉'),
  ],
  'Koklama': [
    _SenseItem('Çiçek', '🌸'),
    _SenseItem('Kahve', '☕'),
    _SenseItem('Ekmek', '🍞'),
    _SenseItem('Sabun', '🧼'),
    _SenseItem('Portakal', '🍊'),
    _SenseItem('Nane', '🌿'),
  ],
};

/// 30 günlük tema: (başlık, duyu grubu, seçenek sayısı, tur sayısı).
const List<(String, String, int, int)> _dailyThemes = [
  ('Gözlerimle Görüyorum', 'Görme', 3, 8),
  ('Kulaklarımla Duyuyorum', 'İşitme', 3, 8),
  ('Ellerimle Dokunuyorum', 'Dokunma', 3, 8),
  ('Dilimle Tadıyorum', 'Tatma', 3, 8),
  ('Burnumla Kokluyorum', 'Koklama', 3, 8),
  ('Parlak Işıklar', 'Görme', 4, 10),
  ('Sesli Nesneler', 'İşitme', 4, 10),
  ('Yumuşak mı Sert mi?', 'Dokunma', 4, 10),
  ('Tatlı ve Ekşi', 'Tatma', 4, 10),
  ('Güzel Kokular', 'Koklama', 4, 10),
  ('Renkli Dünya', 'Görme', 4, 10),
  ('Müzik Aletleri', 'İşitme', 4, 10),
  ('Doğada Dokunuş', 'Dokunma', 4, 10),
  ('Meyve Bahçesi', 'Tatma', 4, 10),
  ('Mutfak Kokuları', 'Koklama', 4, 10),
  ('Gökyüzü Keşfi', 'Görme', 4, 10),
  ('Ritim Zamanı', 'İşitme', 4, 10),
  ('Sıcak ve Soğuk', 'Dokunma', 4, 10),
  ('Lezzet Avı', 'Tatma', 4, 12),
  ('Koku Dedektifi', 'Koklama', 4, 12),
  ('Işık Ustası', 'Görme', 4, 12),
  ('Ses Ustası', 'İşitme', 4, 12),
  ('Dokunma Ustası', 'Dokunma', 4, 12),
  ('Tat Ustası', 'Tatma', 4, 12),
  ('Koku Ustası', 'Koklama', 4, 12),
  ('Beş Duyu Karışık', 'Görme', 4, 10),
  ('Duyular Bir Arada', 'İşitme', 4, 10),
  ('Süper Duyular', 'Dokunma', 4, 12),
  ('Duyu Kâşifi', 'Tatma', 4, 12),
  ('Büyük Duyu Finali', 'Koklama', 4, 12),
];

class SensoryGameScreen extends StatefulWidget {
  const SensoryGameScreen({super.key});

  @override
  State<SensoryGameScreen> createState() => _SensoryGameScreenState();
}

class _SensoryGameScreenState extends State<SensoryGameScreen> {
  late (String, String, int, int) _theme;
  late List<_SenseItem> _group;
  late int _optionCount;
  late int _totalRounds;
  final _rnd = Random();

  int _round = 0;
  int _score = 0;
  late _SenseItem _target;
  late List<_SenseItem> _options;
  bool _answered = false;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;
    _theme = _dailyThemes[dayIndex % _dailyThemes.length];
    _group = _senseGroups[_theme.$2] ?? _senseGroups['Görme']!;
    _optionCount = _theme.$3.clamp(2, _group.length);
    _totalRounds = _theme.$4;
    _newRound();
  }

  void _newRound() {
    final pool = List<_SenseItem>.from(_group)..shuffle(_rnd);
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
            Text(_score >= _totalRounds * 0.7 ? '🎉' : '👍',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('$_score / $_totalRounds doğru',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Duyularını harika kullandın! Yarın yeni bir keşif seni bekliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
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
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tekrar Oyna'),
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
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Bitir',
                        style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(
              title: 'Duyusal Keşif',
              subtitle: 'Bugünün oyunu: ${_theme.$1}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Tur ${_round + 1}/$_totalRounds',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_theme.$2,
                        style: const TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Row(children: [
                    const Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                    const SizedBox(width: 4),
                    Text('$_score',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Bunu bul:',
                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF6366F1), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(80),
                      blurRadius: 20),
                ],
              ),
              alignment: Alignment.center,
              child: Text(_target.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
            ),
            const Spacer(),
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
                        color: const Color(0xFF13131A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: correct
                              ? const Color(0xFF22C55E)
                              : wrong
                                  ? Colors.red
                                  : const Color(0xFF262631),
                          width: correct || wrong ? 4 : 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(o.emoji,
                          style: const TextStyle(fontSize: 54)),
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
