import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/content/content_localizer.dart';
import 'package:familyhub/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../services/hive_service.dart';
import '../../../services/ai/pedagogy_engine.dart';
import '../../widgets/ds.dart';
import '../../widgets/growing_tree.dart';
import '../../widgets/external_link.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen>
    with SingleTickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  late TabController _tabController;
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/content/education.json',
      );
      if (!mounted) return;
      final lang = Localizations.localeOf(context).languageCode;
      final list = normalizeContentList(jsonDecode(raw) as List, lang);
      final custom = normalizeContentList(_loadCustomRaw(), lang);
      setState(() {
        _activities = [...custom, ...list];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _loadCustomRaw() {
    try {
      final raw = HiveService.getSetting('custom_edu_activities');
      if (raw == null || raw.isEmpty) return const [];
      return jsonDecode(raw) as List;
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _loadCustom() {
    try {
      final raw = HiveService.getSetting('custom_edu_activities');
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustom(Map<String, dynamic> activity) async {
    final list = _loadCustom();
    list.insert(0, activity);
    await HiveService.setSetting('custom_edu_activities', jsonEncode(list));
    setState(() => _activities = [activity, ..._activities]);
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddActivitySheet(onSave: _saveCustom),
    );
  }

  // AI ile herhangi bir konuda çocuğa özel ders/görev kartı üretir.
  void _openAiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiLessonSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ActivitiesTab(activities: _activities, isDark: isDark),
                        _ParentGuideTab(
                          activities: _activities,
                          isDark: isDark,
                        ),
                        _ProgressTab(activities: _activities, isDark: isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    const violet = Color(0xFF8B5CF6);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF150D2A), Color(0xFF1A0D30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: violet.withAlpha(50), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: violet.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: violet.withAlpha(80), blurRadius: 10),
              ],
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).eduTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_activities.length} aktivite · rehber · takip',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(120),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // AI Ders Üret + İçerik Ekle (shell nav çubuğu FAB'ları örttüğü için başlıkta)
          GestureDetector(
            onTap: _openAiSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(90),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openAddSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: violet,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: violet.withAlpha(90), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const violet = Color(0xFF8B5CF6);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      height: 44,
      decoration: BoxDecoration(
        color: Ds.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Ds.glassBorder, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: violet,
        unselectedLabelColor: Ds.textSub,
        indicatorColor: violet,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.apps, size: 16), text: 'Aktiviteler'),
          Tab(icon: Icon(Icons.menu_book, size: 16), text: 'Rehber'),
          Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'İlerleme'),
        ],
      ),
    );
  }
}

// ─── TAB 1: Aktiviteler ─────────────────────────────────────────────────────

class _ActivitiesTab extends StatefulWidget {
  final List<Map<String, dynamic>> activities;
  final bool isDark;
  const _ActivitiesTab({required this.activities, required this.isDark});

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  String _selectedCategory = 'tümü';
  String _searchQuery = '';
  int? _ageFilter;

  static const _categories = [
    ('tümü', 'Tümü', Icons.apps),
    ('okul_oncesi', 'Okul Öncesi', Icons.child_care),
    ('ilkokul', 'İlkokul', Icons.menu_book),
    ('ortaokul', 'Ortaokul', Icons.school),
    ('lise', 'Lise', Icons.school_outlined),
    ('stem', 'STEM', Icons.science),
    ('dil_ogrenimi', 'Dil', Icons.translate),
    ('sanat_egitimi', 'Sanat', Icons.palette),
    ('muzik_egitimi', 'Müzik', Icons.music_note),
    ('spor', 'Spor', Icons.sports_soccer),
    ('yaraticilik', 'Yaratıcılık', Icons.lightbulb),
    ('sosyal_beceriler', 'Sosyal', Icons.people),
    ('duygusal_zeka', 'Duygusal Zeka', Icons.favorite),
    ('finansal_okuryazarlik', 'Finans', Icons.savings),
    ('cevre_bilinci', 'Çevre', Icons.eco),
    ('dijital_okuryazarlik', 'Dijital', Icons.computer),
    ('hafiza_gelistirme', 'Hafıza', Icons.psychology),
    ('odaklanma', 'Odaklanma', Icons.center_focus_strong),
    ('problem_cozme', 'Problem Çözme', Icons.extension),
    ('elestirel_dusunme', 'Eleştirel', Icons.lightbulb_outline),
    ('liderlik', 'Liderlik', Icons.groups),
  ];

  List<Map<String, dynamic>> get _filtered {
    return widget.activities.where((a) {
      final cat = (a['category'] as String?)?.toLowerCase() ?? '';
      final matchCat = _selectedCategory == 'tümü' || cat == _selectedCategory;
      final matchSearch =
          _searchQuery.isEmpty ||
          (a['title'] as String?)?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ==
              true;
      final ageGroup = a['age_group'] as Map<String, dynamic>?;
      final matchAge =
          _ageFilter == null ||
          ((ageGroup?['min'] as int? ?? 0) <= _ageFilter! &&
              (ageGroup?['max'] as int? ?? 18) >= _ageFilter!);
      return matchCat && matchSearch && matchAge;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        const SizedBox(height: 8),
        // Search + age filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Color(0xFFE5E7EB)),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).eduSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF13131A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AgeFilterButton(
                age: _ageFilter,
                isDark: widget.isDark,
                onChanged: (v) => setState(() => _ageFilter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Category chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final (id, label, icon) = _categories[i];
              final active = _selectedCategory == id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF8B5CF6)
                        : (const Color(0xFF13131A)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF8B5CF6)
                          : (widget.isDark
                                ? const Color(0x1EFFFFFF)
                                : const Color(0x1EFFFFFF)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 12,
                        color: active
                            ? Colors.white
                            : (const Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? Colors.white
                              : (const Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} aktivite bulundu',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).eduNoActivity),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _ActivityCard(
                    activity: filtered[i],
                    isDark: widget.isDark,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          ActivityDetailSheet(activity: filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AgeFilterButton extends StatelessWidget {
  final int? age;
  final bool isDark;
  final ValueChanged<int?> onChanged;
  const _AgeFilterButton({
    required this.age,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => SimpleDialog(
          title: Text(AppLocalizations.of(context).eduFilterByAge),
          children: [
            SimpleDialogOption(
              onPressed: () {
                onChanged(null);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).tumu),
            ),
            ...[3, 5, 7, 9, 11, 13, 15, 17].map(
              (a) => SimpleDialogOption(
                onPressed: () {
                  onChanged(a);
                  Navigator.pop(context);
                },
                child: Text('$a yaş'),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: age != null
              ? const Color(0xFF8B5CF6)
              : (const Color(0xFF13131A)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: age != null
                ? const Color(0xFF8B5CF6)
                : (const Color(0x1EFFFFFF)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: age != null ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              age != null
                  ? AppLocalizations.of(context).eduAgeYears(age!)
                  : AppLocalizations.of(context).eduAge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: age != null ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 2: Ebeveyn Rehberi ─────────────────────────────────────────────────

class _ParentGuideTab extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final bool isDark;
  const _ParentGuideTab({required this.activities, required this.isDark});

  static const _guides = [
    (
      Icons.psychology,
      '🧠',
      'Bilişsel Gelişim',
      Color(0xFF8B5CF6),
      'Çocuğun düşünme ve problem çözme becerilerini nasıl desteklersiniz?',
    ),
    (
      Icons.favorite,
      '❤️',
      'Duygusal Zeka',
      Color(0xFFEC4899),
      'Empati, öz-düzenleme ve sosyal becerileri geliştirme yolları.',
    ),
    (
      Icons.science,
      '🔬',
      'STEM Eğitimi',
      Color(0xFF06B6D4),
      'Günlük hayatta fen, teknoloji, mühendislik ve matematik.',
    ),
    (
      Icons.palette,
      '🎨',
      'Sanat & Yaratıcılık',
      Color(0xFFF97316),
      'Yaratıcı ifadeyi teşvik etmenin pratik yolları.',
    ),
    (
      Icons.music_note,
      '🎵',
      'Müzik Eğitimi',
      Color(0xFF10B981),
      'Ritim, melodi ve müzikle çocuk gelişimi.',
    ),
    (
      Icons.sports,
      '⚽',
      'Fiziksel Gelişim',
      Color(0xFFF59E0B),
      'Hareket, spor ve motor beceri gelişimi.',
    ),
    (
      Icons.book,
      '📖',
      'Okuma Alışkanlığı',
      Color(0xFF3B82F6),
      'Kitap sevgisini erken yaşta aşılamanın yolları.',
    ),
    (
      Icons.language,
      '🌍',
      'Dil Öğrenimi',
      Color(0xFF6366F1),
      'İkinci dil öğrenimini eğlenceli hale getirme.',
    ),
  ];

  // Rehber zengin içerikleri — bölümler + ipuçları + video araması
  static const Map<String, Map<String, dynamic>> _guideContent = {
    'Bilişsel Gelişim': {
      'intro':
          'Bilişsel gelişim; çocuğun düşünme, hatırlama, problem çözme ve dikkat becerilerini kapsar. Günlük küçük etkileşimler bu becerileri güçlü şekilde destekler.',
      'sections': [
        [
          'Meraki besleyin',
          'Çocuğun "neden?" sorularını ciddiye alın. Cevabı hemen vermek yerine "sen ne düşünüyorsun?" diye sorun. Bu, akıl yürütmeyi tetikler.',
        ],
        [
          'Oyunla öğretin',
          'Bulmaca, eşleştirme ve sıralama oyunları hafızayı ve mantığı geliştirir. Günde 15-20 dakika yeterlidir.',
        ],
        [
          'Seçim yaptırın',
          'Küçük günlük seçimler (hangi kıyafet, hangi kitap) karar verme ve sonuç değerlendirme becerisi kazandırır.',
        ],
      ],
      'tips': [
        'Ekran süresini sınırlayın.',
        'Bol bol sesli kitap okuyun.',
        'Hataları öğrenme fırsatı olarak görün.',
      ],
      'video': 'çocuklarda bilişsel gelişim ebeveyn',
    },
    'Duygusal Zeka': {
      'intro':
          'Duygusal zeka; duyguları tanıma, ifade etme ve yönetme becerisidir. Empati ve sosyal ilişkilerin temelidir.',
      'sections': [
        [
          'Duyguları adlandırın',
          'Çocuk üzgün ya da kızgınken "şu an kızgın hissediyorsun" diyerek duyguyu adlandırın. Bu, duygu farkındalığını artırır.',
        ],
        [
          'Model olun',
          'Kendi duygunuzu sağlıklı ifade edin: "Yorgunum, biraz dinlenmem lazım". Çocuk sizi izleyerek öğrenir.',
        ],
        [
          'Sakinleşme köşesi',
          'Öfke anında birlikte derin nefes alın. Bir "sakin köşe" oluşturmak öz-düzenlemeyi kolaylaştırır.',
        ],
      ],
      'tips': [
        'Hiçbir duyguyu "kötü" damgalamayın.',
        'Dinlerken göz teması kurun.',
        'Empatiyi hikayelerle pekiştirin.',
      ],
      'video': 'çocuklarda duygusal zeka geliştirme',
    },
    'STEM Eğitimi': {
      'intro':
          'STEM (Fen, Teknoloji, Mühendislik, Matematik) günlük hayatın içindedir. Mutfak, bahçe ve oyunlar doğal birer laboratuvardır.',
      'sections': [
        [
          'Mutfakta bilim',
          'Yemek yaparken ölçme, karıştırma ve hâl değişimlerini konuşun. Kabartma tozu-sirke deneyi klasiktir.',
        ],
        [
          'Yapı-inşa oyunları',
          'Legolar ve bloklar mühendislik ve geometri sezgisi kazandırır. "En yüksek kuleyi yap" gibi hedefler koyun.',
        ],
        [
          'Kodlamaya giriş',
          'ScratchJr veya Code.org ile 5+ yaş için ücretsiz, eğlenceli kodlama başlangıcı yapılabilir.',
        ],
      ],
      'tips': [
        'Önce tahmin ettirin, sonra deneyin.',
        'Hata = veri; tekrar deneyin.',
        'Güvenlik önce.',
      ],
      'video': 'evde çocuklarla STEM etkinlikleri',
    },
    'Sanat & Yaratıcılık': {
      'intro':
          'Sanat; hayal gücünü, ince motor becerileri ve öz-ifadeyi geliştirir. Sonuç değil süreç önemlidir.',
      'sections': [
        [
          'Serbest bırakın',
          'Boyama ve hamur çalışmalarında kurallar az olsun. "Doğru" bir sonuç beklemeyin.',
        ],
        [
          'Malzeme çeşitliliği',
          'Parmak boyası, sünger, doğal nesneler farklı dokular ve deneyimler sunar.',
        ],
        [
          'Sergileyin',
          'Eserleri bir yere asın. Bu, çocuğun özgüvenini ve motivasyonunu artırır.',
        ],
      ],
      'tips': [
        '"Güzel olmamış" demeyin.',
        'Çabayı övün, sonucu değil.',
        'Önlük ile rahat bırakın.',
      ],
      'video': 'çocuklar için yaratıcı sanat etkinlikleri',
    },
    'Müzik Eğitimi': {
      'intro':
          'Müzik; ritim duygusu, işitsel algı, dil ve duygusal ifadeyi destekler. Nota bilgisi şart değildir.',
      'sections': [
        [
          'Ritim tutun',
          'Şarkılarla el çırpın, ev yapımı davul çalın. Tempo duygusu böyle gelişir.',
        ],
        [
          'Ses keşfi',
          'Yüksek-alçak, hızlı-yavaş sesleri ayırt ettirin. Bu işitsel dikkati güçlendirir.',
        ],
        [
          'Aile konseri',
          'Basit bir "konser" düzenleyin; sahne özgüveni ve keyif kazandırır.',
        ],
      ],
      'tips': [
        'Her sesi "farklı" görün, "yanlış" değil.',
        'Günlük kısa tekrar etkilidir.',
        'Zorlamayın, keyif esas.',
      ],
      'video': 'çocuklar için müzik etkinlikleri ritim',
    },
    'Fiziksel Gelişim': {
      'intro':
          'Hareket; motor beceri, denge, koordinasyon ve sağlıklı gelişimin temelidir. Günde en az 60 dakika aktif oyun önerilir.',
      'sections': [
        [
          'Isınma-oyun-soğuma',
          'Aktiviteye ısınmayla başlayın, oyunla sürdürün, esnemeyle bitirin.',
        ],
        [
          'Kaba motor',
          'Koşma, zıplama, tırmanma büyük kasları geliştirir. Parklar ideal.',
        ],
        [
          'İnce motor',
          'Top yakalama, ip atlama el-göz koordinasyonunu güçlendirir.',
        ],
      ],
      'tips': [
        'Yarış değil gelişim odaklı olun.',
        'Su tüketimini unutmayın.',
        'Gözetim şart.',
      ],
      'video': 'çocuklar için fiziksel aktivite oyunları',
    },
    'Okuma Alışkanlığı': {
      'intro':
          'Erken okuma sevgisi; kelime dağarcığı, hayal gücü ve akademik başarının en güçlü yordayıcısıdır.',
      'sections': [
        [
          'Rutin oluşturun',
          'Her gün aynı saatte 15 dakika okuma zamanı belirleyin. Tutarlılık alışkanlık yaratır.',
        ],
        [
          'Canlandırarak okuyun',
          'Sesleri, karakterleri canlandırın. "Sence sonra ne olacak?" diye sorun.',
        ],
        ['Örnek olun', 'Sizi kitap okurken gören çocuk okumayı değerli görür.'],
      ],
      'tips': [
        'Zorla değil, keyifle.',
        'Kütüphaneye birlikte gidin.',
        'Resimli kitaplarla başlayın.',
      ],
      'video': 'çocuklarda okuma alışkanlığı kazandırma',
    },
    'Dil Öğrenimi': {
      'intro':
          'Erken yaşta ikinci dil; beyin esnekliği sayesinde doğal ve kalıcı öğrenilir. Baskı değil, maruz kalma önemlidir.',
      'sections': [
        [
          'Günlük maruz kalma',
          'Şarkılar, kısa çizgi filmler ve etiketlerle dili günlük hayata sokun.',
        ],
        [
          'Oyunla pekiştirin',
          'Kelime kartları ve hareketli oyunlar kalıcılığı artırır.',
        ],
        [
          'Hataya hoşgörü',
          'Hataları düzeltirken sabırlı olun; iletişim cesaretini kırmayın.',
        ],
      ],
      'tips': [
        'Günlük kısa tekrar > uzun ders.',
        'Telaffuzu şarkıyla öğretin.',
        'İlerlemeyi kutlayın.',
      ],
      'video': 'çocuklara ikinci dil öğretme yöntemleri',
    },
  };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final (icon, _, title, color, desc) = _guides[i];
        final related = activities
            .where(
              (a) =>
                  (a['title'] as String?)?.toLowerCase().contains(
                    title.split(' ').first.toLowerCase(),
                  ) ==
                  true,
            )
            .take(3)
            .toList();

        return GestureDetector(
          onTap: () => _showGuideDetail(context, title, desc, color, related),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withAlpha(180)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGuideDetail(
    BuildContext context,
    String title,
    String desc,
    Color color,
    List<Map<String, dynamic>> related,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF13131A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x1EFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Zengin rehber içeriği ──
              ...(() {
                final content = _guideContent[title];
                if (content == null) return <Widget>[];
                final intro = content['intro'] as String? ?? '';
                final sections =
                    (content['sections'] as List?)?.cast<List<dynamic>>() ?? [];
                final tips = (content['tips'] as List?)?.cast<String>() ?? [];
                final videoQuery = content['video'] as String? ?? '';
                return [
                  const SizedBox(height: 16),
                  _ActivityImageBanner(keyword: title, title: title),
                  const SizedBox(height: 16),
                  Text(
                    intro,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: Color(0xFFD1D5DB),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...sections.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s[0].toString(),
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              s[1].toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tips.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context).eduPracticalTips,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...tips.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(color: Color(0xFF9CA3AF)),
                                  ),
                                  Expanded(
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.4,
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (videoQuery.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => openExternalLink(
                        context,
                        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(videoQuery)}',
                        label: AppLocalizations.of(context).eduYoutubeSearch,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF0000).withAlpha(90),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              color: Color(0xFFFF3B30),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).eduWatchYoutube,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              color: Color(0xFF9CA3AF),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ];
              })(),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).eduRelatedActivities,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(height: 10),
                ...related.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0A0A0F)
                            : const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (a['title'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TAB 3: İlerleme Takibi ─────────────────────────────────────────────────

class _ProgressTab extends StatefulWidget {
  final List<Map<String, dynamic>> activities;
  final bool isDark;
  const _ProgressTab({required this.activities, required this.isDark});

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  final Set<String> _completed = {};

  static const _devAreas = [
    ('Okul Öncesi', 'okul_oncesi', Color(0xFFEC4899)),
    ('İlkokul', 'ilkokul', Color(0xFF3B82F6)),
    ('STEM', 'stem', Color(0xFF06B6D4)),
    ('Sanat', 'sanat_egitimi', Color(0xFFF97316)),
    ('Sosyal', 'sosyal_beceriler', Color(0xFF10B981)),
    ('Yaratıcılık', 'yaraticilik', Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.activities.length;
    final done = _completed.length;

    // Ağaç ilerlemesi: tamamlanan aktivite oranı (görsel ödül için ölçekli)
    final treeProgress = total == 0
        ? 0.0
        : (done / (total * 0.25)).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Büyüyen ağaç görselleştirmesi
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E1F13), Color(0xFF13131A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2E7D32).withAlpha(60)),
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context).eduLearningTree,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).eduTreeGrows,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 8),
              GrowingTree(progress: treeProgress, size: 200),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Overall progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).eduOverallProgress,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$done / $total aktivite tamamlandı',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${total > 0 ? (done * 100 ~/ total) : 0}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  backgroundColor: Colors.white.withAlpha(40),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // By category
        ..._devAreas.map((area) {
          final (label, key, color) = area;
          final areaActs = widget.activities
              .where((a) => a['category'] == key)
              .toList();
          final areaDone = areaActs
              .where((a) => _completed.contains(a['id']))
              .length;
          final areaTotal = areaActs.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$areaDone / $areaTotal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: areaTotal > 0 ? areaDone / areaTotal : 0,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                  if (areaActs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...areaActs.take(3).map((a) {
                      final id = a['id'] as String? ?? '';
                      final done = _completed.contains(id);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (done) {
                              _completed.remove(id);
                            } else {
                              _completed.add(id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: done ? color : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: done
                                        ? color
                                        : const Color(0x1EFFFFFF),
                                    width: 2,
                                  ),
                                ),
                                child: done
                                    ? const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (a['title'] ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: done
                                        ? const Color(0xFF6B7280)
                                        : (const Color(0xFFE5E7EB)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool isDark;
  final VoidCallback onTap;
  const _ActivityCard({
    required this.activity,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ageGroup = activity['age_group'] as Map<String, dynamic>? ?? {};
    final ageMin = ageGroup['min'] ?? 0;
    final ageMax = ageGroup['max'] ?? 18;
    final rating = (activity['rating'] as num?)?.toDouble() ?? 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (activity['title'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5E7EB),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: [
                      _Chip(
                        label: '$ageMin-$ageMax yaş',
                        color: const Color(0xFF8B5CF6),
                      ),
                      if (activity['duration'] != null)
                        _Chip(
                          label: activity['duration'].toString(),
                          color: const Color(0xFF6366F1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activity['review_count'] ?? 0} değerlendirme',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class ActivityDetailSheet extends StatelessWidget {
  final Map<String, dynamic> activity;
  const ActivityDetailSheet({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = (activity['steps'] as List?)?.cast<String>() ?? [];
    final tips = (activity['parent_tips'] as List?)?.cast<String>() ?? [];
    final objectives =
        (activity['learning_objectives'] as List?)?.cast<String>() ?? [];
    final materials =
        (activity['materials'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final ageGroup = activity['age_group'] as Map<String, dynamic>? ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0x1EFFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Görsel banner (internetten, kırılırsa gradient'e düşer) ──
            _ActivityImageBanner(
              keyword:
                  '${activity['title'] ?? ''} ${activity['category'] ?? ''} ${activity['development_area'] ?? ''}',
              title: (activity['title'] ?? '').toString(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    (activity['title'] ?? '').toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _DetailChip('${ageGroup['min']}-${ageGroup['max']} yaş'),
                      if (activity['duration'] != null)
                        _DetailChip(activity['duration'].toString()),
                      if (activity['frequency'] != null)
                        _DetailChip(activity['frequency'].toString()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Kronometre (aktivite süresine göre geri sayım) ──
            _ActivityTimer(
              durationText: (activity['duration'] ?? '').toString(),
            ),
            const SizedBox(height: 18),
            if (objectives.isNotEmpty) ...[
              _SectionTitle('Hedefler', Icons.flag, isDark),
              const SizedBox(height: 8),
              ...objectives.map((o) => _Bullet(o, isDark)),
              const SizedBox(height: 14),
            ],
            if (materials.isNotEmpty) ...[
              _SectionTitle('Gerekenler', Icons.inventory_2, isDark),
              const SizedBox(height: 8),
              ...materials.map((m) => _MaterialRow(m, isDark)),
              const SizedBox(height: 14),
            ],
            if (steps.isNotEmpty) ...[
              _SectionTitle('Nasıl Yapılır?', Icons.list_alt, isDark),
              const SizedBox(height: 8),
              ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (tips.isNotEmpty) ...[
              _SectionTitle('Ebeveyn İpuçları', Icons.lightbulb, isDark),
              const SizedBox(height: 8),
              ...tips.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(60),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  const _DetailChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  const _SectionTitle(this.title, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
      const SizedBox(width: 6),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE5E7EB),
        ),
      ),
    ],
  );
}

class _Bullet extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Bullet(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF8B5CF6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MaterialRow extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isDark;
  const _MaterialRow(this.material, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 14,
          color: Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${material['name']} — ${material['purpose']}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFE5E7EB)),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Görsel banner — aktiviteye uygun internetten görsel (kırılırsa gradient)
// ═══════════════════════════════════════════════════════════════════════════
class _ActivityImageBanner extends StatelessWidget {
  final String keyword;
  final String title;
  const _ActivityImageBanner({required this.keyword, required this.title});

  String _slug(String s) {
    // Konuya özel görsel anahtarları (başlık + kategori bazlı)
    final map = {
      'matematik': 'mathematics,numbers',
      'sayı': 'numbers,counting',
      'renk': 'colorful,paint',
      'okuma': 'child,reading,book',
      'kitap': 'child,books',
      'deney': 'science,experiment,kids',
      'bilim': 'science,laboratory',
      'robotik': 'robot,coding',
      'kod': 'coding,computer',
      'dijital': 'computer,kids',
      'internet': 'laptop,child',
      'ngilizce': 'english,alphabet',
      'dil': 'language,learning',
      'müzik': 'music,instruments',
      'muzik': 'music,kids',
      'enstrüman': 'guitar,piano',
      'yüzme': 'swimming,pool',
      'yuzme': 'swimming',
      'spor': 'kids,sport,football',
      'empati': 'family,hug,children',
      'duygu': 'emotion,child',
      'öfke': 'calm,meditation',
      'mindfulness': 'meditation,calm',
      'kumbara': 'coins,savings',
      'birikim': 'money,piggybank',
      'finans': 'coins,money',
      'geri dönüşüm': 'recycling,green',
      'çevre': 'nature,green,kids',
      'doğa': 'nature,forest',
      'resim': 'painting,art,kids',
      'heykel': 'sculpture,clay',
      'sanat': 'art,children,painting',
      'boya': 'paint,colorful',
      'hafıza': 'puzzle,memory,cards',
      'odak': 'focus,puzzle',
      'dikkat': 'puzzle,kids',
      'yaz': 'writing,notebook,child',
      'yaratıcı': 'creative,art,kids',
      'tartışma': 'discussion,kids',
      'münazara': 'debate,speaking',
      'liderlik': 'teamwork,children',
      'problem': 'puzzle,thinking',
      'eleştirel': 'thinking,puzzle',
    };
    final k = keyword.toLowerCase();
    for (final e in map.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return 'children,education,learning';
  }

  @override
  Widget build(BuildContext context) {
    // LoremFlickr: anahtar kelimeye göre görsel sağlar (deterministik lock)
    final lock = (title.hashCode & 0x7fffffff) % 500;
    final url = 'https://loremflickr.com/640/360/${_slug(keyword)}?lock=$lock';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return _bannerFallback(loading: true);
          },
          errorBuilder: (c, e, s) => _bannerFallback(),
        ),
      ),
    );
  }

  Widget _bannerFallback({bool loading = false}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white70,
                ),
              )
            : const Icon(Icons.auto_stories, color: Colors.white70, size: 46),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Kronometre — aktivite süresine göre geri sayım (başlat / duraklat / sıfırla)
// ═══════════════════════════════════════════════════════════════════════════
class _ActivityTimer extends StatefulWidget {
  final String durationText;
  const _ActivityTimer({required this.durationText});

  @override
  State<_ActivityTimer> createState() => _ActivityTimerState();
}

class _ActivityTimerState extends State<_ActivityTimer> {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  int _parseMinutes(String s) {
    final m = RegExp(r'\d+').firstMatch(s);
    final v = m != null ? int.tryParse(m.group(0)!) ?? 15 : 15;
    return v.clamp(1, 180);
  }

  @override
  void initState() {
    super.initState();
    _totalSeconds = _parseMinutes(widget.durationText) * 60;
    _remaining = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏰ ${AppLocalizations.of(context).eduTimeUp} 🎉'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
    });
  }

  String get _fmt {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1EFFFFFF)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: const Color(0x22FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                ),
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).eduStopwatch,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, color: Color(0xFF9CA3AF)),
          ),
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _running ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Kullanıcı içerik ekleme formu — kendi aktiviteni oluştur
// ═══════════════════════════════════════════════════════════════════════════
class _AddActivitySheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddActivitySheet({required this.onSave});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '20 dk');
  final _materials = TextEditingController();
  final _steps = TextEditingController();
  int _minAge = 3;
  int _maxAge = 10;
  String _category = 'okul_oncesi';

  static const _cats = [
    ('okul_oncesi', 'Okul Öncesi'),
    ('ilkokul', 'İlkokul'),
    ('ortaokul', 'Ortaokul'),
    ('stem', 'STEM'),
    ('sanat_egitimi', 'Sanat'),
    ('spor', 'Spor'),
    ('muzik_egitimi', 'Müzik'),
    ('sosyal_beceriler', 'Sosyal'),
    ('yaraticilik', 'Yaratıcılık'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _materials.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).eduEnterTitle),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final mats = _materials.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(
          (e) => {
            'name': e,
            'purpose': 'Aktivite için gerekli',
            'alternative': '',
          },
        )
        .toList();
    final steps = _steps.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final activity = <String, dynamic>{
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'title': _title.text.trim(),
      'category': _category,
      'age_group': {'min': _minAge, 'max': _maxAge},
      'development_area': 'Aile',
      'learning_objectives': ['Aileye özel öğrenme'],
      'duration': _duration.text.trim(),
      'frequency': 'serbest',
      'materials': mats,
      'steps': steps,
      'parent_tips': const ['Kendi eklediğiniz içerik.'],
      'rating': 5.0,
      'review_count': 1,
      'is_custom': true,
    };
    widget.onSave(activity);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${AppLocalizations.of(context).eduActivityAdded}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    filled: true,
    fillColor: const Color(0xFF1A1A24),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0x1EFFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context).eduAddActivity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).eduCreateOwn,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context).baslik,
              style: const TextStyle(
                color: Color(0xFFC7CBD4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Örn: Legolarla Şekil Yapma'),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).eduCategory,
              style: const TextStyle(
                color: Color(0xFFC7CBD4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cats.map((c) {
                final sel = _category == c.$1;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      c.$2,
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).eduAgeRange,
                        style: const TextStyle(
                          color: Color(0xFFC7CBD4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _AgeStepper(
                            value: _minAge,
                            onChanged: (v) => setState(() => _minAge = v),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '—',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          ),
                          _AgeStepper(
                            value: _maxAge,
                            onChanged: (v) => setState(() => _maxAge = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).eduDuration,
                        style: const TextStyle(
                          color: Color(0xFFC7CBD4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _duration,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('20 dk'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).eduMaterials,
              style: const TextStyle(
                color: Color(0xFFC7CBD4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _materials,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Legolar\nRenkli kağıt\nMakas'),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).eduHowTo,
              style: const TextStyle(
                color: Color(0xFFC7CBD4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _steps,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Malzemeleri hazırlayın\nÇocuğa gösterin'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).save,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _AgeStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 16, color: Color(0xFF9CA3AF)),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 18 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI Ders Üretici — PedagogyEngine ile herhangi bir konuda çocuğa özel
// ders/görev kartı üretir (başlık, adımlar, puan, rozet, ebeveyn ipucu).
// ═══════════════════════════════════════════════════════════════════════════
class _AiLessonSheet extends StatefulWidget {
  const _AiLessonSheet();

  @override
  State<_AiLessonSheet> createState() => _AiLessonSheetState();
}

class _AiLessonSheetState extends State<_AiLessonSheet> {
  final _topicCtrl = TextEditingController();
  int _age = 5;
  String _difficulty = 'easy';
  Map<String, dynamic>? _card;
  bool _loading = false;
  bool _requested = false;

  static const _difficulties = [
    ('easy', 'Kolay'),
    ('medium', 'Orta'),
    ('hard', 'Zor'),
  ];

  String get _lang {
    final l = HiveService.getSetting('language') ?? 'Türkçe';
    switch (l) {
      case 'English':
        return 'en';
      case 'Français':
        return 'fr';
      case 'Nederlands':
        return 'nl';
      default:
        return 'tr';
    }
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).eduEnterTopic)),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _requested = true;
      _card = null;
    });
    final card = await PedagogyEngine.generateChildTask(
      childName: 'Çocuğunuz',
      age: _age,
      language: _lang,
      category: topic,
      interests: topic,
      difficulty: _difficulty,
    );
    if (!mounted) return;
    setState(() {
      _card = card;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).eduGenerateAI,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Bir konu yazın; yaşa uygun ders/görev kartını AI üretsin.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).eduTopicHint,
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF1A1A24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _generate(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).eduAge,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                _AgeStepper(
                  value: _age,
                  onChanged: (v) => setState(() => _age = v),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _difficulties.map((d) {
                final sel = _difficulty == d.$1;
                return ChoiceChip(
                  label: Text(d.$2),
                  selected: sel,
                  onSelected: (_) => setState(() => _difficulty = d.$1),
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: const Color(0xFF1A1A24),
                  selectedColor: const Color(0xFF6366F1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _loading ? 'Üretiliyor...' : 'Üret',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_requested && !_loading && _card == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context).eduGenFailed,
                  style: const TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            if (_card != null) _buildCard(_card!),
          ],
        ),
      ),
    );
  }

  // Adım hem düz string hem {step_number, description} nesnesi olabilir.
  String _stepText(dynamic e) {
    if (e is Map) {
      return (e['description'] ?? e['text'] ?? e['step'] ?? e.values.join(' '))
          .toString();
    }
    return e.toString();
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final steps = (c['steps'] as List?)?.map(_stepText).toList() ?? [];
    final points = c['points'];
    final badge = (c['badge'] ?? '').toString();
    final duration = (c['duration'] ?? '').toString();
    final parentTip = (c['parent_tip'] ?? '').toString();
    final question = (c['completion_question'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (c['title'] ?? 'Ders').toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((c['subtitle'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              c['subtitle'].toString(),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (duration.isNotEmpty) _pill(Icons.schedule, duration),
              if (points != null) _pill(Icons.stars, '$points puan'),
              if (badge.isNotEmpty) _pill(Icons.military_tech, badge),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).eduSteps,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            ...List.generate(
              steps.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (parentTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).eduParentTip(parentTip),
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (question.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '💬 $question',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData ic, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF13131A),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, size: 13, color: const Color(0xFF6366F1)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD1D5DB),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
