import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen>
    with SingleTickerProviderStateMixin {
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
      final raw =
          await rootBundle.loadString('assets/data/content/education.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      setState(() {
        _activities = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
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
                        _ActivitiesTab(
                            activities: _activities, isDark: isDark),
                        _ParentGuideTab(
                            activities: _activities, isDark: isDark),
                        _ProgressTab(
                            activities: _activities, isDark: isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eğitim',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark)),
                Text('${_activities.length} aktivite • ebeveyn rehberi • takip',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF8B5CF6),
      unselectedLabelColor: AppColors.slate,
      indicatorColor: const Color(0xFF8B5CF6),
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(icon: Icon(Icons.apps, size: 18), text: 'Aktiviteler'),
        Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Rehber'),
        Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'İlerleme'),
      ],
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
    ('stem', 'STEM', Icons.science),
    ('sanat_egitimi', 'Sanat', Icons.palette),
    ('spor', 'Spor', Icons.sports_soccer),
    ('muzik_egitimi', 'Müzik', Icons.music_note),
    ('yaraticilik', 'Yaratıcılık', Icons.lightbulb),
    ('sosyal_beceriler', 'Sosyal', Icons.people),
  ];

  List<Map<String, dynamic>> get _filtered {
    return widget.activities.where((a) {
      final cat = (a['category'] as String?)?.toLowerCase() ?? '';
      final matchCat =
          _selectedCategory == 'tümü' || cat == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          (a['title'] as String?)
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true;
      final matchAge = _ageFilter == null ||
          ((a['age_group']?['min'] as int? ?? 0) <= _ageFilter! &&
              (a['age_group']?['max'] as int? ?? 18) >= _ageFilter!);
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
                  style: TextStyle(
                      color: widget.isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark),
                  decoration: InputDecoration(
                    hintText: 'Aktivite ara...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor:
                        widget.isDark ? AppColors.darkCard : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF8B5CF6)
                        : (widget.isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: active
                            ? const Color(0xFF8B5CF6)
                            : (widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.border)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 12,
                          color: active
                              ? Colors.white
                              : (widget.isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.slate)),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : (widget.isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.slate))),
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
              Text('${filtered.length} aktivite bulundu',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: AppColors.slate),
                      SizedBox(height: 12),
                      Text('Aktivite bulunamadı'),
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
  const _AgeFilterButton(
      {required this.age, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Yaşa Göre Filtrele'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                onChanged(null);
                Navigator.pop(context);
              },
              child: const Text('Tümü'),
            ),
            ...[3, 5, 7, 9, 11, 13, 15, 17].map((a) => SimpleDialogOption(
                  onPressed: () {
                    onChanged(a);
                    Navigator.pop(context);
                  },
                  child: Text('$a yaş'),
                )),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: age != null
              ? const Color(0xFF8B5CF6)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: age != null
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? AppColors.darkBorder : AppColors.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person,
                size: 16,
                color: age != null ? Colors.white : AppColors.slate),
            const SizedBox(width: 4),
            Text(age != null ? '$age yaş' : 'Yaş',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: age != null ? Colors.white : AppColors.slate)),
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
  const _ParentGuideTab(
      {required this.activities, required this.isDark});

  static const _guides = [
    (Icons.psychology, '🧠', 'Bilişsel Gelişim', Color(0xFF8B5CF6),
        'Çocuğun düşünme ve problem çözme becerilerini nasıl desteklersiniz?'),
    (Icons.favorite, '❤️', 'Duygusal Zeka', Color(0xFFEC4899),
        'Empati, öz-düzenleme ve sosyal becerileri geliştirme yolları.'),
    (Icons.science, '🔬', 'STEM Eğitimi', Color(0xFF06B6D4),
        'Günlük hayatta fen, teknoloji, mühendislik ve matematik.'),
    (Icons.palette, '🎨', 'Sanat & Yaratıcılık', Color(0xFFF97316),
        'Yaratıcı ifadeyi teşvik etmenin pratik yolları.'),
    (Icons.music_note, '🎵', 'Müzik Eğitimi', Color(0xFF10B981),
        'Ritim, melodi ve müzikle çocuk gelişimi.'),
    (Icons.sports, '⚽', 'Fiziksel Gelişim', Color(0xFFF59E0B),
        'Hareket, spor ve motor beceri gelişimi.'),
    (Icons.book, '📖', 'Okuma Alışkanlığı', Color(0xFF3B82F6),
        'Kitap sevgisini erken yaşta aşılamanın yolları.'),
    (Icons.language, '🌍', 'Dil Öğrenimi', Color(0xFF6366F1),
        'İkinci dil öğrenimini eğlenceli hale getirme.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final (icon, _, title, color, desc) = _guides[i];
        final related = activities
            .where((a) =>
                (a['title'] as String?)
                    ?.toLowerCase()
                    .contains(title.split(' ').first.toLowerCase()) ==
                true)
            .take(3)
            .toList();

        return GestureDetector(
          onTap: () => _showGuideDetail(context, title, desc, color, related),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 20 : 6),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
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
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark)),
                      const SizedBox(height: 4),
                      Text(desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate,
                              height: 1.3)),
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

  void _showGuideDetail(BuildContext context, String title, String desc,
      Color color, List<Map<String, dynamic>> related) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
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
                    Text(title,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(height: 8),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.dark)),
                  ],
                ),
              ),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('İlgili Aktiviteler',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark)),
                const SizedBox(height: 10),
                ...related.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(a['title'] ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.dark)),
                      ),
                    )),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Overall progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Genel İlerleme',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$done / $total aktivite tamamlandı',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Text(
                      '${total > 0 ? (done * 100 ~/ total) : 0}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  backgroundColor: Colors.white.withAlpha(40),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
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
          final areaDone =
              areaActs.where((a) => _completed.contains(a['id'])).length;
          final areaTotal = areaActs.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withAlpha(widget.isDark ? 20 : 6),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
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
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.dark)),
                      const Spacer(),
                      Text('$areaDone / $areaTotal',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.slate)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          areaTotal > 0 ? areaDone / areaTotal : 0,
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
                                duration:
                                    const Duration(milliseconds: 160),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                    color: done ? color : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: done
                                            ? color
                                            : AppColors.border,
                                        width: 2)),
                                child: done
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(a['title'] ?? '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: done
                                            ? AppColors.slate
                                            : (widget.isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.dark))),
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
  const _ActivityCard(
      {required this.activity, required this.isDark, required this.onTap});

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
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 6),
                blurRadius: 8,
                offset: const Offset(0, 2))
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
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity['title'] ?? '',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.dark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: [
                      _Chip(label: '$ageMin-$ageMax yaş',
                          color: const Color(0xFF8B5CF6)),
                      if (activity['duration'] != null)
                        _Chip(label: activity['duration'],
                            color: AppColors.cobalt),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate)),
                      const SizedBox(width: 6),
                      Text('${activity['review_count'] ?? 0} değerlendirme',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.slate)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate, size: 20),
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
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
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
    final materials = (activity['materials'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final ageGroup = activity['age_group'] as Map<String, dynamic>? ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text(activity['title'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _DetailChip(
                          '${ageGroup['min']}-${ageGroup['max']} yaş'),
                      if (activity['duration'] != null)
                        _DetailChip(activity['duration']),
                      if (activity['frequency'] != null)
                        _DetailChip(activity['frequency']),
                    ],
                  ),
                ],
              ),
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
              ...steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF6366F1)
                            ]),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.dark)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
            ],
            if (tips.isNotEmpty) ...[
              _SectionTitle('Ebeveyn İpuçları', Icons.lightbulb, isDark),
              const SizedBox(height: 8),
              ...tips.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withAlpha(60))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(t,
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.dark))),
                        ],
                      ),
                    ),
                  )),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
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
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.dark)),
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
                  color: Color(0xFF8B5CF6), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.dark))),
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
            const Icon(Icons.check_circle_outline,
                size: 14, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${material['name']} — ${material['purpose']}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.dark)),
            ),
          ],
        ),
      );
}
