// lib/services/emergency_auto_actions_engine.dart
// Emergency auto-actions engine: triggers, messages, calls, escalation chain

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../domain/models/emergency_action.dart';
import '../domain/models/emergency_template.dart';
import '../repositories/emergency_action_repository.dart';
import 'localization/locale_service.dart';

/// High-level engine that orchestrates the entire emergency response pipeline.
class EmergencyAutoActionsEngine {
  static final EmergencyAutoActionsEngine _instance =
      EmergencyAutoActionsEngine._internal();
  factory EmergencyAutoActionsEngine() => _instance;
  EmergencyAutoActionsEngine._internal();

  String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

  String get _helpCall => _text(const {
        'tr': 'Acil durum yardım çağrısı',
        'en': 'Emergency assistance request',
        'nl': 'Noodoproep',
        'fr': 'Demande d’aide d’urgence',
      });

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();

  // ── Active action ──
  EmergencyAction? _activeAction;
  EmergencyAction? get activeAction => _activeAction;

  // ── Streams ──
  final _statusController = StreamController<EmergencyAction>.broadcast();
  Stream<EmergencyAction> get statusStream => _statusController.stream;

  // ── Timers ──
  Timer? _escalationTimer;
  Timer? _locationShareTimer;

  // ── Callbacks ──
  VoidCallback? onSOSStarted;
  VoidCallback? onSOSResolved;

  // ═══════════════════════════════════════════
  // TRIGGER SOS
  // ═══════════════════════════════════════════
  Future<EmergencyAction> triggerSOS({
    required String triggeredBy,
    required String triggerType,
    String? description,
    EmergencySeverity initialSeverity = EmergencySeverity.high,
    EmergencyCategory category = EmergencyCategory.other,
  }) async {
    // 1. Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 8)),
      );
    } catch (e) {
      // ignore: empty_catches
    }

    // 1b. Resolve family_id (aileye realtime ulaşması için gerekli)
    final familyId = await _resolveFamilyId();

    // 2. Build action
    final now = DateTime.now();
    final action = EmergencyAction(
      familyId: familyId ?? '',
      triggeredBy: triggeredBy,
      trigger: EmergencyTrigger(
        type: EmergencyTriggerType.values.firstWhere(
          (e) => e.name == triggerType,
          orElse: () => EmergencyTriggerType.manualSos,
        ),
        timestamp: now,
        latitude: position?.latitude,
        longitude: position?.longitude,
      ),
      emergency: EmergencyDetails(
        severity: initialSeverity,
        category: category,
        description: description ?? _helpCall,
      ),
      autoActions: const AutoActions(),
      escalationChain: const EscalationChain(),
      status: EmergencyStatus(startedAt: now),
      createdAt: now,
      updatedAt: now,
    );

    _activeAction = action;
    _statusController.add(action);
    onSOSStarted?.call();

    // 2b. Buluta yaz + aileye anlık push — best-effort (çevrimdışıysa akış sürer).
    //     Aile üyeleri emergency_actions'a realtime abone olduğunda anında görür.
    if (familyId != null && familyId.isNotEmpty) {
      unawaited(_broadcastToFamily(action, description ?? _helpCall));
    }

    // 3. Execute auto actions
    await _executeAutoActions(action);

    // 4. Start escalation chain
    await _startEscalationChain(action);

    return action;
  }

  // ═══════════════════════════════════════════
  // AUTO ACTIONS
  // ═══════════════════════════════════════════
  Future<void> _executeAutoActions(EmergencyAction action) async {
    final auto = action.autoActions;

    // A. Location share
    if (auto.locationShare.enabled) {
      await _startLocationSharing(action);
    }

    // B. Messages (parallel)
    final futures = <Future<void>>[];
    for (final msg in auto.messages) {
      futures.add(_sendMessage(action, msg));
    }
    await Future.wait(futures, eagerError: false);

    // C. Calls (sequential)
    for (final call in auto.calls) {
      await _executeCall(action, call);
    }

    // D. Audio recording
    if (auto.audioRecording.enabled) {
      await _startAudioRecording(action);
    }

    action.status.state = EmergencyState.active;
    action.status.lastActionAt = DateTime.now();
    _statusController.add(action);
  }

  // ═══════════════════════════════════════════
  // LOCATION SHARING
  // ═══════════════════════════════════════════
  Future<void> _startLocationSharing(EmergencyAction action) async {
    final config = action.autoActions.locationShare;

    // Immediate share
    await _shareLocationOnce(action, isInitial: true);

    // Continuous sharing
    if (config.frequency == 'continuous' ||
        config.frequency == 'every_minute') {
      final interval = config.frequency == 'every_minute'
          ? const Duration(minutes: 1)
          : const Duration(seconds: 30);

      final endTime = config.durationMinutes > 0
          ? DateTime.now().add(Duration(minutes: config.durationMinutes))
          : null;

      _locationShareTimer?.cancel();
      _locationShareTimer = Timer.periodic(interval, (timer) async {
        if (endTime != null && DateTime.now().isAfter(endTime)) {
          timer.cancel();
          return;
        }
        if (!_isActive(action)) {
          timer.cancel();
          return;
        }
        await _shareLocationOnce(action, isInitial: false);
      });
    }
  }

  Future<void> _shareLocationOnce(
    EmergencyAction action, {
    required bool isInitial,
  }) async {
    try {
      // ignore: unused_local_variable
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 8)),
      );
    } catch (e) {
      // ignore: empty_catches
    }
  }

  // ═══════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════
  Future<void> _sendMessage(
    EmergencyAction action,
    EmergencyMessageConfig config,
  ) async {
    if (config.delaySeconds > 0) {
      await Future.delayed(Duration(seconds: config.delaySeconds));
    }

    final template = await _getTemplate(config.templateId);
    final messageText = _resolveTemplate(template.smsContent, {
      'name': _text(const {'tr': 'Kullanıcı', 'en': 'User', 'nl': 'Gebruiker', 'fr': 'Utilisateur'}),
      'location':
          '${action.trigger.latitude ?? 0}, ${action.trigger.longitude ?? 0}',
      'time': _fmtTime(action.trigger.timestamp),
    });

    switch (config.channel) {
      case MessageChannel.sms:
        await _sendSms(_getRecipientTarget(config), messageText);
        break;
      case MessageChannel.push:
        await _sendFcmPush(messageText);
        break;
      case MessageChannel.whatsapp:
        await _sendWhatsApp(_getRecipientTarget(config), messageText);
        break;
      case MessageChannel.telegram:
      case MessageChannel.email:
        await _sendEmail(_getRecipientTarget(config), messageText);
        break;
    }

    _logResponse(
      action,
      'message',
      config.channel.name,
      config.recipientType.name,
      'sent',
    );
  }

  Future<void> _sendSms(String number, String message) async {
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'sms', path: number, queryParameters: {'body': message});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp(String number, String message) async {
    if (number.isEmpty) return;
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email, String message) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {
      'subject': _helpCall,
      'body': message,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Giriş yapan kullanıcının family_id'sini profiles'tan çözer.
  Future<String?> _resolveFamilyId() async {
    try {
      final client = SupabaseConfig.safeClient;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) return null;
      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      return profile?['family_id'] as String?;
    } catch (e) {
      debugPrint('[Emergency] family_id çözülemedi: $e');
      return null;
    }
  }

  /// SOS'u emergency_actions tablosuna yazar (aile realtime görür) + FCM push.
  Future<void> _broadcastToFamily(EmergencyAction action, String message) async {
    try {
      final id = await EmergencyActionRepository().createAction(action);
      action.actionId = id;
    } catch (e) {
      debugPrint('[Emergency] bulut kaydı başarısız: $e');
    }
    await _sendFcmPush(message);
  }

  Future<void> _sendFcmPush(String message) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;

      // Get FCM tokens of all family members via Supabase Edge Function
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      final familyId = profile?['family_id'] as String?;
      if (familyId == null) return;

      // Call Supabase Edge Function to send FCM to all family members
      await client.functions.invoke('send-emergency-push', body: {
        'family_id': familyId,
        'sender_id': userId,
        'message': message,
        'title': _text(const {'tr': '🆘 ACİL DURUM', 'en': '🆘 EMERGENCY', 'nl': '🆘 NOODGEVAL', 'fr': '🆘 URGENCE'}),
      });
    } catch (e) {
      debugPrint('[Emergency] FCM push failed: $e');
    }
  }

  String _getRecipientTarget(EmergencyMessageConfig config) {
    if (config.customRecipients.isNotEmpty) {
      return config.customRecipients.first;
    }
    return '';
  }

  // ═══════════════════════════════════════════
  // EXECUTE CALL
  // ═══════════════════════════════════════════
  Future<void> _executeCall(
    EmergencyAction action,
    EmergencyCallConfig config,
  ) async {
    String number;
    switch (config.type) {
      case CallType.emergencyServices:
        number = '112';
        break;
      case CallType.familyMember:
      case CallType.emergencyContact:
      case CallType.custom:
        number = config.target;
        break;
    }

    if (config.autoDial) {
      await _autoDial(
        number,
        config.messageText ?? _helpCall,
      );
    } else {
      // Prepare manual call UI
    }
  }

  Future<void> _autoDial(String number, String message) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    // Wait for connection then speak
    await Future.delayed(const Duration(seconds: 5));
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(1.0);
    await _tts.setLanguage(switch (_languageCode) {
      'en' => 'en-GB', 'nl' => 'nl-NL', 'fr' => 'fr-FR', _ => 'tr-TR',
    });
    await _tts.speak(message);
  }

  // ═══════════════════════════════════════════
  // AUDIO RECORDING
  // ═══════════════════════════════════════════
  Future<void> _startAudioRecording(EmergencyAction action) async {
    final durationSeconds = action.autoActions.audioRecording.durationSeconds;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/emergency_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );

      await Future.delayed(Duration(seconds: durationSeconds));

      if (await _recorder.isRecording()) {
        final recordedPath = await _recorder.stop();
        if (recordedPath != null) {
          await _uploadEmergencyRecording(recordedPath, action);
        }
      }
    } catch (e) {
      debugPrint('[Emergency] Audio recording failed: $e');
    }
  }

  Future<void> _uploadEmergencyRecording(String filePath, EmergencyAction action) async {
    try {
      final client = SupabaseConfig.safeClient;
      if (client == null) return;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final bytes = await File(filePath).readAsBytes();
      final fileName = 'emergency_${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await client.storage.from('emergency-recordings').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'audio/mp4'),
      );
    } catch (e) {
      debugPrint('[Emergency] Recording upload failed: $e');
    }
  }

  // ═══════════════════════════════════════════
  // ESCALATION CHAIN
  // ═══════════════════════════════════════════
  Future<void> _startEscalationChain(EmergencyAction action) async {
    final steps = action.escalationChain.steps;
    if (steps.isEmpty) return;

    for (final step in steps) {
      if (!_isActive(action)) return;

      // Wait for delay
      await Future.delayed(Duration(minutes: step.delayMinutes));
      if (!_isActive(action)) return;

      // Check condition
      final shouldExecute = await _checkEscalationCondition(
        action,
        step.condition,
      );
      if (!shouldExecute) continue;

      // Execute step
      await _executeEscalationStep(action, step);
      action.status.currentStep = step.order;
      action.status.state = EmergencyState.escalating;
      action.status.lastActionAt = DateTime.now();
      _statusController.add(action);

      // Check for user response
      if (step.requireConfirmation && _checkUserResponse(action)) {
        await resolve(action.actionId!, 'user_responded');
        return;
      }
    }

    // Chain completed without resolution
    if (_isActive(action)) {
      await resolve(action.actionId!, 'timeout');
    }
  }

  Future<bool> _checkEscalationCondition(
    EmergencyAction action,
    String condition,
  ) async {
    switch (condition) {
      case 'no_response':
        return !_checkUserResponse(action);
      case 'always':
        return true;
      default:
        return true;
    }
  }

  Future<void> _executeEscalationStep(
    EmergencyAction action,
    EscalationStep step,
  ) async {
    switch (step.action) {
      case EscalationAction.notify:
        // Send notification to configured recipients
        for (final msg in action.autoActions.messages) {
          await _sendMessage(action, msg);
        }
        break;
      case EscalationAction.call:
        // Auto-dial emergency number
        final number = step.recipients.isNotEmpty ? step.recipients.first : '112';
        await _autoDial(number, _helpCall);
        break;
      case EscalationAction.alertServices:
        // Alert emergency services (112)
        await _autoDial('112', _helpCall);
        break;
      case EscalationAction.soundAlarm:
        // Sound alarm is handled by CrashDetectionService
        break;
      case EscalationAction.lockdown:
        // Lockdown is app-level security action
        break;
    }
  }

  // ═══════════════════════════════════════════
  // USER RESPONSES
  // ═══════════════════════════════════════════
  Future<void> resolve(String actionId, String resolvedBy) async {
    if (_activeAction?.actionId == actionId) {
      _activeAction!.status.state = EmergencyState.resolved;
      _activeAction!.status.resolvedAt = DateTime.now();
      _activeAction!.status.resolvedBy = resolvedBy;
      _statusController.add(_activeAction!);
      onSOSResolved?.call();
      _cleanup();
    }
  }

  Future<void> cancelAsFalseAlarm(String actionId) async {
    if (_activeAction?.actionId == actionId) {
      _activeAction!.status.state = EmergencyState.falseAlarm;
      _activeAction!.status.resolvedAt = DateTime.now();
      _statusController.add(_activeAction!);
      onSOSResolved?.call();
      _cleanup();
    }
  }

  void _cleanup() {
    _escalationTimer?.cancel();
    _locationShareTimer?.cancel();
    _activeAction = null;
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  bool _isActive(EmergencyAction action) {
    return action.status.state == EmergencyState.triggered ||
        action.status.state == EmergencyState.active ||
        action.status.state == EmergencyState.escalating;
  }

  bool _checkUserResponse(EmergencyAction action) {
    // In real implementation, check response_log for user responses
    return false;
  }

  EmergencyTemplate get _defaultTemplate => EmergencyTemplate(
    templateId: 'default',
    name: _text(const {'tr': 'Varsayılan', 'en': 'Default', 'nl': 'Standaard', 'fr': 'Par défaut'}),
    smsContent: _text(const {
      'tr': '🆘 ACİL: {name} yardım istiyor! Konum: {location} Saat: {time}',
      'en': '🆘 EMERGENCY: {name} needs help! Location: {location} Time: {time}',
      'nl': '🆘 NOODGEVAL: {name} heeft hulp nodig! Locatie: {location} Tijd: {time}',
      'fr': '🆘 URGENCE : {name} demande de l’aide ! Position : {location} Heure : {time}',
    }),
    pushContent: _text(const {
      'tr': 'Yardım çağrısı! Konum: {location}', 'en': 'Help request! Location: {location}',
      'nl': 'Hulpverzoek! Locatie: {location}', 'fr': 'Demande d’aide ! Position : {location}',
    }),
    voiceContent: _text(const {
      'tr': 'Bu otomatik bir acil durum çağrısıdır. {name} yardım istiyor.',
      'en': 'This is an automated emergency call. {name} needs help.',
      'nl': 'Dit is een automatische noodoproep. {name} heeft hulp nodig.',
      'fr': 'Ceci est un appel d’urgence automatique. {name} demande de l’aide.',
    }),
    emailContent: _text(const {
      'tr': 'Acil durum yardım çağrısı. {name} konum: {location}',
      'en': 'Emergency assistance request. {name}, location: {location}',
      'nl': 'Noodoproep. {name}, locatie: {location}',
      'fr': 'Demande d’aide d’urgence. {name}, position : {location}',
    }),
  );

  Future<EmergencyTemplate> _getTemplate(String templateId) async {
    try {
      final template = await EmergencyActionRepository().getTemplateById(templateId);
      return template ?? _defaultTemplate;
    } catch (_) {
      return _defaultTemplate;
    }
  }

  String _resolveTemplate(String template, Map<String, String> vars) {
    var result = template;
    vars.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  String _fmtTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _logResponse(
    EmergencyAction action,
    String actionType,
    String channel,
    String recipient,
    String status,
  ) {
    action.responseLog.add(ResponseLogEntry(
      timestamp: DateTime.now(),
      action: actionType,
      channel: channel,
      recipient: recipient,
      status: status,
    ));
  }

  void dispose() {
    _cleanup();
    _statusController.close();
  }
}
