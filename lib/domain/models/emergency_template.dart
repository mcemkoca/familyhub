// lib/domain/models/emergency_template.dart
// Emergency message templates and contacts

import 'emergency_action.dart';

// ─────────────────────────────────────────────
// EMERGENCY TEMPLATE
// ─────────────────────────────────────────────

class EmergencyTemplate {
  final String templateId;
  final String name;
  final String language;
  final String smsContent;
  final String pushContent;
  final String pushTitle;
  final String voiceContent;
  final String emailContent;
  final List<TemplateVariable> variables;
  final int usageCount;
  final double? averageResponseTime;

  const EmergencyTemplate({
    required this.templateId,
    required this.name,
    this.language = 'tr',
    required this.smsContent,
    required this.pushContent,
    this.pushTitle = '🆘 ACİL DURUM',
    required this.voiceContent,
    required this.emailContent,
    this.variables = const [],
    this.usageCount = 0,
    this.averageResponseTime,
  });

  factory EmergencyTemplate.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>?;
    return EmergencyTemplate(
      templateId: json['templateId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      language: json['language'] as String? ?? 'tr',
      smsContent: content?['sms'] as String? ?? '',
      pushContent: content?['push'] as String? ?? '',
      pushTitle: content?['pushTitle'] as String? ?? '🆘 ACİL DURUM',
      voiceContent: content?['voice'] as String? ?? '',
      emailContent: content?['email'] as String? ?? '',
      variables: (json['variables'] as List<dynamic>?)
              ?.map((e) => TemplateVariable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'name': name,
        'language': language,
        'content': {
          'sms': smsContent,
          'push': pushContent,
          'pushTitle': pushTitle,
          'voice': voiceContent,
          'email': emailContent,
        },
        'variables': variables.map((v) => v.toJson()).toList(),
        'usageCount': usageCount,
        'averageResponseTime': averageResponseTime,
      };
}

class TemplateVariable {
  final String name;
  final String source; // user_profile, location, time, health_card, custom
  final bool required;

  const TemplateVariable({
    required this.name,
    required this.source,
    this.required = true,
  });

  factory TemplateVariable.fromJson(Map<String, dynamic> json) =>
      TemplateVariable(
        name: json['name'] as String? ?? '',
        source: json['source'] as String? ?? 'custom',
        required: json['required'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'source': source,
        'required': required,
      };
}

// ─────────────────────────────────────────────
// EMERGENCY CONTACT
// ─────────────────────────────────────────────

class EmergencyContactModel {
  final String contactId;
  final String familyId;
  final String name;
  final String phone;
  final String? email;
  final String relation;
  final int priority;
  final String? timezone;
  final String? preferredHours;
  final bool alwaysAvailable;
  final bool canReceiveSMS;
  final bool canReceivePush;
  final bool canReceiveCall;
  final bool canAccessLocation;
  final bool canAccessHealthData;
  final List<ContactRole> roles;
  final bool isActive;
  final DateTime? verifiedAt;

  const EmergencyContactModel({
    required this.contactId,
    required this.familyId,
    required this.name,
    required this.phone,
    this.email,
    required this.relation,
    this.priority = 1,
    this.timezone,
    this.preferredHours,
    this.alwaysAvailable = true,
    this.canReceiveSMS = true,
    this.canReceivePush = true,
    this.canReceiveCall = true,
    this.canAccessLocation = true,
    this.canAccessHealthData = false,
    this.roles = const [],
    this.isActive = true,
    this.verifiedAt,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) =>
      EmergencyContactModel(
        contactId: json['contactId'] as String? ?? '',
        familyId: json['familyId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        relation: json['relation'] as String? ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 1,
        timezone: (json['availability'] as Map<String, dynamic>?)?['timezone'] as String?,
        preferredHours: (json['availability'] as Map<String, dynamic>?)?['preferredHours'] as String?,
        alwaysAvailable:
            (json['availability'] as Map<String, dynamic>?)?['alwaysAvailable'] as bool? ?? true,
        canReceiveSMS: (json['capabilities'] as Map<String, dynamic>?)?['canReceiveSMS'] as bool? ?? true,
        canReceivePush: (json['capabilities'] as Map<String, dynamic>?)?['canReceivePush'] as bool? ?? true,
        canReceiveCall: (json['capabilities'] as Map<String, dynamic>?)?['canReceiveCall'] as bool? ?? true,
        canAccessLocation:
            (json['capabilities'] as Map<String, dynamic>?)?['canAccessLocation'] as bool? ?? true,
        canAccessHealthData:
            (json['capabilities'] as Map<String, dynamic>?)?['canAccessHealthData'] as bool? ?? false,
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => ContactRole.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.tryParse(json['verifiedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'contactId': contactId,
        'familyId': familyId,
        'name': name,
        'phone': phone,
        'email': email,
        'relation': relation,
        'priority': priority,
        'availability': {
          'timezone': timezone,
          'preferredHours': preferredHours,
          'alwaysAvailable': alwaysAvailable,
        },
        'capabilities': {
          'canReceiveSMS': canReceiveSMS,
          'canReceivePush': canReceivePush,
          'canReceiveCall': canReceiveCall,
          'canAccessLocation': canAccessLocation,
          'canAccessHealthData': canAccessHealthData,
        },
        'roles': roles.map((r) => r.toJson()).toList(),
        'isActive': isActive,
        'verifiedAt': verifiedAt?.toIso8601String(),
      };
}

class ContactRole {
  final String type; // primary, secondary, backup, medical, legal
  final List<String> conditions;

  const ContactRole({
    required this.type,
    this.conditions = const [],
  });

  factory ContactRole.fromJson(Map<String, dynamic> json) => ContactRole(
        type: json['type'] as String? ?? '',
        conditions:
            (json['conditions'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'conditions': conditions,
      };
}

// ─────────────────────────────────────────────
// ESCALATION POLICY
// ─────────────────────────────────────────────

class EscalationPolicy {
  final String policyId;
  final String familyId;
  final String name;
  final List<PolicyTrigger> triggers;
  final List<PolicyStep> steps;
  final PolicyConditions conditions;

  const EscalationPolicy({
    required this.policyId,
    required this.familyId,
    required this.name,
    this.triggers = const [],
    this.steps = const [],
    this.conditions = const PolicyConditions(),
  });

  factory EscalationPolicy.fromJson(Map<String, dynamic> json) =>
      EscalationPolicy(
        policyId: json['policyId'] as String? ?? '',
        familyId: json['familyId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        triggers: (json['triggers'] as List<dynamic>?)
                ?.map((e) => PolicyTrigger.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => PolicyStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        conditions: json['conditions'] != null
            ? PolicyConditions.fromJson(
                json['conditions'] as Map<String, dynamic>)
            : const PolicyConditions(),
      );

  Map<String, dynamic> toJson() => {
        'policyId': policyId,
        'familyId': familyId,
        'name': name,
        'triggers': triggers.map((t) => t.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'conditions': conditions.toJson(),
      };
}

class PolicyTrigger {
  final String type; // no_response, severity_increase, time_elapsed, location_change
  final double threshold;

  const PolicyTrigger({
    required this.type,
    required this.threshold,
  });

  factory PolicyTrigger.fromJson(Map<String, dynamic> json) => PolicyTrigger(
        type: json['type'] as String? ?? '',
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'threshold': threshold,
      };
}

class PolicyStep {
  final int order;
  final String name;
  final int delayMinutes;
  final EscalationAction action;
  final List<String> recipients;
  final String messageTemplate;
  final bool requireConfirmation;

  const PolicyStep({
    required this.order,
    required this.name,
    required this.delayMinutes,
    required this.action,
    this.recipients = const [],
    this.messageTemplate = 'default',
    this.requireConfirmation = false,
  });

  factory PolicyStep.fromJson(Map<String, dynamic> json) => PolicyStep(
        order: (json['order'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        delayMinutes: (json['delay'] as num?)?.toInt() ?? 0,
        action: EscalationAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => EscalationAction.notify,
        ),
        recipients:
            (json['recipients'] as List<dynamic>?)?.cast<String>() ?? [],
        messageTemplate: json['messageTemplate'] as String? ?? 'default',
        requireConfirmation: json['requireConfirmation'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'name': name,
        'delay': delayMinutes,
        'action': action.name,
        'recipients': recipients,
        'messageTemplate': messageTemplate,
        'requireConfirmation': requireConfirmation,
      };
}

class PolicyConditions {
  final String timeOfDay; // any, day, night
  final String location; // any, home, away, work
  final String memberStatus; // any, alone, with_family

  const PolicyConditions({
    this.timeOfDay = 'any',
    this.location = 'any',
    this.memberStatus = 'any',
  });

  factory PolicyConditions.fromJson(Map<String, dynamic> json) =>
      PolicyConditions(
        timeOfDay: json['timeOfDay'] as String? ?? 'any',
        location: json['location'] as String? ?? 'any',
        memberStatus: json['memberStatus'] as String? ?? 'any',
      );

  Map<String, dynamic> toJson() => {
        'timeOfDay': timeOfDay,
        'location': location,
        'memberStatus': memberStatus,
      };
}
