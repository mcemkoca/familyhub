import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Fetches onboarding content from Firebase Remote Config with local fallback.
class OnboardingService {
  static Future<List<Map<String, String>>> getSlides() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final jsonString = remoteConfig.getString('onboarding_slides');
      if (jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList.map((e) {
          final map = e as Map<String, dynamic>;
          return <String, String>{
            'image': (map['image'] ?? 'assets/images/onboarding/onboarding_1.png') as String,
            'title': (map['title'] ?? '') as String,
            'desc': (map['desc'] ?? '') as String,
          };
        }).toList();
      }
    } catch (_) {
      // Remote config failed — caller should use local fallback
    }
    return [];
  }
}
