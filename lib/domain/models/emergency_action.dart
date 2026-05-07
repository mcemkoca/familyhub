// lib/domain/models/emergency_action.dart
// Emergency auto-actions domain models

// ─────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────

enum EmergencyTriggerType {
  panicButton,
  voiceCommand,
  crashDetection,
  inactivityAlert,
  healthEmergency,
  manualSos,
  smartSuggestion,
  thirdParty,
}

enum EmergencySeverity { low, medium, high, critical, lifeThreatening }

enum EmergencyCategory {
  medical,
  accident,
  security,
  fire,
  naturalDisaster,
  other,
}

enum EmergencyState {
  triggered,
  confirming,
  active,
  escalating,
  resolved,
  falseAlarm,
  timeout,
}

enum MessageChannel { sms, push, whatsapp, telegram, email }

enum RecipientType { family, emergencyContacts, all, custom }

enum CallType { emergencyServices, familyMember, emergencyContact, custom }

enum EscalationAction { notify, call, alertServices, soundAlarm, lockdown }

// ─────────────────────────────────────────────
// EMERGENCY TRIGGER
// ─────────────────────────────────────────────

class EmergencyTrigger {
  final EmergencyTriggerType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double confidence;

  const EmergencyTrigger({
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.confidence = 1.0,
  });

  factory EmergencyTrigger.fromJson(Map<String, dynamic> json) =>
      EmergencyTrigger(
        type: EmergencyTriggerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EmergencyTriggerType.manualSos,
        ),
        timestamp:
            DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'confidence': confidence,
  };
}

// ─────────────────────────────────────────────
// EMERGENCY DETAILS
// ─────────────────────────────────────────────

class EmergencyDetails {
  final EmergencySeverity severity;
  final EmergencyCategory category;
  final String description;
  final bool isConfirmed;
  final String? confirmationMethod;

  const EmergencyDetails({
    required this.severity,
    required this.category,
    required this.description,
    this.isConfirmed = false,
    this.confirmationMethod,
  });

  factory EmergencyDetails.fromJson(Map<String, dynamic> json) =>
      EmergencyDetails(
        severity: EmergencySeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => EmergencySeverity.high,
        ),
        category: EmergencyCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => EmergencyCategory.other,
        ),
        description: json['description'] as String? ?? '',
        isConfirmed: json['isConfirmed'] as bool? ?? false,
        confirmationMethod: json['confirmationMethod'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'category': category.name,
    'description': description,
    'isConfirmed': isConfirmed,
    'confirmationMethod': confirmationMethod,
  };
}

// ─────────────────────────────────────────────
// LOCATION SHARE CONFIG
// ─────────────────────────────────────────────

class LocationShareConfig {
  final bool enabled;
  final List<String> recipients;
  final String frequency; // once, continuous, every_minute
  final int durationMinutes;
  final bool includeRoute;

  const LocationShareConfig({
    this.enabled = true,
    this.recipients = const [],
    this.frequency = 'continuous',
    this.durationMinutes = 30,
    this.includeRoute = true,
  });

  factory LocationShareConfig.fromJson(Map<String, dynamic> json) =>
      LocationShareConfig(
        enabled: json['enabled'] as bool? ?? true,
        recipients:
            (json['recipients'] as List<dynamic>?)?.cast<String>() ?? [],
        frequency: json['frequency'] as String? ?? 'continuous',
        durationMinutes: (json['duration'] as num?)?.toInt() ?? 30,
        includeRoute: json['includeRoute'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'recipients': recipients,
    'frequency': frequency,
    'duration': durationMinutes,
    'includeRoute': includeRoute,
  };
}

// ─────────────────────────────────────────────
// EMERGENCY MESSAGE CONFIG
// ─────────────────────────────────────────────

class EmergencyMessageConfig {
  final MessageChannel channel;
  final RecipientType recipientType;
  final List<String> customRecipients;
  final String templateId;
  final Map<String, String> variables;
  final int delaySeconds;
  final int retryCount;
  final int retryIntervalSeconds;

  const EmergencyMessageConfig({
    required this.channel,
    required this.recipientType,
    this.customRecipients = const [],
    this.templateId = 'default',
    this.variables = const {},
    this.delaySeconds = 0,
    this.retryCount = 3,
    this.retryIntervalSeconds = 10,
  });

  factory EmergencyMessageConfig.fromJson(Map<String, dynamic> json) =>
      EmergencyMessageConfig(
        channel: MessageChannel.values.firstWhere(
          (e) => e.name == json['channel'],
          orElse: () => MessageChannel.sms,
        ),
        recipientType: RecipientType.values.firstWhere(
          (e) => e.name == json['recipientType'],
          orElse: () => RecipientType.family,
        ),
        customRecipients:
            (json['customRecipients'] as List<dynamic>?)?.cast<String>() ?? [],
        templateId: json['template'] as String? ?? 'default',
        variables:
            (json['variables'] as Map<String, dynamic>?)
                ?.cast<String, String>() ??
            {},
        delaySeconds: (json['delay'] as num?)?.toInt() ?? 0,
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 3,
        retryIntervalSeconds: (json['retryInterval'] as num?)?.toInt() ?? 10,
      );

  Map<String, dynamic> toJson() => {
    'channel': channel.name,
    'recipientType': recipientType.name,
    'customRecipients': customRecipients,
    'template': templateId,
    'variables': variables,
    'delay': delaySeconds,
    'retryCount': retryCount,
    'retryInterval': retryIntervalSeconds,
  };
}

// ─────────────────────────────────────────────
// EMERGENCY CALL CONFIG
// ─────────────────────────────────────────────

class EmergencyCallConfig {
  final CallType type;
  final String target;
  final bool autoDial;
  final bool playMessage;
  final String? messageText;
  final int maxAttempts;

  const EmergencyCallConfig({
    required this.type,
    required this.target,
    this.autoDial = true,
    this.playMessage = true,
    this.messageText,
    this.maxAttempts = 3,
  });

  factory EmergencyCallConfig.fromJson(Map<String, dynamic> json) =>
      EmergencyCallConfig(
        type: CallType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CallType.emergencyContact,
        ),
        target: json['target'] as String? ?? '',
        autoDial: json['autoDial'] as bool? ?? true,
        playMessage: json['playMessage'] as bool? ?? true,
        messageText: json['messageText'] as String?,
        maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 3,
      );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'target': target,
    'autoDial': autoDial,
    'playMessage': playMessage,
    'messageText': messageText,
    'maxAttempts': maxAttempts,
  };
}

// ─────────────────────────────────────────────
// AUDIO RECORDING CONFIG
// ─────────────────────────────────────────────

class AudioRecordingConfig {
  final bool enabled;
  final int durationSeconds;
  final bool autoUpload;
  final List<String> triggerWords;

  const AudioRecordingConfig({
    this.enabled = true,
    this.durationSeconds = 300,
    this.autoUpload = true,
    this.triggerWords = const [],
  });

  factory AudioRecordingConfig.fromJson(Map<String, dynamic> json) =>
      AudioRecordingConfig(
        enabled: json['enabled'] as bool? ?? true,
        durationSeconds: (json['duration'] as num?)?.toInt() ?? 300,
        autoUpload: json['autoUpload'] as bool? ?? true,
        triggerWords:
            (json['triggerWords'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'duration': durationSeconds,
    'autoUpload': autoUpload,
    'triggerWords': triggerWords,
  };
}

// ─────────────────────────────────────────────
// SMART HOME ACTION
// ─────────────────────────────────────────────

class SmartHomeActionConfig {
  final String device;
  final String action;
  final int delaySeconds;

  const SmartHomeActionConfig({
    required this.device,
    required this.action,
    this.delaySeconds = 0,
  });

  factory SmartHomeActionConfig.fromJson(Map<String, dynamic> json) =>
      SmartHomeActionConfig(
        device: json['device'] as String? ?? '',
        action: json['action'] as String? ?? '',
        delaySeconds: (json['delay'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'device': device,
    'action': action,
    'delay': delaySeconds,
  };
}

// ─────────────────────────────────────────────
// COMMUNITY ALERT CONFIG
// ─────────────────────────────────────────────

class CommunityAlertConfig {
  final bool enabled;
  final List<String> platforms;
  final bool anonymous;

  const CommunityAlertConfig({
    this.enabled = false,
    this.platforms = const [],
    this.anonymous = true,
  });

  factory CommunityAlertConfig.fromJson(Map<String, dynamic> json) =>
      CommunityAlertConfig(
        enabled: json['enabled'] as bool? ?? false,
        platforms: (json['platforms'] as List<dynamic>?)?.cast<String>() ?? [],
        anonymous: json['anonymous'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'platforms': platforms,
    'anonymous': anonymous,
  };
}

// ─────────────────────────────────────────────
// AUTO ACTIONS
// ─────────────────────────────────────────────

class AutoActions {
  final LocationShareConfig locationShare;
  final List<EmergencyMessageConfig> messages;
  final List<EmergencyCallConfig> calls;
  final AudioRecordingConfig audioRecording;
  final List<SmartHomeActionConfig> smartHome;
  final CommunityAlertConfig communityAlert;

  const AutoActions({
    this.locationShare = const LocationShareConfig(),
    this.messages = const [],
    this.calls = const [],
    this.audioRecording = const AudioRecordingConfig(),
    this.smartHome = const [],
    this.communityAlert = const CommunityAlertConfig(),
  });

  factory AutoActions.fromJson(Map<String, dynamic> json) => AutoActions(
    locationShare: json['locationShare'] != null
        ? LocationShareConfig.fromJson(
            json['locationShare'] as Map<String, dynamic>,
          )
        : const LocationShareConfig(),
    messages:
        (json['messages'] as List<dynamic>?)
            ?.map(
              (e) => EmergencyMessageConfig.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    calls:
        (json['calls'] as List<dynamic>?)
            ?.map(
              (e) => EmergencyCallConfig.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    audioRecording: json['audioRecording'] != null
        ? AudioRecordingConfig.fromJson(
            json['audioRecording'] as Map<String, dynamic>,
          )
        : const AudioRecordingConfig(),
    smartHome:
        (json['smartHome'] as List<dynamic>?)
            ?.map(
              (e) => SmartHomeActionConfig.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    communityAlert: json['communityAlert'] != null
        ? CommunityAlertConfig.fromJson(
            json['communityAlert'] as Map<String, dynamic>,
          )
        : const CommunityAlertConfig(),
  );

  Map<String, dynamic> toJson() => {
    'locationShare': locationShare.toJson(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'calls': calls.map((c) => c.toJson()).toList(),
    'audioRecording': audioRecording.toJson(),
    'smartHome': smartHome.map((s) => s.toJson()).toList(),
    'communityAlert': communityAlert.toJson(),
  };
}

// ─────────────────────────────────────────────
// ESCALATION STEP
// ─────────────────────────────────────────────

class EscalationStep {
  final int order;
  final String name;
  final int delayMinutes;
  final EscalationAction action;
  final List<String> recipients;
  final String messageTemplate;
  final bool requireConfirmation;
  final String condition; // no_response, severity_increase, always

  const EscalationStep({
    required this.order,
    required this.name,
    required this.delayMinutes,
    required this.action,
    this.recipients = const [],
    this.messageTemplate = 'default',
    this.requireConfirmation = false,
    this.condition = 'always',
  });

  factory EscalationStep.fromJson(Map<String, dynamic> json) => EscalationStep(
    order: (json['order'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    delayMinutes: (json['delay'] as num?)?.toInt() ?? 0,
    action: EscalationAction.values.firstWhere(
      (e) => e.name == json['action'],
      orElse: () => EscalationAction.notify,
    ),
    recipients: (json['recipients'] as List<dynamic>?)?.cast<String>() ?? [],
    messageTemplate: json['messageTemplate'] as String? ?? 'default',
    requireConfirmation: json['requireConfirmation'] as bool? ?? false,
    condition: json['condition'] as String? ?? 'always',
  );

  Map<String, dynamic> toJson() => {
    'order': order,
    'name': name,
    'delay': delayMinutes,
    'action': action.name,
    'recipients': recipients,
    'messageTemplate': messageTemplate,
    'requireConfirmation': requireConfirmation,
    'condition': condition,
  };
}

// ─────────────────────────────────────────────
// ESCALATION CHAIN
// ─────────────────────────────────────────────

class EscalationChain {
  final List<EscalationStep> steps;

  const EscalationChain({this.steps = const []});

  factory EscalationChain.fromJson(Map<String, dynamic> json) =>
      EscalationChain(
        steps:
            (json['steps'] as List<dynamic>?)
                ?.map((e) => EscalationStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────
// EMERGENCY STATUS
// ─────────────────────────────────────────────

class EmergencyStatus {
  EmergencyState state;
  int currentStep;
  final DateTime startedAt;
  DateTime? lastActionAt;
  DateTime? resolvedAt;
  String? resolvedBy;

  EmergencyStatus({
    this.state = EmergencyState.triggered,
    this.currentStep = 0,
    required this.startedAt,
    this.lastActionAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory EmergencyStatus.fromJson(Map<String, dynamic> json) =>
      EmergencyStatus(
        state: EmergencyState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => EmergencyState.triggered,
        ),
        currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
        startedAt:
            DateTime.tryParse(json['startedAt'] as String) ?? DateTime.now(),
        lastActionAt: json['lastActionAt'] != null
            ? DateTime.tryParse(json['lastActionAt'] as String)
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'] as String)
            : null,
        resolvedBy: json['resolvedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'currentStep': currentStep,
    'startedAt': startedAt.toIso8601String(),
    'lastActionAt': lastActionAt?.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolvedBy': resolvedBy,
  };
}

// ─────────────────────────────────────────────
// RESPONSE LOG ENTRY
// ─────────────────────────────────────────────

class ResponseLogEntry {
  final DateTime timestamp;
  final String action;
  final String channel;
  final String recipient;
  final String status; // sent, delivered, read, failed, no_response
  final String? response;

  const ResponseLogEntry({
    required this.timestamp,
    required this.action,
    required this.channel,
    required this.recipient,
    this.status = 'sent',
    this.response,
  });

  factory ResponseLogEntry.fromJson(Map<String, dynamic> json) =>
      ResponseLogEntry(
        timestamp:
            DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now(),
        action: json['action'] as String? ?? '',
        channel: json['channel'] as String? ?? '',
        recipient: json['recipient'] as String? ?? '',
        status: json['status'] as String? ?? 'sent',
        response: json['response'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'action': action,
    'channel': channel,
    'recipient': recipient,
    'status': status,
    'response': response,
  };
}

// ─────────────────────────────────────────────
// MAIN EMERGENCY ACTION
// ─────────────────────────────────────────────

class EmergencyAction {
  String? actionId;
  final String familyId;
  final String triggeredBy;
  final EmergencyTrigger trigger;
  final EmergencyDetails emergency;
  final AutoActions autoActions;
  final EscalationChain escalationChain;
  final EmergencyStatus status;
  final List<ResponseLogEntry> responseLog;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyAction({
    this.actionId,
    required this.familyId,
    required this.triggeredBy,
    required this.trigger,
    required this.emergency,
    required this.autoActions,
    required this.escalationChain,
    required this.status,
    this.responseLog = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyAction.fromJson(
    Map<String, dynamic> json,
  ) => EmergencyAction(
    actionId: json['actionId'] as String?,
    familyId: json['familyId'] as String? ?? '',
    triggeredBy: json['triggeredBy'] as String? ?? '',
    trigger: EmergencyTrigger.fromJson(json['trigger'] as Map<String, dynamic>),
    emergency: EmergencyDetails.fromJson(
      json['emergency'] as Map<String, dynamic>,
    ),
    autoActions: AutoActions.fromJson(
      json['autoActions'] as Map<String, dynamic>,
    ),
    escalationChain: EscalationChain.fromJson(
      json['escalationChain'] as Map<String, dynamic>,
    ),
    status: EmergencyStatus.fromJson(json['status'] as Map<String, dynamic>),
    responseLog:
        (json['responseLog'] as List<dynamic>?)
            ?.map((e) => ResponseLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'actionId': actionId,
    'familyId': familyId,
    'triggeredBy': triggeredBy,
    'trigger': trigger.toJson(),
    'emergency': emergency.toJson(),
    'autoActions': autoActions.toJson(),
    'escalationChain': escalationChain.toJson(),
    'status': status.toJson(),
    'responseLog': responseLog.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool get isActive =>
      status.state == EmergencyState.triggered ||
      status.state == EmergencyState.active ||
      status.state == EmergencyState.escalating;
}
