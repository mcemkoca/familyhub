import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// ── WHO Milestone Data ──

const _milestonesByAge = {
  '0-3 ay': [
    ('Motor', 'Baş kontrolü yapar', '🏋️'),
    ('Sosyal', 'Gülümser', '😊'),
    ('Dil', 'Ses çıkarır', '🔊'),
    ('Görme', 'Yüzleri takip eder', '👁️'),
  ],
  '3-6 ay': [
    ('Motor', 'Desteksiz oturur (başlangıç)', '🪑'),
    ('Motor', 'Nesneleri kavrar', '✋'),
    ('Sosyal', 'Yabancılara farklı tepki', '👶'),
    ('Dil', 'Cıvıldama başlar', '🗣️'),
  ],
  '6-9 ay': [
    ('Motor', 'Emeklemeye başlar', '🧸'),
    ('Motor', 'Destekle ayağa kalkar', '🦵'),
    ('Dil', '"Mama", "baba" heceleri', '💬'),
    ('Sosyal', 'Yabancı kaygısı', '😟'),
  ],
  '9-12 ay': [
    ('Motor', 'Bağımsız yürümeye başlar', '👣'),
    ('Dil', 'İlk anlamlı kelimeler', '🗣️'),
    ('Sosyal', 'Taklit oyunları', '🎭'),
    ('Bilişsel', 'Nesne kalıcılığı', '🎯'),
  ],
  '12-18 ay': [
    ('Motor', 'Merdiven çıkar (destekle)', '🪜'),
    ('Dil', '10-20 kelime', '💬'),
    ('Sosyal', 'Sembolik oyun', '🎮'),
    ('Özbakım', 'Kaşıkla yemeye çalışır', '🥄'),
  ],
  '18-24 ay': [
    ('Dil', '2 kelimelik cümleler', '💬'),
    ('Motor', 'Koşar, toplar', '⚽'),
    ('Bilişsel', 'Renkleri tanır', '🌈'),
    ('Sosyal', 'Paralel oyun', '🧒'),
  ],
  '2-3 yaş': [
    ('Dil', '200-300 kelime, cümleler', '📚'),
    ('Motor', 'Üçteker bisiklet sürer', '🚲'),
    ('Sosyal', 'Sıra beklemeye başlar', '⏳'),
    ('Bilişsel', 'Sayı kavramı (1-3)', '🔢'),
  ],
  '3-4 yaş': [
    ('Dil', 'Sorular sorar (neden, nasıl)', '❓'),
    ('Motor', 'Makas kullanır', '✂️'),
    ('Sosyal', 'Grup oyunları', '👫'),
    ('Bilişsel', 'Renk ve şekil sınıflaması', '🔷'),
  ],
  '4-5 yaş': [
    ('Dil', 'Hikaye anlatır', '📖'),
    ('Motor', 'Tek ayak üzerinde durur', '🦩'),
    ('Bilişsel', 'Harf ve rakam tanıma', '🔤'),
    ('Sosyal', 'Kuralları anlıyor', '📋'),
  ],
  '5-6 yaş': [
    ('Dil', 'Net konuşma, dilbilgisi', '🗣️'),
    ('Motor', 'İnce motor becerileri', '✏️'),
    ('Bilişsel', 'Okuma hazırlığı', '📚'),
    ('Sosyal', 'Empati gelişimi', '💛'),
  ],
  '6-8 yaş': [
    ('Akademik', 'Okuma ve yazmayı öğrenir', '📝'),
    ('Akademik', 'Temel matematik', '➕'),
    ('Sosyal', 'Arkadaşlık ilişkileri güçlenir', '🤝'),
    ('Duygusal', 'Kural ve değerleri kavrar', '⚖️'),
  ],
  '8-10 yaş': [
    ('Akademik', 'Çarpma-bölme, karmaşık okuma', '🔢'),
    ('Motor', 'Spor koordinasyonu', '🏃'),
    ('Sosyal', 'Grup kimliği gelişir', '👥'),
    ('Duygusal', 'Sorumluluk bilinci', '🎯'),
  ],
  '10-12 yaş': [
    ('Akademik', 'Soyut düşünce başlangıcı', '🧠'),
    ('Sosyal', 'Akran etkisi artar', '👦👧'),
    ('Duygusal', 'Kimlik arayışı başlar', '🪞'),
    ('Dijital', 'Dijital okuryazarlık', '💻'),
  ],
};

// ── Hive Storage ──

class _ChildDevHive {
  static const _box = 'child_development';
  static const _childrenKey = 'children';

  static Future<Box> get box async => Hive.isBoxOpen(_box)
      ? Hive.box(_box)
      : await Hive.openBox(_box);

  static Future<void> save(String key, dynamic v) async {
    final b = await box;
    await b.put(key, jsonEncode(v));
  }

  static Future<dynamic> load(String key) async {
    final b = await box;
    final raw = b.get(key);
    return raw == null ? null : jsonDecode(raw as String);
  }
}

// ── Models ──

class ChildProfile {
  final String id;
  final String name;
  final String emoji;
  final DateTime birthDate;
  final String? schoolName;
  final String? grade;
  final List<String> completedMilestones;
  final List<SchoolSubject> subjects;
  final List<HomeworkEntry> homework;
  final List<GrowthEntry> growthLog;

  ChildProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.birthDate,
    this.schoolName,
    this.grade,
    this.completedMilestones = const [],
    this.subjects = const [],
    this.homework = const [],
    this.growthLog = const [],
  });

  int get ageMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 +
        (now.month - birthDate.month);
  }

  String get ageLabel {
    final months = ageMonths;
    if (months < 24) return '$months ay';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem == 0 ? '$years yaş' : '$years yaş $rem ay';
  }

  String get devGroup {
    final months = ageMonths;
    if (months < 3) return '0-3 ay';
    if (months < 6) return '3-6 ay';
    if (months < 9) return '6-9 ay';
    if (months < 12) return '9-12 ay';
    if (months < 18) return '12-18 ay';
    if (months < 24) return '18-24 ay';
    if (months < 36) return '2-3 yaş';
    if (months < 48) return '3-4 yaş';
    if (months < 60) return '4-5 yaş';
    if (months < 72) return '5-6 yaş';
    if (months < 96) return '6-8 yaş';
    if (months < 120) return '8-10 yaş';
    return '10-12 yaş';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthDate': birthDate.toIso8601String(),
        'schoolName': schoolName,
        'grade': grade,
        'completedMilestones': completedMilestones,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'homework': homework.map((h) => h.toJson()).toList(),
        'growthLog': growthLog.map((g) => g.toJson()).toList(),
      };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '👶',
        birthDate: DateTime.parse(j['birthDate'] as String),
        schoolName: j['schoolName'] as String?,
        grade: j['grade'] as String?,
        completedMilestones:
            List<String>.from(j['completedMilestones'] as List? ?? []),
        subjects: (j['subjects'] as List? ?? [])
            .map((e) => SchoolSubject.fromJson(e as Map<String, dynamic>))
            .toList(),
        homework: (j['homework'] as List? ?? [])
            .map((e) => HomeworkEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        growthLog: (j['growthLog'] as List? ?? [])
            .map((e) => GrowthEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ChildProfile copyWith({
    List<String>? completedMilestones,
    List<SchoolSubject>? subjects,
    List<HomeworkEntry>? homework,
    List<GrowthEntry>? growthLog,
    String? schoolName,
    String? grade,
  }) =>
      ChildProfile(
        id: id,
        name: name,
        emoji: emoji,
        birthDate: birthDate,
        schoolName: schoolName ?? this.schoolName,
        grade: grade ?? this.grade,
        completedMilestones:
            completedMilestones ?? this.completedMilestones,
        subjects: subjects ?? this.subjects,
        homework: homework ?? this.homework,
        growthLog: growthLog ?? this.growthLog,
      );
}

class SchoolSubject {
  final String id;
  final String name;
  final String emoji;
  final List<int> grades;
  final String notes;

  SchoolSubject({
    required this.id,
    required this.name,
    required this.emoji,
    this.grades = const [],
    this.notes = '',
  });

  double get average =>
      grades.isEmpty ? 0 : grades.reduce((a, b) => a + b) / grades.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'grades': grades,
        'notes': notes,
      };

  factory SchoolSubject.fromJson(Map<String, dynamic> j) => SchoolSubject(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '📚',
        grades: List<int>.from(j['grades'] as List? ?? []),
        notes: j['notes'] as String? ?? '',
      );
}

class HomeworkEntry {
  final String id;
  final String subject;
  final String description;
  final String dueDate;
  bool completed;

  HomeworkEntry({
    required this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'description': description,
        'dueDate': dueDate,
        'completed': completed,
      };

  factory HomeworkEntry.fromJson(Map<String, dynamic> j) => HomeworkEntry(
        id: j['id'] as String,
        subject: j['subject'] as String,
        description: j['description'] as String,
        dueDate: j['dueDate'] as String,
        completed: j['completed'] as bool? ?? false,
      );
}

class GrowthEntry {
  final String date;
  final double? height;
  final double? weight;

  const GrowthEntry({required this.date, this.height, this.weight});

  Map<String, dynamic> toJson() =>
      {'date': date, 'height': height, 'weight': weight};

  factory GrowthEntry.fromJson(Map<String, dynamic> j) => GrowthEntry(
        date: j['date'] as String,
        height: (j['height'] as num?)?.toDouble(),
        weight: (j['weight'] as num?)?.toDouble(),
      );
}

// ── Provider ──

final childDevProvider =
    StateNotifierProvider<ChildDevNotifier, List<ChildProfile>>(
  (ref) => ChildDevNotifier(),
);

class ChildDevNotifier extends StateNotifier<List<ChildProfile>> {
  ChildDevNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final data = await _ChildDevHive.load(_ChildDevHive._childrenKey);
    if (data != null) {
      state = (data as List)
          .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    await _ChildDevHive.save(
        _ChildDevHive._childrenKey,
        state.map((c) => c.toJson()).toList());
  }

  Future<void> addChild(ChildProfile child) async {
    state = [...state, child];
    await _persist();
  }

  Future<void> toggleMilestone(String childId, String milestoneKey) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      final completed = List<String>.from(c.completedMilestones);
      if (completed.contains(milestoneKey)) {
        completed.remove(milestoneKey);
      } else {
        completed.add(milestoneKey);
      }
      return c.copyWith(completedMilestones: completed);
    }).toList();
    await _persist();
  }

  Future<void> addHomework(String childId, HomeworkEntry hw) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      return c.copyWith(homework: [...c.homework, hw]);
    }).toList();
    await _persist();
  }

  Future<void> toggleHomework(String childId, String hwId) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      return c.copyWith(
        homework: c.homework.map((h) {
          if (h.id != hwId) return h;
          return HomeworkEntry(
            id: h.id,
            subject: h.subject,
            description: h.description,
            dueDate: h.dueDate,
            completed: !h.completed,
          );
        }).toList(),
      );
    }).toList();
    await _persist();
  }

  Future<void> addGrowthEntry(String childId, GrowthEntry entry) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      return c.copyWith(growthLog: [...c.growthLog, entry]);
    }).toList();
    await _persist();
  }

  Future<void> addSubject(String childId, SchoolSubject subject) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      return c.copyWith(subjects: [...c.subjects, subject]);
    }).toList();
    await _persist();
  }

  Future<void> addGrade(
      String childId, String subjectId, int grade) async {
    state = state.map((c) {
      if (c.id != childId) return c;
      return c.copyWith(
        subjects: c.subjects.map((s) {
          if (s.id != subjectId) return s;
          return SchoolSubject(
            id: s.id,
            name: s.name,
            emoji: s.emoji,
            grades: [...s.grades, grade],
            notes: s.notes,
          );
        }).toList(),
      );
    }).toList();
    await _persist();
  }
}

// ── Screen ──

class ChildDevelopmentScreen extends ConsumerStatefulWidget {
  const ChildDevelopmentScreen({super.key});

  @override
  ConsumerState<ChildDevelopmentScreen> createState() =>
      _ChildDevelopmentScreenState();
}

class _ChildDevelopmentScreenState
    extends ConsumerState<ChildDevelopmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedChild = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childDevProvider);
    final child = children.isEmpty
        ? null
        : children[_selectedChild.clamp(0, children.length - 1)];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      const Text('🌱 Çocuk Gelişimi & Okul',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const Text('Büyüme takibi · Dersler · Ödevler',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      // Child selector
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: children.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            if (i == children.length) {
                              return GestureDetector(
                                onTap: _showAddChildSheet,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withAlpha(80),
                                        width: 1.5),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 20),
                                ),
                              );
                            }
                            final c = children[i];
                            final sel = _selectedChild == i;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedChild = i),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? Colors.white
                                          : Colors.white.withAlpha(30),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white
                                              .withAlpha(sel ? 255 : 80),
                                          width: 2),
                                    ),
                                    child: Center(
                                        child: Text(c.emoji,
                                            style: const TextStyle(
                                                fontSize: 22))),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.ageLabel,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withAlpha(sel ? 255 : 160),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: '🌱 Gelişim'),
                Tab(text: '📚 Dersler'),
                Tab(text: '📝 Ödevler'),
                Tab(text: '📏 Büyüme'),
              ],
            ),
          ),

          if (child == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👶', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('Çocuk profili ekleyin',
                        style: TextStyle(color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showAddChildSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('+ Çocuk Ekle',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: TabBarView(
                controller: _tab,
                children: [
                  _MilestoneTab(child: child),
                  _SchoolTab(child: child),
                  _HomeworkTab(child: child),
                  _GrowthTab(child: child),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: child == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addItem(child),
              backgroundColor: const Color(0xFFFF6B6B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(_fabLabel(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }

  String _fabLabel() {
    switch (_tab.index) {
      case 1: return 'Ders Ekle';
      case 2: return 'Ödev Ekle';
      case 3: return 'Ölçüm Ekle';
      default: return 'Güncelle';
    }
  }

  void _addItem(ChildProfile child) {
    switch (_tab.index) {
      case 1: _showAddSubjectSheet(child); break;
      case 2: _showAddHomeworkSheet(child); break;
      case 3: _showAddGrowthSheet(child); break;
    }
  }

  void _showAddChildSheet() {
    final nameCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    String emoji = '👧';
    DateTime birthDate =
        DateTime.now().subtract(const Duration(days: 365 * 5));
    final emojis = ['👧', '👦', '🧒', '👶'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => _DevSheet(
          title: '👶 Çocuk Profili Oluştur',
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                children: emojis.map((e) {
                  final sel = emoji == e;
                  return GestureDetector(
                    onTap: () => setSt(() => emoji = e),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFFF6B6B).withAlpha(25)
                            : Colors.grey.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel
                              ? const Color(0xFFFF6B6B)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child:
                              Text(e, style: const TextStyle(fontSize: 26))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _DevField(controller: nameCtrl, label: 'Çocuğun adı'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: birthDate,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365 * 14)),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setSt(() => birthDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFFFF6B6B), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake,
                          color: Color(0xFFFF6B6B), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Doğum tarihi: ${DateFormat('dd MMMM yyyy', 'tr').format(birthDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _DevField(
                  controller: schoolCtrl,
                  label: 'Okul adı (isteğe bağlı)'),
              const SizedBox(height: 16),
              _DevBtn(
                label: 'Profil Oluştur',
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ref.read(childDevProvider.notifier).addChild(
                        ChildProfile(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          emoji: emoji,
                          birthDate: birthDate,
                          schoolName: schoolCtrl.text.trim().isEmpty
                              ? null
                              : schoolCtrl.text.trim(),
                        ),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectSheet(ChildProfile child) {
    final nameCtrl = TextEditingController();
    String emoji = '📚';
    const subjectEmojis = [
      ('Türkçe', '📖'), ('Matematik', '➕'), ('Fen', '🔬'),
      ('Sosyal', '🌍'), ('İngilizce', '🇬🇧'), ('Müzik', '🎵'),
      ('Beden', '⚽'), ('Resim', '🎨'), ('Din', '📿'), ('Diğer', '📚'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => _DevSheet(
          title: '📚 Ders Ekle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ders seç veya kendin yaz:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: subjectEmojis.map((pair) {
                  final (name, em) = pair;
                  return GestureDetector(
                    onTap: () {
                      setSt(() {
                        emoji = em;
                        nameCtrl.text = name;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: nameCtrl.text == name
                            ? const Color(0xFFFF6B6B).withAlpha(20)
                            : Colors.grey.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: nameCtrl.text == name
                              ? const Color(0xFFFF6B6B)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text('$em $name',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _DevField(controller: nameCtrl, label: 'Ders adı'),
              const SizedBox(height: 14),
              _DevBtn(
                label: 'Ders Ekle',
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ref.read(childDevProvider.notifier).addSubject(
                        child.id,
                        SchoolSubject(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          emoji: emoji,
                        ),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHomeworkSheet(ChildProfile child) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => _DevSheet(
          title: '📝 Ödev Ekle — ${child.name}',
          child: Column(
            children: [
              _DevField(
                  controller: subjectCtrl, label: 'Ders adı'),
              const SizedBox(height: 10),
              _DevField(
                controller: descCtrl,
                label: 'Ödev açıklaması',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
                  );
                  if (d != null) setSt(() => dueDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFFFF6B6B), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event,
                          color: Color(0xFFFF6B6B), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Teslim: ${DateFormat('dd MMMM', 'tr').format(dueDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DevBtn(
                label: 'Ödevi Kaydet',
                onTap: () {
                  if (subjectCtrl.text.trim().isEmpty) return;
                  ref.read(childDevProvider.notifier).addHomework(
                        child.id,
                        HomeworkEntry(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          subject: subjectCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          dueDate:
                              DateFormat('dd.MM.yyyy').format(dueDate),
                        ),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGrowthSheet(ChildProfile child) {
    final heightCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DevSheet(
        title: '📏 Büyüme Ölçümü — ${child.name}',
        child: Column(
          children: [
            _DevField(
              controller: heightCtrl,
              label: 'Boy (cm)',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _DevField(
              controller: weightCtrl,
              label: 'Kilo (kg)',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _DevBtn(
              label: 'Kaydet',
              onTap: () {
                final h = double.tryParse(heightCtrl.text);
                final w = double.tryParse(weightCtrl.text);
                if (h == null && w == null) return;
                ref.read(childDevProvider.notifier).addGrowthEntry(
                      child.id,
                      GrowthEntry(
                        date: DateFormat('dd.MM.yyyy')
                            .format(DateTime.now()),
                        height: h,
                        weight: w,
                      ),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Views ──

class _MilestoneTab extends ConsumerWidget {
  final ChildProfile child;
  const _MilestoneTab({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(childDevProvider)
        .firstWhere((c) => c.id == child.id, orElse: () => child);

    final group = fresh.devGroup;
    final milestones = _milestonesByAge[group] ?? [];

    final completed =
        milestones.where((m) => fresh.completedMilestones.contains('$group-${m.$2}')).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Age + group card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(fresh.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fresh.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                    Text(fresh.ageLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text('Gelişim grubu: $group',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('$completed/${milestones.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22)),
                  const Text('tamamlandı',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: milestones.isEmpty
                ? 0
                : completed / milestones.length,
            backgroundColor: Colors.grey.withAlpha(30),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),

        // Current group milestones
        Text('$group Gelişim Basamakları',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        ...milestones.map((m) {
          final key = '$group-${m.$2}';
          final done = fresh.completedMilestones.contains(key);
          return GestureDetector(
            onTap: () => ref
                .read(childDevProvider.notifier)
                .toggleMilestone(fresh.id, key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFFFF6B6B).withAlpha(12)
                    : Colors.grey.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done
                      ? const Color(0xFFFF6B6B).withAlpha(50)
                      : Colors.grey.withAlpha(30),
                ),
              ),
              child: Row(
                children: [
                  Text(m.$3, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$2,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.black87)),
                        Text(m.$1,
                            style: TextStyle(
                                fontSize: 11,
                                color: done
                                    ? const Color(0xFFFF6B6B)
                                        .withAlpha(160)
                                    : const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFFF6B6B)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? const Color(0xFFFF6B6B)
                            : Colors.grey.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SchoolTab extends ConsumerWidget {
  final ChildProfile child;
  const _SchoolTab({required this.child});

  Color _gradeColor(double avg) {
    if (avg >= 85) return Colors.green;
    if (avg >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(childDevProvider)
        .firstWhere((c) => c.id == child.id, orElse: () => child);

    if (fresh.subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Henüz ders eklenmedi\n+ ile ekleyin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fresh.schoolName != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF6B6B).withAlpha(40)),
            ),
            child: Row(
              children: [
                const Text('🏫', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(fresh.schoolName!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...fresh.subjects.map((s) {
          final avg = s.average;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withAlpha(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                      if (s.grades.isEmpty)
                        const Text('Not girilmedi',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF)))
                      else
                        Text(
                          s.grades.map((g) => g.toString()).join(' · '),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
                if (s.grades.isNotEmpty) ...[
                  Column(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: _gradeColor(avg),
                        ),
                      ),
                      Text('ort.',
                          style: TextStyle(
                              fontSize: 9,
                              color: _gradeColor(avg))),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // Add grade button
                GestureDetector(
                  onTap: () => _addGrade(context, ref, fresh.id, s),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add,
                        color: Color(0xFFFF6B6B), size: 18),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addGrade(
      BuildContext context, WidgetRef ref, String childId, SchoolSubject s) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${s.emoji} ${s.name} — Not Ekle'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Not (0-100)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final grade = int.tryParse(ctrl.text);
              if (grade != null && grade >= 0 && grade <= 100) {
                ref
                    .read(childDevProvider.notifier)
                    .addGrade(childId, s.id, grade);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Kaydet',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HomeworkTab extends ConsumerWidget {
  final ChildProfile child;
  const _HomeworkTab({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(childDevProvider)
        .firstWhere((c) => c.id == child.id, orElse: () => child);

    final pending =
        fresh.homework.where((h) => !h.completed).toList();
    final done = fresh.homework.where((h) => h.completed).toList();

    if (fresh.homework.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📝', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Ödev yok — harika! 🎉',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _Label('Bekleyen Ödevler (${pending.length})'),
          ...pending.map((h) => _HwTile(
                hw: h,
                childId: fresh.id,
                ref: ref,
              )),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Label('Tamamlanan (${done.length})'),
          ...done.map((h) => _HwTile(
                hw: h,
                childId: fresh.id,
                ref: ref,
              )),
        ],
      ],
    );
  }
}

class _HwTile extends StatelessWidget {
  final HomeworkEntry hw;
  final String childId;
  final WidgetRef ref;
  const _HwTile(
      {required this.hw, required this.childId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          ref.read(childDevProvider.notifier).toggleHomework(childId, hw.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hw.completed
              ? Colors.green.withAlpha(8)
              : Colors.orange.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hw.completed
                ? Colors.green.withAlpha(40)
                : Colors.orange.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: hw.completed ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hw.completed
                      ? Colors.green
                      : Colors.grey.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: hw.completed
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hw.subject,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              hw.completed ? Colors.grey : Colors.black87)),
                  if (hw.description.isNotEmpty)
                    Text(hw.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Text('📅 ${hw.dueDate}',
                style: TextStyle(
                    fontSize: 10,
                    color: hw.completed
                        ? Colors.grey
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _GrowthTab extends ConsumerWidget {
  final ChildProfile child;
  const _GrowthTab({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(childDevProvider)
        .firstWhere((c) => c.id == child.id, orElse: () => child);

    final log = fresh.growthLog.reversed.toList();

    if (log.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📏', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Henüz ölçüm girilmedi\n+ ile ekleyin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    final lastHeight =
        log.firstWhere((g) => g.height != null, orElse: () => GrowthEntry(date: '')).height;
    final lastWeight =
        log.firstWhere((g) => g.weight != null, orElse: () => GrowthEntry(date: '')).weight;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Last measurement summary
        Row(
          children: [
            Expanded(
              child: _GrowthCard(
                emoji: '📏',
                label: 'Boy',
                value: lastHeight != null
                    ? '${lastHeight.toStringAsFixed(1)} cm'
                    : '—',
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GrowthCard(
                emoji: '⚖️',
                label: 'Kilo',
                value: lastWeight != null
                    ? '${lastWeight.toStringAsFixed(1)} kg'
                    : '—',
                color: const Color(0xFFFFD93D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Label('Ölçüm Geçmişi'),
        ...log.map((g) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(30)),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(g.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (g.height != null)
                    Text('📏 ${g.height!.toStringAsFixed(1)} cm',
                        style: const TextStyle(fontSize: 12)),
                  if (g.height != null && g.weight != null)
                    const SizedBox(width: 12),
                  if (g.weight != null)
                    Text('⚖️ ${g.weight!.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _GrowthCard(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ── Shared Dev Widgets ──

class _DevSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _DevSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DevField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType keyboard;
  const _DevField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFFFF6B6B), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DevBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DevBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280))),
    );
  }
}
