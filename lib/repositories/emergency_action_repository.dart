// lib/repositories/emergency_action_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

import '../domain/models/emergency_action.dart';
import '../domain/models/emergency_template.dart';

class EmergencyActionRepository {
  static final EmergencyActionRepository _instance = EmergencyActionRepository._internal();
  factory EmergencyActionRepository() => _instance;
  EmergencyActionRepository._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  // ── Emergency Actions ──
  Future<List<EmergencyAction>> getFamilyActions(String familyId, {int limit = 50}) async {
    try {
      final res = await _client
          .from('emergency_actions')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((e) => EmergencyAction.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getFamilyActions] error: $e');
      rethrow;
    }
  }

  Future<List<EmergencyAction>> getActiveActions(String familyId) async {
    try {
      final res = await _client
          .from('emergency_actions')
          .select()
          .eq('family_id', familyId)
          .inFilter('status_state', ['triggered', 'active', 'escalating'])
          .order('created_at', ascending: false);
      return (res as List).map((e) => EmergencyAction.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getActiveActions] error: $e');
      rethrow;
    }
  }

  Future<String> createAction(EmergencyAction action) async {
    try {
      final data = action.toJson()..remove('actionId');
      final res = await _client.from('emergency_actions').insert(data).select('id').single();
      return res['id'] as String;
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.createAction] error: $e');
      rethrow;
    }
  }

  Future<void> updateAction(EmergencyAction action) async {
    try {
      if (action.actionId == null) return;
      await _client.from('emergency_actions').update(action.toJson()).eq('id', action.actionId!);
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.updateAction] error: $e');
      rethrow;
    }
  }

  // ── Templates ──
  Future<List<EmergencyTemplate>> getTemplates() async {
    try {
      final res = await _client.from('emergency_templates').select().order('usage_count', ascending: false);
      return (res as List).map((e) => EmergencyTemplate.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getTemplates] error: $e');
      rethrow;
    }
  }

  Future<EmergencyTemplate?> getTemplateById(String templateId) async {
    try {
      final res = await _client.from('emergency_templates').select().eq('template_id', templateId).maybeSingle();
      if (res == null) return null;
      return EmergencyTemplate.fromJson(res);
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getTemplateById] error: $e');
      rethrow;
    }
  }

  // ── Contacts ──
  Future<List<EmergencyContactModel>> getFamilyContacts(String familyId) async {
    try {
      final res = await _client
          .from('emergency_contacts')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true)
          .order('priority', ascending: true);
      return (res as List).map((e) => EmergencyContactModel.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getFamilyContacts] error: $e');
      rethrow;
    }
  }

  // ── Policies ──
  Future<EscalationPolicy?> getFamilyPolicy(String familyId) async {
    try {
      final res = await _client.from('escalation_policies').select().eq('family_id', familyId).maybeSingle();
      if (res == null) return null;
      return EscalationPolicy.fromJson(res);
    } catch (e, st) {
      debugPrint('[EmergencyActionRepository.getFamilyPolicy] error: $e');
      rethrow;
    }
  }
}
