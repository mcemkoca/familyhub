import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../config/constants.dart';
import '../../../domain/models/smart_reminder.dart';
import '../../../repositories/smart_reminder_repository.dart';
import '../../../services/auth_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SmartReminderCreateScreen extends StatefulWidget {
  const SmartReminderCreateScreen({super.key});

  @override
  State<SmartReminderCreateScreen> createState() =>
      _SmartReminderCreateScreenState();
}

class _SmartReminderCreateScreenState extends State<SmartReminderCreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Trigger states
  bool _locationEnabled = false;
  LocationTriggerType _locationType = LocationTriggerType.nearby;
  final _locationNameController = TextEditingController(text: 'A101 Market');
  final _latController = TextEditingController(text: '41.0082');
  final _lngController = TextEditingController(text: '28.9784');
  double _radius = 200;
  double _proximity = 500;

  bool _timeEnabled = false;
  TimeTriggerType _timeType = TimeTriggerType.absolute;
  TimeOfDay _absoluteTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _smartStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _smartEnd = const TimeOfDay(hour: 21, minute: 0);

  bool _behaviorEnabled = false;
  BehaviorTriggerType _behaviorType = BehaviorTriggerType.inactivity;

  CompositeLogic _compositeLogic = CompositeLogic.and_;

  // Sensitivity
  bool _quietHours = true;
  bool _dndRespect = true;
  double _interruptibility = 80;

  // Personalization
  ReminderTone _tone = ReminderTone.friendly;
  bool _includeContext = true;

  // Target
  TargetAudienceType _targetType = TargetAudienceType.smartSelect;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).baslikGirilmeli)));
      return;
    }

    HapticFeedback.mediumImpact();

    final triggers = TriggerConfig(
      location: _locationEnabled
          ? LocationTrigger(
              enabled: true,
              type: _locationType,
              geofence: GeofenceConfig(
                latitude: double.tryParse(_latController.text) ?? 0,
                longitude: double.tryParse(_lngController.text) ?? 0,
                radiusMeters: _radius,
                name: _locationNameController.text,
              ),
              proximityMeters: _proximity,
            )
          : const LocationTrigger(),
      time: _timeEnabled
          ? TimeTrigger(
              enabled: true,
              type: _timeType,
              absoluteTime: _timeType == TimeTriggerType.absolute
                  ? DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      _absoluteTime.hour,
                      _absoluteTime.minute,
                    )
                  : null,
              smartWindow: _timeType == TimeTriggerType.smartSuggest
                  ? SmartWindow(start: _smartStart, end: _smartEnd)
                  : null,
            )
          : const TimeTrigger(),
      behavior: _behaviorEnabled
          ? BehaviorTrigger(enabled: true, type: _behaviorType)
          : const BehaviorTrigger(),
      composite: CompositeTrigger(
        enabled:
            (_locationEnabled && _timeEnabled) ||
            (_locationEnabled && _behaviorEnabled) ||
            (_timeEnabled && _behaviorEnabled),
        logic: _compositeLogic,
        triggers: [
          if (_locationEnabled) TriggerType.location,
          if (_timeEnabled) TriggerType.time,
          if (_behaviorEnabled) TriggerType.behavior,
        ],
      ),
    );

    final userId = AuthService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).girisYapmalisiniz)),
      );
      return;
    }
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('family_id, display_name')
        .eq('id', userId)
        .maybeSingle();
    if (!context.mounted) return;
    final familyId = profile?['family_id'] as String?;
    if (familyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).aileBilgisiBulunamadi)),
      );
      return;
    }

    final reminder = SmartReminder(
      id: const Uuid().v4(),
      familyId: familyId,
      createdBy: userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      triggers: triggers,
      contextSensitivity: ContextSensitivity(
        quietHoursRespect: _quietHours,
        doNotDisturbOverride: _dndRespect,
        interruptibilityThreshold: _interruptibility,
      ),
      personalization: Personalization(
        tone: _tone,
        includeContext: _includeContext,
      ),
      targetAudience: TargetAudience(type: _targetType),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await SmartReminderRepository().create(reminder);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).hatirlaticiOlusturuldu)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _testReminder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TestPreviewSheet(
        title: _titleController.text.isEmpty
            ? 'Test Hatırlatıcı'
            : _titleController.text,
        description: _descController.text,
        tone: _tone,
        includeContext: _includeContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).yeniAkilliHatirlatici),
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8F9FA),
        foregroundColor: textColor,
        actions: [
          TextButton(onPressed: _testReminder, child: const Text('🧪 Test Et')),
          TextButton(
            onPressed: _save,
            child: const Text(
              '💾 Kaydet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBasicInfoCard(isDark, textColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTriggersCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSensitivityCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPersonalizationCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTargetCard(isDark, textColor),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isDark, Color textColor) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temel Bilgiler', style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              hintText: 'Market alışverişi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Süt ve ekmek al...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersCard(bool isDark, Color textColor) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 Tetikleyiciler (Context)', style: _sectionStyle(textColor)),
          const SizedBox(height: 12),

          // Location
          SwitchListTile(
            title: const Text('📍 Lokasyon'),
            subtitle: Text(_locationEnabled ? 'Aktif' : 'Pasif'),
            value: _locationEnabled,
            onChanged: (v) => setState(() => _locationEnabled = v),
          ),
          if (_locationEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                children: [
                  DropdownButtonFormField<LocationTriggerType>(
                    initialValue: _locationType,
                    decoration: const InputDecoration(labelText: 'Tür'),
                    items: LocationTriggerType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(_locationTypeLabel(t)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _locationType = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationNameController,
                    decoration: const InputDecoration(labelText: 'Yer Adı'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: const InputDecoration(labelText: 'Enlem'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: const InputDecoration(
                            labelText: 'Boylam',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Geofence Yarıçapı: ${_radius.toInt()}m'),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  Text('Yaklaşma Mesafesi: ${_proximity.toInt()}m'),
                  Slider(
                    value: _proximity,
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    onChanged: (v) => setState(() => _proximity = v),
                  ),
                ],
              ),
            ),
          ],

          const Divider(),

          // Time
          SwitchListTile(
            title: const Text('⏰ Zaman'),
            subtitle: Text(_timeEnabled ? 'Aktif' : 'Pasif'),
            value: _timeEnabled,
            onChanged: (v) => setState(() => _timeEnabled = v),
          ),
          if (_timeEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                children: [
                  DropdownButtonFormField<TimeTriggerType>(
                    initialValue: _timeType,
                    decoration: const InputDecoration(labelText: 'Tür'),
                    items: TimeTriggerType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(_timeTypeLabel(t)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _timeType = v!),
                  ),
                  const SizedBox(height: 12),
                  if (_timeType == TimeTriggerType.absolute)
                    ListTile(
                      title: const Text('Saat'),
                      trailing: Text(_absoluteTime.format(context)),
                      onTap: () => _pickTime(
                        _absoluteTime,
                        (t) => setState(() => _absoluteTime = t),
                      ),
                    ),
                  if (_timeType == TimeTriggerType.smartSuggest)
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(AppLocalizations.of(context).startTime),
                            trailing: Text(_smartStart.format(context)),
                            onTap: () => _pickTime(
                              _smartStart,
                              (t) => setState(() => _smartStart = t),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(AppLocalizations.of(context).endTime),
                            trailing: Text(_smartEnd.format(context)),
                            onTap: () => _pickTime(
                              _smartEnd,
                              (t) => setState(() => _smartEnd = t),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          const Divider(),

          // Behavior
          SwitchListTile(
            title: Text(AppLocalizations.of(context).davranis),
            subtitle: Text(_behaviorEnabled ? 'Aktif' : 'Pasif'),
            value: _behaviorEnabled,
            onChanged: (v) => setState(() => _behaviorEnabled = v),
          ),
          if (_behaviorEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: DropdownButtonFormField<BehaviorTriggerType>(
                initialValue: _behaviorType,
                decoration: const InputDecoration(labelText: 'Davranış Türü'),
                items: BehaviorTriggerType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_behaviorTypeLabel(t)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _behaviorType = v!),
              ),
            ),

          if ((_locationEnabled && _timeEnabled) ||
              (_locationEnabled && _behaviorEnabled) ||
              (_timeEnabled && _behaviorEnabled)) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).bilesikMantik),
                  const SizedBox(height: 8),
                  SegmentedButton<CompositeLogic>(
                    segments: const [
                      ButtonSegment(
                        value: CompositeLogic.and_,
                        label: Text('AND'),
                      ),
                      ButtonSegment(
                        value: CompositeLogic.or_,
                        label: Text('OR'),
                      ),
                    ],
                    selected: {_compositeLogic},
                    onSelectionChanged: (s) =>
                        setState(() => _compositeLogic = s.first),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensitivityCard(bool isDark, Color textColor) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧠 Bağlam Hassasiyeti', style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).sessizSaatlereSaygiGoster),
            subtitle: Text(AppLocalizations.of(context).arasiSessiz),
            value: _quietHours,
            onChanged: (v) => setState(() => _quietHours = v),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).rahatsizEtmeModunaSaygi),
            value: _dndRespect,
            onChanged: (v) => setState(() => _dndRespect = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rahatsız Edilebilirlik: ${_interruptibility.toInt()}%'),
                Slider(
                  value: _interruptibility,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => setState(() => _interruptibility = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationCard(bool isDark, Color textColor) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎨 Kişiselleştirme', style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          const Text('Ton'),
          Wrap(
            spacing: 8,
            children: ReminderTone.values.map((tone) {
              final selected = _tone == tone;
              return ChoiceChip(
                label: Text(_toneLabel(tone)),
                selected: selected,
                onSelected: (_) => setState(() => _tone = tone),
              );
            }).toList(),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).baglamEkle),
            subtitle: const Text("{location}'dasın, {title}"),
            value: _includeContext,
            onChanged: (v) => setState(() => _includeContext = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(bool isDark, Color textColor) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👥 Hedef Kişiler', style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          RadioListTile<TargetAudienceType>(
            title: const Text('Akıllı seçim (AI önerir)'),
            subtitle: Text(AppLocalizations.of(context).enYakinMusaitUygunYetkinlik),
            value: TargetAudienceType.smartSelect,
            groupValue: _targetType,
            onChanged: (v) => setState(() => _targetType = v!),
          ),
          RadioListTile<TargetAudienceType>(
            title: Text(AppLocalizations.of(context).manuelSecim),
            value: TargetAudienceType.group,
            groupValue: _targetType,
            onChanged: (v) => setState(() => _targetType = v!),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionStyle(Color textColor) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  String _locationTypeLabel(LocationTriggerType t) {
    switch (t) {
      case LocationTriggerType.enter:
        return 'Girince';
      case LocationTriggerType.exit:
        return 'Çıkınca';
      case LocationTriggerType.nearby:
        return 'Yaklaşınca';
      case LocationTriggerType.leaveHome:
        return 'Evden çıkınca';
      case LocationTriggerType.arriveWork:
        return 'İşe varınca';
    }
  }

  String _timeTypeLabel(TimeTriggerType t) {
    switch (t) {
      case TimeTriggerType.absolute:
        return 'Kesin zaman';
      case TimeTriggerType.relative:
        return 'Göreli zaman';
      case TimeTriggerType.recurring:
        return 'Tekrarlayan';
      case TimeTriggerType.smartSuggest:
        return 'Akıllı pencere';
    }
  }

  String _behaviorTypeLabel(BehaviorTriggerType t) {
    switch (t) {
      case BehaviorTriggerType.appOpen:
        return 'App açılınca';
      case BehaviorTriggerType.taskComplete:
        return 'Görev tamamlanınca';
      case BehaviorTriggerType.locationPattern:
        return 'Lokasyon pattern';
      case BehaviorTriggerType.inactivity:
        return 'Hareketsizlik';
      case BehaviorTriggerType.energyLevel:
        return 'Enerji seviyesi';
      case BehaviorTriggerType.socialContext:
        return 'Sosyal bağlam';
      case BehaviorTriggerType.weatherChange:
        return 'Hava değişimi';
      case BehaviorTriggerType.purchaseIntent:
        return 'Alışveriş niyeti';
    }
  }

  String _toneLabel(ReminderTone t) {
    switch (t) {
      case ReminderTone.formal:
        return 'Resmi';
      case ReminderTone.friendly:
        return 'Arkadaşça';
      case ReminderTone.urgent:
        return 'Acil';
      case ReminderTone.gentle:
        return 'Nazik';
    }
  }
}

// ── TEST PREVIEW SHEET ────────────────────────────────────────────────

class _TestPreviewSheet extends StatelessWidget {
  final String title;
  final String description;
  final ReminderTone tone;
  final bool includeContext;

  const _TestPreviewSheet({
    required this.title,
    required this.description,
    required this.tone,
    required this.includeContext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var displayTitle = title;
    var displayBody = description.isEmpty
        ? 'Hatırlatıcı açıklaması...'
        : description;

    if (includeContext) {
      displayBody += '\n(Şu an Kadıköy\'dasın)';
    }

    if (tone == ReminderTone.urgent) {
      displayTitle = '🔴 $displayTitle';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '📱 Bildirim Önizleme',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16213E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(51)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(displayBody, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(onPressed: () {}, child: const Text('✅ Tamam')),
                    TextButton(
                      onPressed: () {},
                      child: const Text('⏰ 10dk Ertele'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).close),
            ),
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE CARD WIDGET ──────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
