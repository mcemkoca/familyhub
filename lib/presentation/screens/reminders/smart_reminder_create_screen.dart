// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase_client.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/smart_reminder.dart';
import '../../../repositories/smart_reminder_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/smart_reminder_background_service.dart';
import 'package:familyhub/l10n/app_localizations.dart';

class SmartReminderCreateScreen extends StatefulWidget {
  const SmartReminderCreateScreen({super.key});

  @override
  State<SmartReminderCreateScreen> createState() =>
      _SmartReminderCreateScreenState();
}

class _SmartReminderCreateScreenState extends State<SmartReminderCreateScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Trigger states
  bool _locationEnabled = false;
  LocationTriggerType _locationType = LocationTriggerType.nearby;
  final _locationNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
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
    final reminderBody = AppLocalizations.of(context).srReminderBody;
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
    final profile = await SupabaseConfig.client
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
      final created = await SmartReminderRepository().create(reminder);
      // Schedule background notification
      final triggerTime = created.triggers.time.enabled
          ? created.triggers.time.absoluteTime
          : created.status.nextScheduled;
      if (triggerTime != null && triggerTime.isAfter(DateTime.now())) {
        await SmartReminderBackgroundService.scheduleReminder(
          id: created.id,
          when: triggerTime,
          title: created.title,
          body: created.description ?? reminderBody,
        );
      }
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
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).srError('$e'))));
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
            ? AppLocalizations.of(context).srTestReminder
            : _titleController.text,
        description: _descController.text,
        tone: _tone,
        includeContext: _includeContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFF0A0A0F),
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
          Text(AppLocalizations.of(context).srBasicInfo, style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).baslik,
              hintText: AppLocalizations.of(context).marketAlisverisi,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).description,
              hintText: AppLocalizations.of(context).sutVeEkmekAl,
              border: const OutlineInputBorder(),
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
            subtitle: Text(_locationEnabled ? AppLocalizations.of(context).commonActive : AppLocalizations.of(context).commonPassive),
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
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).tur),
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
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).yerAdi),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context).srLatitude),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).srLongitude,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).srGeofenceRadius(_radius.toInt())),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  Text(AppLocalizations.of(context).srProximity(_proximity.toInt())),
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
            subtitle: Text(_timeEnabled ? AppLocalizations.of(context).commonActive : AppLocalizations.of(context).commonPassive),
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
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).tur),
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
                      title: Text(AppLocalizations.of(context).srTime),
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
            subtitle: Text(_behaviorEnabled ? AppLocalizations.of(context).commonActive : AppLocalizations.of(context).commonPassive),
            value: _behaviorEnabled,
            onChanged: (v) => setState(() => _behaviorEnabled = v),
          ),
          if (_behaviorEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: DropdownButtonFormField<BehaviorTriggerType>(
                initialValue: _behaviorType,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).davranisTuru),
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
                    segments: [
                      ButtonSegment(
                        value: CompositeLogic.and_,
                        label: Text(AppLocalizations.of(context).srAnd),
                      ),
                      ButtonSegment(
                        value: CompositeLogic.or_,
                        label: Text(AppLocalizations.of(context).srOr),
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
          Text(AppLocalizations.of(context).baglamHassasiyeti, style: _sectionStyle(textColor)),
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
                Text(AppLocalizations.of(context).srInterruptibility(_interruptibility.toInt())),
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
          Text(AppLocalizations.of(context).kisisellestirme, style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).srTone),
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
          Text(AppLocalizations.of(context).hedefKisiler, style: _sectionStyle(textColor)),
          const SizedBox(height: 12),
          RadioListTile<TargetAudienceType>(
            title: Text(AppLocalizations.of(context).srSmartChoice),
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
        return AppLocalizations.of(context).srEnter;
      case LocationTriggerType.exit:
        return AppLocalizations.of(context).srExit;
      case LocationTriggerType.nearby:
        return AppLocalizations.of(context).srApproach;
      case LocationTriggerType.leaveHome:
        return AppLocalizations.of(context).srExitHome;
      case LocationTriggerType.arriveWork:
        return AppLocalizations.of(context).srArriveWork;
    }
  }

  String _timeTypeLabel(TimeTriggerType t) {
    switch (t) {
      case TimeTriggerType.absolute:
        return AppLocalizations.of(context).srExactTime;
      case TimeTriggerType.relative:
        return AppLocalizations.of(context).srRelativeTime;
      case TimeTriggerType.recurring:
        return AppLocalizations.of(context).srRecurring;
      case TimeTriggerType.smartSuggest:
        return AppLocalizations.of(context).srSmartWindow;
    }
  }

  String _behaviorTypeLabel(BehaviorTriggerType t) {
    switch (t) {
      case BehaviorTriggerType.appOpen:
        return AppLocalizations.of(context).srAppOpen;
      case BehaviorTriggerType.taskComplete:
        return AppLocalizations.of(context).srTaskDone;
      case BehaviorTriggerType.locationPattern:
        return AppLocalizations.of(context).srLocationPattern;
      case BehaviorTriggerType.inactivity:
        return AppLocalizations.of(context).srInactivity;
      case BehaviorTriggerType.energyLevel:
        return AppLocalizations.of(context).srEnergyLevel;
      case BehaviorTriggerType.socialContext:
        return AppLocalizations.of(context).srSocialContext;
      case BehaviorTriggerType.weatherChange:
        return AppLocalizations.of(context).srWeatherChange;
      case BehaviorTriggerType.purchaseIntent:
        return AppLocalizations.of(context).srShoppingIntent;
    }
  }

  String _toneLabel(ReminderTone t) {
    switch (t) {
      case ReminderTone.formal:
        return AppLocalizations.of(context).srToneFormal;
      case ReminderTone.friendly:
        return AppLocalizations.of(context).srToneFriendly;
      case ReminderTone.urgent:
        return AppLocalizations.of(context).srToneUrgent;
      case ReminderTone.gentle:
        return AppLocalizations.of(context).srToneGentle;
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
    var displayTitle = title;
    var displayBody = description.isEmpty
        ? 'Hatırlatıcı açıklaması...'
        : description;

    if (includeContext) {
      displayBody += '\n(Bulunduğun konuma göre uyarlanır)';
    }

    if (tone == ReminderTone.urgent) {
      displayTitle = '🔴 $displayTitle';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFE5E7EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          Text(AppLocalizations.of(context).bildirimOnizleme,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
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
        color: const Color(0xFFE5E7EB),
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
