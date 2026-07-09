import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import '../../../services/notification_service.dart';

// ── Hive models (lightweight, no codegen needed — stored as JSON strings) ──

class FamilyHealthHive {
  static const _boxName = 'family_health';

  static Future<Box<dynamic>> get box async =>
      Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);

  static Future<void> save(String key, dynamic value) async {
    final b = await box;
    await b.put(key, jsonEncode(value));
  }

  static Future<dynamic> load(String key) async {
    final b = await box;
    final raw = b.get(key);
    if (raw == null) return null;
    return jsonDecode(raw as String);
  }
}

// ── Data Models ──

class FamilyMemberHealth {
  final String id;
  final String name;
  final String emoji;
  final String bloodType;
  final List<String> allergies;
  final List<Medicine> medicines;
  final List<Vitamin> vitamins;
  final List<DoctorReport> reports;
  final List<DoctorAppointment> appointments;

  FamilyMemberHealth({
    required this.id,
    required this.name,
    required this.emoji,
    this.bloodType = '',
    this.allergies = const [],
    this.medicines = const [],
    this.vitamins = const [],
    this.reports = const [],
    this.appointments = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'bloodType': bloodType,
        'allergies': allergies,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'vitamins': vitamins.map((v) => v.toJson()).toList(),
        'reports': reports.map((r) => r.toJson()).toList(),
        'appointments': appointments.map((a) => a.toJson()).toList(),
      };

  factory FamilyMemberHealth.fromJson(Map<String, dynamic> j) =>
      FamilyMemberHealth(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        bloodType: j['bloodType'] as String? ?? '',
        allergies: List<String>.from(j['allergies'] as List? ?? []),
        medicines: (j['medicines'] as List? ?? [])
            .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
            .toList(),
        vitamins: (j['vitamins'] as List? ?? [])
            .map((e) => Vitamin.fromJson(e as Map<String, dynamic>))
            .toList(),
        reports: (j['reports'] as List? ?? [])
            .map((e) => DoctorReport.fromJson(e as Map<String, dynamic>))
            .toList(),
        appointments: (j['appointments'] as List? ?? [])
            .map((e) => DoctorAppointment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  FamilyMemberHealth copyWith({
    List<Medicine>? medicines,
    List<Vitamin>? vitamins,
    List<DoctorReport>? reports,
    List<DoctorAppointment>? appointments,
    String? bloodType,
    List<String>? allergies,
  }) =>
      FamilyMemberHealth(
        id: id,
        name: name,
        emoji: emoji,
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
        medicines: medicines ?? this.medicines,
        vitamins: vitamins ?? this.vitamins,
        reports: reports ?? this.reports,
        appointments: appointments ?? this.appointments,
      );
}

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String startDate;
  final String? endDate;
  final String notes;
  final bool active;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'startDate': startDate,
        'endDate': endDate,
        'notes': notes,
        'active': active,
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] as String,
        name: j['name'] as String,
        dosage: j['dosage'] as String,
        frequency: j['frequency'] as String,
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String?,
        notes: j['notes'] as String? ?? '',
        active: j['active'] as bool? ?? true,
      );

  Medicine copyWith({bool? active}) => Medicine(
        id: id,
        name: name,
        dosage: dosage,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        active: active ?? this.active,
      );
}

class Vitamin {
  final String id;
  final String name;
  final String amount;
  final String timing;
  final bool active;

  Vitamin({
    required this.id,
    required this.name,
    required this.amount,
    required this.timing,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'timing': timing,
        'active': active,
      };

  factory Vitamin.fromJson(Map<String, dynamic> j) => Vitamin(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: j['amount'] as String,
        timing: j['timing'] as String,
        active: j['active'] as bool? ?? true,
      );
}

class DoctorReport {
  final String id;
  final String title;
  final String doctor;
  final String date;
  final String notes;
  final String reportType;

  DoctorReport({
    required this.id,
    required this.title,
    required this.doctor,
    required this.date,
    this.notes = '',
    this.reportType = 'Muayene',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doctor': doctor,
        'date': date,
        'notes': notes,
        'reportType': reportType,
      };

  factory DoctorReport.fromJson(Map<String, dynamic> j) => DoctorReport(
        id: j['id'] as String,
        title: j['title'] as String,
        doctor: j['doctor'] as String,
        date: j['date'] as String,
        notes: j['notes'] as String? ?? '',
        reportType: j['reportType'] as String? ?? 'Muayene',
      );
}

class DoctorAppointment {
  final String id;
  final String doctorName;
  final String specialty;
  final String dateTime;
  final String location;
  final bool completed;

  DoctorAppointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    this.location = '',
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'specialty': specialty,
        'dateTime': dateTime,
        'location': location,
        'completed': completed,
      };

  factory DoctorAppointment.fromJson(Map<String, dynamic> j) =>
      DoctorAppointment(
        id: j['id'] as String,
        doctorName: j['doctorName'] as String,
        specialty: j['specialty'] as String,
        dateTime: j['dateTime'] as String,
        location: j['location'] as String? ?? '',
        completed: j['completed'] as bool? ?? false,
      );

  DoctorAppointment copyWith({bool? completed}) => DoctorAppointment(
        id: id,
        doctorName: doctorName,
        specialty: specialty,
        dateTime: dateTime,
        location: location,
        completed: completed ?? this.completed,
      );
}

// ── Providers ──

final familyHealthProvider =
    StateNotifierProvider<FamilyHealthNotifier, List<FamilyMemberHealth>>(
  (ref) => FamilyHealthNotifier(),
);

class FamilyHealthNotifier extends StateNotifier<List<FamilyMemberHealth>> {
  FamilyHealthNotifier() : super([]) {
    _load();
  }

  static const _key = 'members';

  Future<void> _load() async {
    final data = await FamilyHealthHive.load(_key);
    if (data != null) {
      state = (data as List)
          .map((e) => FamilyMemberHealth.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Default family members
      state = [
        FamilyMemberHealth(id: 'anne', name: 'Anne', emoji: '👩'),
        FamilyMemberHealth(id: 'baba', name: 'Baba', emoji: '👨'),
      ];
    }
  }

  Future<void> _persist() async {
    await FamilyHealthHive.save(_key, state.map((m) => m.toJson()).toList());
  }

  Future<void> addMember(FamilyMemberHealth member) async {
    state = [...state, member];
    await _persist();
  }

  Future<void> updateMember(FamilyMemberHealth updated) async {
    state = state.map((m) => m.id == updated.id ? updated : m).toList();
    await _persist();
  }

  Future<void> addMedicine(String memberId, Medicine medicine) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(medicines: [...m.medicines, medicine]);
    }).toList();
    await _persist();
  }

  Future<void> toggleMedicine(String memberId, String medicineId) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
        medicines: m.medicines
            .map((med) =>
                med.id == medicineId ? med.copyWith(active: !med.active) : med)
            .toList(),
      );
    }).toList();
    await _persist();
  }

  Future<void> deleteMedicine(String memberId, String medicineId) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
          medicines: m.medicines.where((med) => med.id != medicineId).toList());
    }).toList();
    await _persist();
  }

  Future<void> addVitamin(String memberId, Vitamin vitamin) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(vitamins: [...m.vitamins, vitamin]);
    }).toList();
    await _persist();
  }

  Future<void> addReport(String memberId, DoctorReport report) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(reports: [...m.reports, report]);
    }).toList();
    await _persist();
  }

  Future<void> addAppointment(
      String memberId, DoctorAppointment appointment) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
          appointments: [...m.appointments, appointment]);
    }).toList();
    await _persist();
    await _scheduleAppointmentReminder(appointment);
  }

  /// Randevu gününde 09:00'da hatırlatma bildirimi kurar (dd.MM.yyyy).
  Future<void> _scheduleAppointmentReminder(DoctorAppointment a) async {
    try {
      final d = DateFormat('dd.MM.yyyy').parseStrict(a.dateTime);
      final when = DateTime(d.year, d.month, d.day, 9, 0);
      if (when.isBefore(DateTime.now())) return;
      await NotificationService.requestPermission();
      await NotificationService.scheduleNotification(
        id: a.id.hashCode & 0x7fffff,
        title: '🩺 Doktor Randevusu',
        body:
            '${a.doctorName}${a.specialty.isNotEmpty ? ' · ${a.specialty}' : ''} bugün'
            '${a.location.isNotEmpty ? ' · ${a.location}' : ''}',
        scheduledDate: when,
        payload: 'appointment:${a.id}',
      );
    } catch (_) {}
  }

  Future<void> completeAppointment(
      String memberId, String appointmentId) async {
    state = state.map((m) {
      if (m.id != memberId) return m;
      return m.copyWith(
        appointments: m.appointments
            .map((a) => a.id == appointmentId
                ? a.copyWith(completed: true)
                : a)
            .toList(),
      );
    }).toList();
    await _persist();
  }
}

// ── Main Screen ──

class FamilyHealthScreen extends ConsumerStatefulWidget {
  const FamilyHealthScreen({super.key});

  @override
  ConsumerState<FamilyHealthScreen> createState() => _FamilyHealthScreenState();
}

class _FamilyHealthScreenState extends ConsumerState<FamilyHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedMember = 0;

  static const _tabs = ['💊 İlaçlar', '🌿 Vitaminler', '📋 Raporlar', '📅 Randevular'];

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
    final members = ref.watch(familyHealthProvider);
    final member = members.isEmpty ? null : members[_selectedMember.clamp(0, members.length - 1)];

    const teal = Color(0xFF14B8A6);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF071A18), Color(0xFF0A2420)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(bottom: BorderSide(color: teal.withAlpha(30), width: 0.5)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Aile Hekimi',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Sağlık takibi & ilaç yönetimi',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      const SizedBox(height: 12),
                      // Member selector
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: members.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            if (i == members.length) {
                              return GestureDetector(
                                onTap: () => _addMember(members),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withAlpha(80),
                                        width: 1.5,
                                        style: BorderStyle.solid),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 20),
                                ),
                              );
                            }
                            final m = members[i];
                            final sel = _selectedMember == i;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMember = i),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
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
                                        child: Text(m.emoji,
                                            style: const TextStyle(
                                                fontSize: 22))),
                                  ),
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
              indicatorColor: teal,
              labelColor: teal,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          if (member == null)
            const SliverFillRemaining(
              child: Center(child: Text('Aile üyesi ekleyin')),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: TabBarView(
                controller: _tab,
                children: [
                  _MedicineTab(member: member),
                  _VitaminTab(member: member),
                  _ReportsTab(member: member),
                  _AppointmentsTab(member: member),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: member == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addItem(member),
              backgroundColor: const Color(0xFF11998E),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _fabLabel(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  String _fabLabel() {
    switch (_tab.index) {
      case 0: return 'İlaç Ekle';
      case 1: return 'Vitamin Ekle';
      case 2: return 'Rapor Ekle';
      case 3: return 'Randevu Ekle';
      default: return 'Ekle';
    }
  }

  void _addItem(FamilyMemberHealth member) {
    switch (_tab.index) {
      case 0: _showAddMedicineSheet(member); break;
      case 1: _showAddVitaminSheet(member); break;
      case 2: _showAddReportSheet(member); break;
      case 3: _showAddAppointmentSheet(member); break;
    }
  }

  void _addMember(List<FamilyMemberHealth> existing) {
    final nameCtrl = TextEditingController();
    String emoji = '👤';
    final emojis = ['👩', '👨', '👧', '👦', '👴', '👵', '🧒', '👶'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => _Sheet(
          title: '👤 Aile Üyesi Ekle',
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () => setSt(() => emoji = e),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: emoji == e
                            ? const Color(0xFF11998E).withAlpha(30)
                            : Colors.grey.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: emoji == e
                              ? const Color(0xFF11998E)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _Field(controller: nameCtrl, label: 'Ad (örn. Anne, Ahmet)'),
              const SizedBox(height: 16),
              _GradBtn(
                label: 'Ekle',
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ref.read(familyHealthProvider.notifier).addMember(
                        FamilyMemberHealth(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  void _showAddMedicineSheet(FamilyMemberHealth member) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        title: '💊 İlaç Ekle — ${member.name}',
        child: Column(
          children: [
            _Field(controller: nameCtrl, label: 'İlaç adı'),
            const SizedBox(height: 10),
            _Field(controller: dosageCtrl, label: 'Doz (örn. 500mg, 1 tablet)'),
            const SizedBox(height: 10),
            _Field(
                controller: freqCtrl,
                label: 'Kullanım (örn. Günde 2 kez, sabah)'),
            const SizedBox(height: 10),
            _Field(
                controller: notesCtrl,
                label: 'Notlar (isteğe bağlı)',
                maxLines: 2),
            const SizedBox(height: 16),
            _GradBtn(
              label: 'İlacı Kaydet',
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(familyHealthProvider.notifier).addMedicine(
                      member.id,
                      Medicine(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        frequency: freqCtrl.text.trim(),
                        startDate: DateFormat('dd.MM.yyyy').format(DateTime.now()),
                        notes: notesCtrl.text.trim(),
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

  void _showAddVitaminSheet(FamilyMemberHealth member) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String timing = 'Sabah';
    final timings = ['Sabah', 'Öğle', 'Akşam', 'Yemekle', 'Aç karna'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setSt) => _Sheet(
          title: '🌿 Vitamin/Takviye Ekle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(controller: nameCtrl, label: 'Vitamin adı (örn. D3, Omega-3)'),
              const SizedBox(height: 10),
              _Field(controller: amountCtrl, label: 'Miktar (örn. 1000 IU, 2 kapsül)'),
              const SizedBox(height: 12),
              const Text('Kullanım zamanı',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: timings.map((t) {
                  final sel = timing == t;
                  return GestureDetector(
                    onTap: () => setSt(() => timing = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF11998E)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _GradBtn(
                label: 'Vitamin Kaydet',
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  ref.read(familyHealthProvider.notifier).addVitamin(
                        member.id,
                        Vitamin(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          amount: amountCtrl.text.trim(),
                          timing: timing,
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReportSheet(FamilyMemberHealth member) {
    final titleCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'Muayene';
    String? docName; // seçilen belge dosya adı
    final types = ['Muayene', 'Kan Tahlili', 'Röntgen', 'MR/BT', 'Reçete', 'Diğer'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setSt) => _Sheet(
          title: '📋 Rapor / Belge Ekle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(controller: titleCtrl, label: 'Başlık (örn. Yıllık check-up)'),
              const SizedBox(height: 10),
              _Field(controller: doctorCtrl, label: 'Doktor / Klinik adı'),
              const SizedBox(height: 10),
              const Text('Rapor türü',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: types.map((t) {
                  final sel = type == t;
                  return GestureDetector(
                    onTap: () => setSt(() => type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF11998E)
                            : Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _Field(
                  controller: notesCtrl,
                  label: 'Notlar / Bulgular',
                  maxLines: 3),
              const SizedBox(height: 8),
              // Belge / fotoğraf ekle (file_selector ile gerçek seçim).
              GestureDetector(
                onTap: () async {
                  final f = await openFile();
                  if (f != null) setSt(() => docName = f.name);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF11998E).withAlpha(80),
                        width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF11998E).withAlpha(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(docName == null ? Icons.attach_file : Icons.check_circle,
                          color: const Color(0xFF11998E)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                            docName ?? 'Belge / Fotoğraf Ekle (PDF, JPG)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF11998E),
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _GradBtn(
                label: 'Raporu Kaydet',
                onTap: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  ref.read(familyHealthProvider.notifier).addReport(
                        member.id,
                        DoctorReport(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          title: titleCtrl.text.trim(),
                          doctor: doctorCtrl.text.trim(),
                          date: DateFormat('dd.MM.yyyy').format(DateTime.now()),
                          notes: docName != null
                              ? '${notesCtrl.text.trim()}\n📎 $docName'.trim()
                              : notesCtrl.text.trim(),
                          reportType: type,
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAppointmentSheet(FamilyMemberHealth member) {
    final doctorCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setSt) => _Sheet(
          title: '📅 Randevu Ekle — ${member.name}',
          child: Column(
            children: [
              _Field(controller: doctorCtrl, label: 'Doktor adı'),
              const SizedBox(height: 10),
              _Field(
                  controller: specialtyCtrl,
                  label: 'Uzmanlık (Kardiyoloji, Göz vb.)'),
              const SizedBox(height: 10),
              _Field(controller: locationCtrl, label: 'Hastane / Klinik'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setSt(() => selectedDate = d);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF11998E), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF11998E), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _GradBtn(
                label: 'Randevuyu Kaydet',
                onTap: () {
                  if (doctorCtrl.text.trim().isEmpty) return;
                  ref
                      .read(familyHealthProvider.notifier)
                      .addAppointment(
                        member.id,
                        DoctorAppointment(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          doctorName: doctorCtrl.text.trim(),
                          specialty: specialtyCtrl.text.trim(),
                          dateTime: DateFormat('dd.MM.yyyy')
                              .format(selectedDate),
                          location: locationCtrl.text.trim(),
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Widgets ──

class _MedicineTab extends ConsumerWidget {
  final FamilyMemberHealth member;
  const _MedicineTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read to get fresh state
    final freshMember = ref
        .watch(familyHealthProvider)
        .firstWhere((m) => m.id == member.id, orElse: () => member);

    if (freshMember.medicines.isEmpty) {
      return const _EmptyState(
          emoji: '💊', text: 'Henüz ilaç eklenmedi\n+ butonuna dokun');
    }

    final active = freshMember.medicines.where((m) => m.active).toList();
    final passive = freshMember.medicines.where((m) => !m.active).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _SectionLabel('Aktif İlaçlar (${active.length})'),
          ...active.map((m) => _MedicineTile(
                medicine: m,
                memberId: freshMember.id,
                ref: ref,
              )),
        ],
        if (passive.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionLabel('Pasif / Tamamlanan (${passive.length})'),
          ...passive.map((m) => _MedicineTile(
                medicine: m,
                memberId: freshMember.id,
                ref: ref,
              )),
        ],
      ],
    );
  }
}

class _MedicineTile extends StatelessWidget {
  final Medicine medicine;
  final String memberId;
  final WidgetRef ref;
  const _MedicineTile(
      {required this.medicine, required this.memberId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: medicine.active
            ? const Color(0xFF11998E).withAlpha(12)
            : Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: medicine.active
              ? const Color(0xFF11998E).withAlpha(60)
              : Colors.grey.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: medicine.active
                  ? const Color(0xFF11998E)
                  : Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Text('💊', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: medicine.active
                            ? Colors.black87
                            : Colors.grey)),
                if (medicine.dosage.isNotEmpty)
                  Text(medicine.dosage,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                if (medicine.frequency.isNotEmpty)
                  Text(medicine.frequency,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                if (medicine.startDate.isNotEmpty)
                  Text('Başlangıç: ${medicine.startDate}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFB0B7C0))),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => ref
                    .read(familyHealthProvider.notifier)
                    .toggleMedicine(memberId, medicine.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: medicine.active
                        ? Colors.green.withAlpha(20)
                        : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    medicine.active ? '✓ Aktif' : 'Pasif',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: medicine.active
                            ? Colors.green
                            : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => ref
                    .read(familyHealthProvider.notifier)
                    .deleteMedicine(memberId, medicine.id),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitaminTab extends ConsumerWidget {
  final FamilyMemberHealth member;
  const _VitaminTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(familyHealthProvider)
        .firstWhere((m) => m.id == member.id, orElse: () => member);

    if (fresh.vitamins.isEmpty) {
      return const _EmptyState(
          emoji: '🌿', text: 'Henüz vitamin/takviye eklenmedi');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fresh.vitamins.map((v) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF38EF7D).withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF38EF7D).withAlpha(60)),
          ),
          child: Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800)),
                    if (v.amount.isNotEmpty)
                      Text(v.amount,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    Text('⏰ ${v.timing}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('✓ Aktif',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final FamilyMemberHealth member;
  const _ReportsTab({required this.member});

  static const _typeIcon = {
    'Muayene': '👨‍⚕️',
    'Kan Tahlili': '🩸',
    'Röntgen': '🩻',
    'MR/BT': '🧠',
    'Reçete': '📜',
    'Diğer': '📄',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(familyHealthProvider)
        .firstWhere((m) => m.id == member.id, orElse: () => member);

    if (fresh.reports.isEmpty) {
      return const _EmptyState(
          emoji: '📋', text: 'Henüz rapor / belge eklenmedi');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fresh.reports.reversed.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_typeIcon[r.reportType] ?? '📄',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800)),
                    if (r.doctor.isNotEmpty)
                      Text('👨‍⚕️ ${r.doctor}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280))),
                    Text(r.date,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF))),
                    if (r.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF374151))),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.reportType,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AppointmentsTab extends ConsumerWidget {
  final FamilyMemberHealth member;
  const _AppointmentsTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref
        .watch(familyHealthProvider)
        .firstWhere((m) => m.id == member.id, orElse: () => member);

    final upcoming = fresh.appointments
        .where((a) => !a.completed)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final done =
        fresh.appointments.where((a) => a.completed).toList();

    if (fresh.appointments.isEmpty) {
      return const _EmptyState(
          emoji: '📅', text: 'Henüz randevu eklenmedi');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          _SectionLabel('Yaklaşan Randevular (${upcoming.length})'),
          ...upcoming.map((a) => _AppointmentTile(
                appointment: a,
                memberId: fresh.id,
                ref: ref,
              )),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionLabel('Tamamlanan (${done.length})'),
          ...done.map((a) => _AppointmentTile(
                appointment: a,
                memberId: fresh.id,
                ref: ref,
              )),
        ],
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final DoctorAppointment appointment;
  final String memberId;
  final WidgetRef ref;
  const _AppointmentTile(
      {required this.appointment,
      required this.memberId,
      required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appointment.completed
            ? Colors.grey.withAlpha(15)
            : Colors.orange.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appointment.completed
              ? Colors.grey.withAlpha(40)
              : Colors.orange.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Text(appointment.completed ? '✅' : '📅',
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.doctorName,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: appointment.completed
                            ? Colors.grey
                            : Colors.black87)),
                if (appointment.specialty.isNotEmpty)
                  Text(appointment.specialty,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                Text('📍 ${appointment.location.isNotEmpty ? appointment.location : "Belirtilmedi"}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
                Text('🗓 ${appointment.dateTime}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151))),
              ],
            ),
          ),
          if (!appointment.completed)
            GestureDetector(
              onTap: () => ref
                  .read(familyHealthProvider.notifier)
                  .completeAppointment(memberId, appointment.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.green.withAlpha(80)),
                ),
                child: const Text('Tamamla',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ──

class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827))),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _Field(
      {required this.controller,
      required this.label,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFF111827)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF11998E), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11998E).withAlpha(60),
              blurRadius: 12,
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

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String text;
  const _EmptyState({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
            letterSpacing: .3),
      ),
    );
  }
}
