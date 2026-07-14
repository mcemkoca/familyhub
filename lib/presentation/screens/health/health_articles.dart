import 'package:flutter/material.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'health_store.dart';
import '../../../services/ai/ai_content_service.dart';
import 'health_articles_data.dart';

/// Sağlık Makaleleri — kategorili, görselli sağlık içerikleri.
/// Görsel: ağdan (Unsplash) yüklenir, başarısızsa degrade+emoji fallback.
/// İçerik bilgilendirme amaçlıdır (teşhis koymaz).

const _categories = [
  ('senin', Icons.star),
  ('populer', Icons.local_fire_department),
  ('cocuk', Icons.child_care),
  ('kadin', Icons.female),
  ('aile', Icons.groups),
];

/// Kategori anahtarını aktif dildeki etikete çevirir.
String _categoryLabel(BuildContext context, String key) {
  final l = AppLocalizations.of(context);
  switch (key) {
    case 'senin':
      return l.haCatForYou;
    case 'populer':
      return l.haCatPopular;
    case 'cocuk':
      return l.haCatChild;
    case 'kadin':
      return l.haCatWomen;
    case 'aile':
      return l.haCatFamily;
    default:
      return key;
  }
}

class HealthArticlesScreen extends StatefulWidget {
  const HealthArticlesScreen({super.key});

  @override
  State<HealthArticlesScreen> createState() => _HealthArticlesScreenState();
}

class _HealthArticlesScreenState extends State<HealthArticlesScreen> {
  String _cat = 'senin';
  List<HealthArticle> _aiArticles = [];
  bool _loadingAi = false;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _loadAi();
  }

  /// AI'dan taze sağlık makaleleri çeker (haftalık önbellek + Yenile ile anlık).
  Future<void> _loadAi({bool force = false}) async {
    setState(() => _loadingAi = true);
    // AI içeriğini aktif dilde üret; etiketleri await öncesi yakala.
    final lang = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context);
    final currentLabel = l.haCatCurrent;
    final todayLabel = l.haDateToday;
    final langName = switch (lang) {
      'nl' => 'Hollandaca (Nederlands)',
      'fr' => 'Fransızca (Français)',
      'en' => 'İngilizce (English)',
      _ => 'Türkçe',
    };
    try {
      final items = await AiContentService.weeklyList(
        topic: 'health_articles_${_tick}_$lang',
        forceRefresh: force,
        maxTokens: 1100,
        prompt: '''
Bir aile sağlığı uygulaması için 4 kısa, güncel ve güvenilir sağlık makalesi üret.
Konular çeşitli olsun (beslenme, çocuk sağlığı, bağışıklık, uyku, hareket, mevsimsel).
Teşhis koyma; bilgilendirici ve pratik ol. Sadece JSON döndür:
{"items":[{"title":"Başlık","summary":"1 cümle özet","emoji":"🥗","body":["paragraf 1","paragraf 2","paragraf 3"]}]}
Tüm metinleri $langName dilinde yaz.''',
        listKey: 'items',
        fallback: const [],
      );
      final parsed = items
          .map(
            (e) => HealthArticle(
              id: 'ai_${e['title'].hashCode}',
              category: 'yeni',
              categoryLabel: currentLabel,
              categoryColor: const Color(0xFF14B8A6),
              title: (e['title'] ?? '').toString(),
              summary: (e['summary'] ?? '').toString(),
              emoji: (e['emoji'] ?? '🩺').toString(),
              imageUrl: '',
              dateLabel: todayLabel,
              body:
                  (e['body'] as List?)
                      ?.map((x) => x.toString())
                      .where((x) => x.isNotEmpty)
                      .toList() ??
                  const [],
            ),
          )
          .where((a) => a.title.isNotEmpty)
          .toList();
      if (mounted) setState(() => _aiArticles = parsed);
    } catch (_) {
      // AI erişilemezse statik makaleler yine gösterilir.
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  List<HealthArticle> _filteredFor(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final base = [..._aiArticles, ...healthArticlesFor(lang)];
    if (_cat == 'senin' || _cat == 'populer') return base;
    return base.where((a) => a.category == _cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingAi
            ? null
            : () {
                setState(() => _tick++);
                _loadAi(force: true);
              },
        backgroundColor: const Color(0xFF14B8A6),
        icon: _loadingAi
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh_rounded, color: Colors.white),
        label: Text(
          _loadingAi
              ? AppLocalizations.of(context).commonRefreshing
              : AppLocalizations.of(context).commonRefresh,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
              title: AppLocalizations.of(context).haTitle,
              subtitle: AppLocalizations.of(context).haSubtitle,
              icon: Icons.monitor_heart_rounded,
              showBack: true,
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((c) {
                  final sel = _cat == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _cat = c.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF6366F1)
                                : const Color(0x14FFFFFF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              c.$2,
                              size: 15,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _categoryLabel(context, c.$1),
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  ..._filteredFor(context).map((a) => _card(a)),
                  const SizedBox(height: 6),
                  _seeAll(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(HealthArticle a) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ArticleDetail(article: a)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: _thumb(a),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: a.categoryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.categoryLabel,
                        style: TextStyle(
                          color: a.categoryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.dateLabel,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(HealthArticle a) {
    return SizedBox(
      width: 110,
      height: 116,
      child: Image.network(
        a.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(a),
        loadingBuilder: (_, child, prog) => prog == null ? child : _fallback(a),
      ),
    );
  }

  Widget _fallback(HealthArticle a) => Container(
    width: 110,
    height: 116,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [a.categoryColor, a.categoryColor.withAlpha(150)],
      ),
    ),
    child: Center(child: Text(a.emoji, style: const TextStyle(fontSize: 40))),
  );

  Widget _seeAll() {
    return GestureDetector(
      onTap: () => setState(() => _cat = 'senin'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x226366F1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(30),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.menu_book, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).haSeeAll,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).haBrowseAll,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}

class _ArticleDetail extends StatelessWidget {
  final HealthArticle article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            HealthHeader(
              title: article.categoryLabel,
              subtitle: AppLocalizations.of(context).haArticleBadge,
              showBack: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 190,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                article.categoryColor,
                                article.categoryColor.withAlpha(150),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              article.emoji,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...article.body.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        p,
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
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
}
