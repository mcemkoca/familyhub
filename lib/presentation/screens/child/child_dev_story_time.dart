import 'package:flutter/material.dart';
import '../../widgets/external_link.dart';
import 'child_dev_content.dart' show DevHeader;
import 'child_dev_stories.dart';

/// Hikaye Zamanı — günün 4 görselli hikayesi.
class StoryTimeScreen extends StatelessWidget {
  const StoryTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            const DevHeader(
              title: 'Hikaye Zamanı',
              subtitle: 'Bugünün 4 görselli hikayesi',
            ),
            Expanded(
              child: FutureBuilder<List<KidStory>>(
                future: aiDailyStories(),
                initialData: dailyStories(),
                builder: (context, snap) {
                  final stories = snap.data ?? dailyStories();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: stories.length,
                    itemBuilder: (context, i) =>
                        _storyCard(context, stories[i], i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyCard(BuildContext context, KidStory s, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoryReaderScreen(story: s)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: s.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: s.gradient.first.withAlpha(70), blurRadius: 14),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -18,
              child: Text(s.emoji,
                  style: TextStyle(
                      fontSize: 120,
                      color: Colors.white.withAlpha(40))),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Hikaye ${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(s.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.menu_book,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text('${s.pages.length} sayfa · Oku',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görselli hikaye okuyucu (sayfa sayfa).
class StoryReaderScreen extends StatefulWidget {
  final KidStory story;
  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final totalPages = s.pages.length + 1; // +1 son sayfa (ders)
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            DevHeader(title: s.title, subtitle: 'Görselli hikaye'),
            // Sayfa göstergesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(totalPages, (i) {
                  final active = i <= _page;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? s.gradient.first
                            : const Color(0xFF2A2A34),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: totalPages,
                itemBuilder: (context, i) {
                  if (i == s.pages.length) return _endPage(s);
                  return _storyPage(s, s.pages[i]);
                },
              ),
            ),
            // Alt gezinme
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    _navBtn('Geri', Icons.arrow_back, () {
                      _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }, filled: false, color: s.gradient.first),
                  const Spacer(),
                  if (_page < totalPages - 1)
                    _navBtn('İleri', Icons.arrow_forward, () {
                      _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }, filled: true, color: s.gradient.first)
                  else
                    _navBtn('Bitir', Icons.check, () => Navigator.pop(context),
                        filled: true, color: s.gradient.first),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyPage(KidStory s, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          // Görsel sahne
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: s.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
                child: Text(s.emoji, style: const TextStyle(fontSize: 110))),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFFE5E7EB), fontSize: 18, height: 1.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endPage(KidStory s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: s.gradient),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Hikayeden Ders',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(s.moral,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFD1D5DB), fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          if (s.readMoreUrl != null)
            OutlinedButton.icon(
              onPressed: () => openExternalLink(context, s.readMoreUrl!),
              style: OutlinedButton.styleFrom(
                foregroundColor: s.gradient.first,
                side: BorderSide(color: s.gradient.first),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('İnternetten devamını oku'),
            ),
        ],
      ),
    );
  }

  Widget _navBtn(String label, IconData icon, VoidCallback onTap,
      {required bool filled, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            if (!filled) Icon(icon, size: 16, color: color),
            if (!filled) const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.w700)),
            if (filled) const SizedBox(width: 6),
            if (filled) Icon(icon, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
