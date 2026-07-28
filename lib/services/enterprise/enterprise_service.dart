import '../../core/errors.dart';
import '../../core/supabase_client.dart';
import '../../core/analytics/analytics_service.dart';
import '../localization/locale_service.dart';

class EnterpriseService {
  static String _text(Map<String, String> values) {
    final language = LocaleService.resolveInitialLocale().languageCode;
    return values[language] ?? values['tr']!;
  }

  static Future<Map<String, dynamic>> registerOrganization({
    required String name,
    required String domain,
    required int employeeCount,
    required String adminEmail,
  }) async {
    final domainExists = await _checkDomain(domain);
    if (domainExists) {
      throw ValidationException(_text(const {
        'tr': 'Bu alan adı zaten kayıtlı', 'en': 'This domain is already registered',
        'nl': 'Dit domein is al geregistreerd', 'fr': 'Ce domaine est déjà enregistré',
      }));
    }

    final org = await SupabaseConfig.client.from('organizations').insert({
      'name': name,
      'domain': domain,
      'employee_count': employeeCount,
      'admin_email': adminEmail,
      'status': 'pending_verification',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    await _sendDomainVerificationEmail(adminEmail, org['id'] as String);

    AnalyticsService.track('enterprise_signup', properties: {
      'domain': domain,
      'size': employeeCount,
    });

    return org;
  }

  static Future<void> verifyDomain(String orgId, String token) async {
    await SupabaseConfig.client.from('organizations').update({
      'status': 'verified',
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('id', orgId);

    await _setupSSO(orgId);
  }

  static Future<Map<String, dynamic>> getDashboardData(String orgId) async {
    final stats = await SupabaseConfig.client.rpc('get_org_stats', params: {'org_id': orgId}) as Map<String, dynamic>;
    return {
      'total_employees': stats['total_employees'],
      'active_families': stats['active_families'],
      'engagement_rate': stats['engagement_rate'],
      'health_score': stats['health_score'],
      'roi': {
        'reduced_sick_days': stats['reduced_sick_days'],
        'retention_improvement': stats['retention_improvement'],
        'productivity_gain': stats['productivity_gain'],
      },
    };
  }

  static Future<void> syncWithHRSystem(String orgId, String systemType) async {
    switch (systemType) {
      case 'bamboo_hr':
        await _syncBambooHR(orgId);
        break;
      case 'workday':
        await _syncWorkday(orgId);
        break;
      default:
        throw ValidationException('${_text(const {
          'tr': 'Desteklenmeyen İK sistemi', 'en': 'Unsupported HR system',
          'nl': 'Niet-ondersteund HR-systeem', 'fr': 'Système RH non pris en charge',
        })}: $systemType');
    }
  }

  // ── Private helpers ──
  static Future<bool> _checkDomain(String domain) async {
    final result = await SupabaseConfig.client
        .from('organizations')
        .select('id')
        .eq('domain', domain)
        .maybeSingle();
    return result != null;
  }

  static Future<void> _sendDomainVerificationEmail(String email, String orgId) async {
    // Sends verification email via Supabase Edge Function
    await SupabaseConfig.client.rpc('send_verification_email', params: {
      'to_email': email,
      'org_id': orgId,
    });
  }

  static Future<void> _setupSSO(String orgId) async {
    await SupabaseConfig.client.from('sso_configs').insert({
      'org_id': orgId,
      'provider': 'saml',
      'status': 'pending_setup',
    });
  }

  static Future<void> _syncBambooHR(String orgId) async {
    AnalyticsService.track('hr_sync', properties: {'org_id': orgId, 'system': 'bamboo_hr'});
    // TODO: Implement BambooHR API integration
  }

  static Future<void> _syncWorkday(String orgId) async {
    AnalyticsService.track('hr_sync', properties: {'org_id': orgId, 'system': 'workday'});
    // TODO: Implement Workday API integration
  }
}
