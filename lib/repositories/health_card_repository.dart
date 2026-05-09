import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../services/auth_service.dart';
import '../services/health_card_service.dart';

class HealthCardRepository {
  static final HealthCardRepository _instance =
      HealthCardRepository._internal();
  factory HealthCardRepository() => _instance;
  HealthCardRepository._internal();

  final _client = SupabaseConfig.client;

  Future<String?> _getFamilyId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _client
        .from('profiles')
        .select('family_id')
        .eq('id', user.id)
        .maybeSingle();
    return profile?['family_id'] as String?;
  }

  Future<HealthCardData?> getForCurrentUser() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return null;

      final response = await _client
          .from('health_cards')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return _fromJson(response);
    } catch (e) {
      debugPrint('[HealthCardRepository.getForCurrentUser] error: $e');
      rethrow;
    }
  }

  Future<List<HealthCardData>> getForFamily() async {
    try {
      final familyId = await _getFamilyId();
      if (familyId == null) return [];

      final response = await _client
          .from('health_cards')
          .select('*')
          .eq('family_id', familyId);

      return (response as List).map((e) => _fromJson(e)).toList();
    } catch (e) {
      debugPrint('[HealthCardRepository.getForFamily] error: $e');
      rethrow;
    }
  }

  Future<HealthCardData> upsert(HealthCardData data) async {
    try {
      final userId = AuthService.currentUserId;
      final familyId = await _getFamilyId();
      if (userId == null) throw Exception('Giriş yapmalısınız');

      final json = _toJson(data);
      json['user_id'] = userId;
      if (familyId != null) json['family_id'] = familyId;

      final existing = await _client
          .from('health_cards')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final Map<String, dynamic> response;
      if (existing == null) {
        response = await _client
            .from('health_cards')
            .insert(json)
            .select()
            .single();
      } else {
        response = await _client
            .from('health_cards')
            .update(json)
            .eq('user_id', userId)
            .select()
            .single();
      }

      return _fromJson(response);
    } catch (e) {
      debugPrint('[HealthCardRepository.upsert] error: $e');
      rethrow;
    }
  }

  Future<void> deleteForCurrentUser() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      await _client.from('health_cards').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('[HealthCardRepository.deleteForCurrentUser] error: $e');
      rethrow;
    }
  }

  HealthCardData _fromJson(Map<String, dynamic> json) {
    return HealthCardData(
      bloodType: json['blood_type'] ?? '',
      allergies: List<String>.from(json['allergies'] ?? []),
      medications:
          (json['medications'] as List<dynamic>?)
              ?.map((e) => Medication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chronicConditions: List<String>.from(json['chronic_conditions'] ?? []),
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      emergencyContactRelation: json['emergency_contact_relation'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorPhone: json['doctor_phone'] ?? '',
      doctorHospital: json['doctor_hospital'] ?? '',
      organDonor: json['organ_donor'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> _toJson(HealthCardData data) {
    return {
      'blood_type': data.bloodType,
      'allergies': data.allergies,
      'medications': data.medications.map((e) => e.toJson()).toList(),
      'chronic_conditions': data.chronicConditions,
      'emergency_contact_name': data.emergencyContactName,
      'emergency_contact_phone': data.emergencyContactPhone,
      'emergency_contact_relation': data.emergencyContactRelation,
      'doctor_name': data.doctorName,
      'doctor_phone': data.doctorPhone,
      'doctor_hospital': data.doctorHospital,
      'organ_donor': data.organDonor,
      'notes': data.notes,
    };
  }
}
