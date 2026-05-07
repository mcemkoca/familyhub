import 'dart:io';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../supabase_client.dart';

/// Multi-provider analytics service: Mixpanel + Amplitude + Supabase internal.
/// Tokens should be provided via --dart-define in production.
class AnalyticsService {
  static Mixpanel? _mixpanel;
  static Amplitude? _amplitude;
  static final _firebaseAnalytics = FirebaseAnalytics.instance;

  static const _mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  static const _amplitudeKey = String.fromEnvironment('AMPLITUDE_KEY');

  static bool get _isConfigured => _mixpanelToken.isNotEmpty || _amplitudeKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!_isConfigured) return;

    if (_mixpanelToken.isNotEmpty) {
      _mixpanel = await Mixpanel.init(_mixpanelToken, trackAutomaticEvents: true);
    }

    if (_amplitudeKey.isNotEmpty) {
      _amplitude = Amplitude(Configuration(apiKey: _amplitudeKey));
      await _amplitude!.isBuilt;
    }
  }

  static Future<void> initializeFirebase() async {
    await _firebaseAnalytics.setAnalyticsCollectionEnabled(true);
  }

  static Future<void> identify(String userId, Map<String, dynamic> traits) async {
    _mixpanel?.identify(userId);
    _mixpanel?.getPeople().set('\$email', traits['email']);
    _mixpanel?.getPeople().set('\$name', traits['name']);
    _mixpanel?.getPeople().set('family_role', traits['role']);
    _mixpanel?.getPeople().set('family_size', traits['familySize']);

    _amplitude?.setUserId(userId);
    final identify = Identify()
      ..set('email', traits['email'])
      ..set('name', traits['name'])
      ..set('family_role', traits['role'])
      ..set('family_size', traits['familySize']);
    _amplitude?.identify(identify);

    await _firebaseAnalytics.setUserId(id: userId);
    await _firebaseAnalytics.setUserProperty(name: 'email', value: traits['email']?.toString());
    await _firebaseAnalytics.setUserProperty(name: 'name', value: traits['name']?.toString());
    await _firebaseAnalytics.setUserProperty(name: 'family_role', value: traits['role']?.toString());
    await _firebaseAnalytics.setUserProperty(name: 'family_size', value: traits['familySize']?.toString());
  }

  static Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    if (!_isConfigured) return;

    final enriched = {
      ...?properties,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': const String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
      'platform': Platform.operatingSystem,
    };

    _mixpanel?.track(event, properties: enriched);
    _amplitude?.track(BaseEvent(event, eventProperties: enriched));

    await _firebaseAnalytics.logEvent(
      name: event.replaceAll(' ', '_').toLowerCase().substring(0, event.length > 40 ? 40 : event.length),
      parameters: enriched.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    // Internal Supabase analytics (fire-and-forget)
    SupabaseConfig.client
        .from('analytics_events')
        .insert({
          'event': event,
          'properties': enriched,
          'user_id': SupabaseConfig.client.auth.currentUser?.id,
        })
        .ignore();
  }

  // ── Funnel events ──
  static void trackOnboardingStep(int step, String stepName) {
    track('onboarding_step', properties: {
      'step_number': step,
      'step_name': stepName,
    });
  }

  static void trackActivation(String activationType) {
    track('activation', properties: {'type': activationType});
  }

  static void trackRetention(int day) {
    track('retention', properties: {'day': day});
  }

  static void trackRevenue(String product, double amount, String currency) {
    _mixpanel?.getPeople().trackCharge(amount, properties: {
      'product': product,
      'currency': currency,
    });
    track('purchase', properties: {
      'product': product,
      'amount': amount,
      'currency': currency,
    });
  }

  static void trackBillingError(String error) {
    track('billing_error', properties: {'error': error});
  }

  static void trackPurchaseFailed(String error) {
    track('purchase_failed', properties: {'error': error});
  }
}
