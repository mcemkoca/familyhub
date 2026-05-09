// lib/repositories/emergency_action_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/utils/repository_mixin.dart';

import '../domain/models/emergency_action.dart';
import '../domain/models/emergency_template.dart';

class EmergencyActionRepository with RepositoryErrorHandler {
  static final EmergencyActionRepository _instance =
      EmergencyActionRepository._internal();
  factory EmergencyActionRepository() => _instance;
  EmergencyActionRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  // ── Emergency Actions ──
  Future<List<EmergencyAction>> getFamilyActions(
    String familyId, {
    int limit = 50,
  }) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('emergency_actions')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => EmergencyAction.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getFamilyActions');
  }

  Future<List<EmergencyAction>> getActiveActions(String familyId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('emergency_actions')
          .select()
          .eq('family_id', familyId)
          .inFilter('status_state', ['triggered', 'active', 'escalating'])
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => EmergencyAction.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getActiveActions');
  }

  Future<String> createAction(EmergencyAction action) async {
    return handleRepositoryCall(() async {
      final data = action.toJson()..remove('actionId');
      final res = await _client
          .from('emergency_actions')
          .insert(data)
          .select('id')
          .single();
      return res['id'] as String;
    }, 'createAction');
  }

  Future<void> updateAction(EmergencyAction action) async {
    return handleRepositoryCall(() async {
      if (action.actionId == null) return;
      await _client
          .from('emergency_actions')
          .update(action.toJson())
          .eq('id', action.actionId!);
    }, 'updateAction');
  }

  // ── Templates ──
  Future<List<EmergencyTemplate>> getTemplates() async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('emergency_templates')
          .select()
          .order('usage_count', ascending: false);
      return (res as List)
          .map((e) => EmergencyTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getTemplates');
  }

  Future<EmergencyTemplate?> getTemplateById(String templateId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('emergency_templates')
          .select()
          .eq('template_id', templateId)
          .maybeSingle();
      if (res == null) return null;
      return EmergencyTemplate.fromJson(res);
    }, 'getTemplateById');
  }

  // ── Contacts ──
  Future<List<EmergencyContactModel>> getFamilyContacts(String familyId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('emergency_contacts')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true)
          .order('priority', ascending: true);
      return (res as List)
          .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }, 'getFamilyContacts');
  }

  // ── Policies ──
  Future<EscalationPolicy?> getFamilyPolicy(String familyId) async {
    return handleRepositoryCall(() async {
      final res = await _client
          .from('escalation_policies')
          .select()
          .eq('family_id', familyId)
          .maybeSingle();
      if (res == null) return null;
      return EscalationPolicy.fromJson(res);
    }, 'getFamilyPolicy');
  }
}
