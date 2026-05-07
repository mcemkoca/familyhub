import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/health_card_repository.dart';

class HealthCardService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'health_card_data';

  static Future<HealthCardData?> load() async {
    try {
      // 1. Try Supabase first
      final remote = await HealthCardRepository().getForCurrentUser();
      if (remote != null) {
        await _saveLocal(remote);
        return remote;
      }
    } catch (e) {
      debugPrint('HealthCardService remote load error: $e');
    }

    // 2. Fallback to local cache
    final jsonString = await _storage.read(key: _key);
    if (jsonString == null) return _emptyData();
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return HealthCardData.fromJson(map);
    } catch (_) {
      return _emptyData();
    }
  }

  static Future<void> save(HealthCardData data) async {
    try {
      // 1. Write to Supabase first
      await HealthCardRepository().upsert(data);
    } catch (e) {
      debugPrint('HealthCardService remote save error: $e');
    }

    // 2. Mirror to local cache
    await _saveLocal(data);
  }

  static Future<void> _saveLocal(HealthCardData data) async {
    final jsonString = jsonEncode(data.toJson());
    await _storage.write(key: _key, value: jsonString);
  }

  static HealthCardData _emptyData() {
    return HealthCardData(
      bloodType: '',
      allergies: [],
      medications: [],
      chronicConditions: [],
      emergencyContactName: '',
      emergencyContactPhone: '',
      emergencyContactRelation: '',
      doctorName: '',
      doctorPhone: '',
      doctorHospital: '',
      organDonor: false,
      notes: '',
    );
  }
}

class HealthCardData {
  String bloodType;
  List<String> allergies;
  List<Medication> medications;
  List<String> chronicConditions;
  String emergencyContactName;
  String emergencyContactPhone;
  String emergencyContactRelation;
  String doctorName;
  String doctorPhone;
  String doctorHospital;
  bool organDonor;
  String notes;

  HealthCardData({
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.chronicConditions,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    required this.doctorName,
    required this.doctorPhone,
    required this.doctorHospital,
    required this.organDonor,
    required this.notes,
  });

  factory HealthCardData.fromJson(Map<String, dynamic> json) {
    return HealthCardData(
      bloodType: json['bloodType'] ?? '',
      allergies: List<String>.from(json['allergies'] ?? []),
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => Medication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      emergencyContactRelation: json['emergencyContactRelation'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorPhone: json['doctorPhone'] ?? '',
      doctorHospital: json['doctorHospital'] ?? '',
      organDonor: json['organDonor'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications.map((e) => e.toJson()).toList(),
      'chronicConditions': chronicConditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'doctorHospital': doctorHospital,
      'organDonor': organDonor,
      'notes': notes,
    };
  }
}

class Medication {
  String name;
  String dosage;
  String frequency;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
    };
  }
}
