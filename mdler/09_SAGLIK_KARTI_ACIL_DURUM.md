# SAGLIK KARTI & ACIL DURUM
## 6 Saglik/Acil Sorun | Hedef: Tam Saglik Profili + Otomatik SOS

---

## 41. Saglik Karti — Secenekler Halinde + Otomatik Acil Kisi

**Sorun:** Saglik karti secenekler halinde olmali, acil durum kisisi aile icinden otomatik secilmeli

### lib/features/health/models/health_card.dart
```dart
class HealthCard {
  final String userId;
  final BloodType? bloodType;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final List<Medication> medications;
  final EmergencyContact emergencyContact;
  final String? specialNotes;
  final DateTime lastUpdated;

  HealthCard({
    required this.userId,
    this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.medications = const [],
    required this.emergencyContact,
    this.specialNotes,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'blood_type': bloodType?.value,
    'allergies': allergies,
    'chronic_diseases': chronicDiseases,
    'medications': medications.map((m) => m.toJson()).toList(),
    'emergency_contact_name': emergencyContact.name,
    'emergency_contact_phone': emergencyContact.phone,
    'emergency_contact_relation': emergencyContact.relation,
    'special_notes': specialNotes,
    'last_updated': lastUpdated.toIso8601String(),
  };

  factory HealthCard.fromJson(Map<String, dynamic> json) => HealthCard(
    userId: json['user_id'],
    bloodType: BloodType.fromString(json['blood_type']),
    allergies: List<String>.from(json['allergies'] ?? []),
    chronicDiseases: List<String>.from(json['chronic_diseases'] ?? []),
    medications: (json['medications'] as List? ?? [])
        .map((m) => Medication.fromJson(m)).toList(),
    emergencyContact: EmergencyContact(
      name: json['emergency_contact_name'] ?? '',
      phone: json['emergency_contact_phone'] ?? '',
      relation: json['emergency_contact_relation'] ?? '',
      isAutoSelected: false,
    ),
    specialNotes: json['special_notes'],
    lastUpdated: DateTime.parse(json['last_updated']),
  );
}

enum BloodType {
  aPositive('A+'), aNegative('A-'),
  bPositive('B+'), bNegative('B-'),
  abPositive('AB+'), abNegative('AB-'),
  oPositive('O+'), oNegative('O-');

  final String value;
  const BloodType(this.value);

  static BloodType? fromString(String? value) {
    if (value == null) return null;
    return BloodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BloodType.oPositive,
    );
  }
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String? notes;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'notes': notes,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    name: json['name'],
    dosage: json['dosage'],
    frequency: json['frequency'],
    notes: json['notes'],
  );
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;
  final bool isAutoSelected;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
    this.isAutoSelected = false,
  });

  factory EmergencyContact.empty() => EmergencyContact(
    name: '', phone: '', relation: '',
  );
}
```

### lib/features/health/screens/health_card_screen.dart
```dart
class HealthCardScreen extends StatefulWidget {
  @override
  _HealthCardScreenState createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  final HealthCardService _service = HealthCardService();
  final FamilyRepository _familyRepo = FamilyRepository();

  HealthCard? _healthCard;
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final card = await _service.getHealthCard();
    final members = await _familyRepo.getFamilyMembers(_getFamilyId());

    // Acil durum kisisi otomatik sec
    EmergencyContact? autoContact;
    if (card?.emergencyContact.name.isEmpty ?? true) {
      autoContact = _autoSelectEmergencyContact(members);
    }

    setState(() {
      _healthCard = card ?? HealthCard(
        userId: SupabaseConfig.currentUser!.id,
        emergencyContact: autoContact ?? EmergencyContact.empty(),
        lastUpdated: DateTime.now(),
      );
      _familyMembers = members;
      _isLoading = false;
    });
  }

  EmergencyContact _autoSelectEmergencyContact(List<FamilyMember> members) {
    // Oncelik sirasi: Es > Anne > Baba > Cocuk > Kardes > Dost
    final priorityOrder = ['es', 'anne', 'baba', 'cocuk', 'kardes', 'dost'];

    for (final relation in priorityOrder) {
      final match = members.firstWhere(
        (m) => m.role?.toLowerCase() == relation,
        orElse: () => null as FamilyMember,
      );
      if (match != null) {
        return EmergencyContact(
          name: match.name,
          relation: match.role ?? 'Aile',
          phone: match.phone ?? '',
          isAutoSelected: true,
        );
      }
    }

    // Hicbiri yoksa ilk aile uyesi
    if (members.isNotEmpty) {
      return EmergencyContact(
        name: members.first.name,
        relation: members.first.role ?? 'Aile',
        phone: members.first.phone ?? '',
        isAutoSelected: true,
      );
    }

    return EmergencyContact.empty();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saglik Kartim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.bloodtype,
            title: 'Kan Grubu',
            child: _buildBloodTypeSelector(isDark),
          ),
          _buildSection(
            icon: Icons.warning_amber,
            title: 'Alerjiler',
            child: _buildMultiSelectChips(
              options: ['Polen', 'Toz', 'Ilac', 'Gida', 'Lateks', 'Yok'],
              selected: _healthCard!.allergies,
              onSelected: (value) => _toggleAllergy(value),
            ),
          ),
          _buildSection(
            icon: Icons.medical_services,
            title: 'Kronik Hastaliklar',
            child: _buildMultiSelectChips(
              options: ['Diyabet', 'Hipertansiyon', 'Astim', 'Kalp', 'Epilepsi', 'Yok'],
              selected: _healthCard!.chronicDiseases,
              onSelected: (value) => _toggleDisease(value),
            ),
          ),
          _buildSection(
            icon: Icons.medication,
            title: 'Duzenli Ilaclar',
            child: _buildMedicationList(),
          ),
          _buildSection(
            icon: Icons.contact_emergency,
            title: 'Acil Durum Kisisi',
            subtitle: _healthCard!.emergencyContact.isAutoSelected 
                ? '(Otomatik secildi)' 
                : null,
            child: _buildEmergencyContactCard(isDark),
          ),
          _buildSection(
            icon: Icons.note,
            title: 'Ozel Notlar',
            child: TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Doktor notlari, ozel durumlar...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              controller: TextEditingController(text: _healthCard!.specialNotes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BloodType.values.map((type) {
        final isSelected = _healthCard!.bloodType == type;
        return ChoiceChip(
          label: Text(type.value),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _healthCard = HealthCard(
                userId: _healthCard!.userId,
                bloodType: selected ? type : null,
                allergies: _healthCard!.allergies,
                chronicDiseases: _healthCard!.chronicDiseases,
                medications: _healthCard!.medications,
                emergencyContact: _healthCard!.emergencyContact,
                specialNotes: _healthCard!.specialNotes,
                lastUpdated: DateTime.now(),
              );
            });
          },
          selectedColor: AppColors.primary,
          backgroundColor: isDark ? AppColors.surfaceDarkElevated : Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyContactCard(bool isDark) {
    final contact = _healthCard!.emergencyContact;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isAutoSelected 
              ? AppColors.info.withOpacity(0.5) 
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.error.withOpacity(0.2),
                child: const Icon(Icons.person, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name.isEmpty ? 'Secilmemis' : contact.name,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      contact.relation,
                      style: TextStyle(
                        fontSize: 13, 
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (contact.isAutoSelected)
                Chip(
                  label: const Text('Otomatik', style: TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.info.withOpacity(0.2),
                  side: BorderSide.none,
                ),
            ],
          ),
          if (contact.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(contact.phone),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.success),
                  onPressed: () => _callEmergency(contact.phone),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12, 
                  color: AppColors.textTertiaryDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      final allergies = List<String>.from(_healthCard!.allergies);
      if (allergies.contains(allergy)) {
        allergies.remove(allergy);
      } else {
        allergies.add(allergy);
      }
      _healthCard = HealthCard(
        userId: _healthCard!.userId,
        bloodType: _healthCard!.bloodType,
        allergies: allergies,
        chronicDiseases: _healthCard!.chronicDiseases,
        medications: _healthCard!.medications,
        emergencyContact: _healthCard!.emergencyContact,
        specialNotes: _healthCard!.specialNotes,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _toggleDisease(String disease) {
    setState(() {
      final diseases = List<String>.from(_healthCard!.chronicDiseases);
      if (diseases.contains(disease)) {
        diseases.remove(disease);
      } else {
        diseases.add(disease);
      }
      _healthCard = HealthCard(
        userId: _healthCard!.userId,
        bloodType: _healthCard!.bloodType,
        allergies: _healthCard!.allergies,
        chronicDiseases: diseases,
        medications: _healthCard!.medications,
        emergencyContact: _healthCard!.emergencyContact,
        specialNotes: _healthCard!.specialNotes,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _callEmergency(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _navigateToEdit() {
    // Edit screen navigation
  }

  String _getFamilyId() {
    return context.read<FamilyProvider>().currentFamilyId;
  }

  Widget _buildMedicationList() {
    return Column(
      children: [
        ..._healthCard!.medications.map((med) => ListTile(
          leading: const Icon(Icons.medication, color: AppColors.primary),
          title: Text(med.name),
          subtitle: Text('${med.dosage} - ${med.frequency}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () => _removeMedication(med),
          ),
        )),
        ListTile(
          leading: const Icon(Icons.add, color: AppColors.primary),
          title: const Text('Ilac Ekle'),
          onTap: () => _showAddMedicationDialog(),
        ),
      ],
    );
  }

  void _removeMedication(Medication med) {
    setState(() {
      _healthCard = HealthCard(
        userId: _healthCard!.userId,
        bloodType: _healthCard!.bloodType,
        allergies: _healthCard!.allergies,
        chronicDiseases: _healthCard!.chronicDiseases,
        medications: _healthCard!.medications.where((m) => m.name != med.name).toList(),
        emergencyContact: _healthCard!.emergencyContact,
        specialNotes: _healthCard!.specialNotes,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _showAddMedicationDialog() {
    // Add medication dialog
  }
}
```

---

## 42. Emergency Screen — Gercek SOS

**Sorun:** Sadece animasyon, gercek SOS gondermiyor

### lib/features/safety/screens/emergency_screen.dart
```dart
class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendSOS() async {
    setState(() => _isSending = true);

    try {
      // 1. Konum al
      final position = await Geolocator.getCurrentPosition();

      // 2. Acil durum kisilerini cek
      final healthCard = await HealthCardService().getHealthCard();
      final contacts = await FamilyRepository().getEmergencyContacts();

      // 3. SMS gonder
      for (final contact in contacts) {
        await SmsService().sendSms(
          phoneNumber: contact.phone,
          message: '🚨 ACIL DURUM! ${healthCard?.emergencyContact.name ?? 'Kullanici'} '
              'yardim ihtiyaci var. Konum: '
              'https://maps.google.com/?q=${position.latitude},${position.longitude}',
        );
      }

      // 4. Supabase'e kaydet
      await SupabaseConfig.safeClient.from('emergency_alerts').insert({
        'user_id': SupabaseConfig.currentUser!.id,
        'location': '${position.latitude},${position.longitude}',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS gonderildi! Acil durum kisilerine bilgi verildi.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS gonderilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.error,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: GestureDetector(
                    onTap: _isSending ? null : _sendSOS,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSending
                            ? const CircularProgressIndicator(color: AppColors.error)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sos, size: 64, color: AppColors.error),
                                  SizedBox(height: 8),
                                  Text(
                                    'SOS',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'Acil durumda dokunun',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Iptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 43. Crash Detection — 9 TODO Tamamlama

**Sorun:** 9 bos method

### lib/features/safety/services/crash_detection_service.dart
```dart
class CrashDetectionService {
  final SafetyRepository _safetyRepo = SafetyRepository();
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  final CallService _callService = CallService();
  final AudioService _audioService = AudioService();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isMonitoring = false;

  /// 1. Servisi baslat
  Future<void> initialize() async {
    await _requestPermissions();
    _startMonitoring();
  }

  /// 2. Izinleri iste
  Future<void> _requestPermissions() async {
    await Permission.sms.request();
    await Permission.phone.request();
    await Permission.location.request();
    await Permission.sensors.request();
  }

  /// 3. Sensor monitoring baslat
  void _startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );

      // Kaza threshold: 5G'den fazla ivme
      if (magnitude > 5 * 9.81) {
        _handleCrashDetected();
      }
    });
  }

  /// 4. Kaza algilandi
  Future<void> _handleCrashDetected() async {
    // Sensor'u durdur
    _accelerometerSubscription?.pause();

    // 1. Konum al
    final position = await _locationService.getCurrentPosition();

    // 2. Acil durum kisilerini cek
    final emergencyContacts = await _safetyRepo.getEmergencyContacts();

    // 3. SMS gonder
    for (final contact in emergencyContacts) {
      await _smsService.sendSms(
        phoneNumber: contact.phone,
        message: '🚨 KAZA ALGILANDI! Konum: '
            'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      );
    }

    // 4. Alarm cal
    await _audioService.playAlarmSound();

    // 5. Countdown baslat
    final userCancelled = await _showCancelCountdown();

    if (!userCancelled) {
      // 6. 112'yi ara
      await _callService.callEmergency('112');
    }

    // Sensor'u tekrar baslat
    _accelerometerSubscription?.resume();
  }

  /// 5. Countdown dialog
  Future<bool> _showCancelCountdown() async {
    bool cancelled = false;

    await showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => EmergencyCountdownDialog(
        seconds: 30,
        onCancel: () {
          cancelled = true;
          _audioService.stopAlarm();
          Navigator.pop(context);
        },
      ),
    );

    return cancelled;
  }

  /// 6. Servisi durdur
  void dispose() {
    _accelerometerSubscription?.cancel();
    _isMonitoring = false;
  }

  /// 7. Background task
  static void backgroundTask() {
    // WorkManager callback
    CrashDetectionService().initialize();
  }

  /// 8. Test modu
  Future<void> testCrashDetection() async {
    await _handleCrashDetected();
  }

  /// 9. Durum kontrolu
  bool get isMonitoring => _isMonitoring;
}
```

---

## Kontrol Listesi

- [ ] Saglik karti kan grubu secenekleri calisiyor
- [ ] Alerji ve hastalik multi-select calisiyor
- [ ] Ilac listesi ekleme/cikarma calisiyor
- [ ] Acil durum kisisi otomatik seciliyor (Es > Anne > Baba > Cocuk)
- [ ] Acil durum kisisi aranabiliyor
- [ ] SOS butonu gercek SMS gonderiyor
- [ ] Crash detection 9 method tamamlandi
- [ ] Sensor monitoring calisiyor
- [ ] 30 saniye countdown calisiyor
- [ ] 112 arama implemente edildi

---
**Versiyon:** 1.0 | **Dosya:** 9/10 | **Hedef:** Tam Saglik Profili + Otomatik SOS
