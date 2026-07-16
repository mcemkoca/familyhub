import 'dart:convert';

import 'package:http/http.dart' as http;
import '../localization/locale_service.dart';

/// OpenAI API integration for FamilyHub dynamic content generation.
///
/// Usage:
/// ```dart
/// AIContentService.instance.initialize(apiKey: 'sk-...');
/// final seed = await AIContentService.instance.generateSeedData();
/// ```
class AIContentService {
  AIContentService._();
  static final AIContentService _instance = AIContentService._();
  static AIContentService get instance => _instance;

  String? _apiKey;
  String? _masterPrompt;

  String get _languageCode =>
      LocaleService.resolveInitialLocale().languageCode;

  String _text(Map<String, String> values) =>
      values[_languageCode] ?? values['tr']!;

  /// Rate limiting: track last call timestamp
  DateTime? _lastCallTime;
  static const _minIntervalMs = 500; // 2 req/sec max

  void initialize({required String apiKey, String? masterPrompt}) {
    _apiKey = apiKey;
    _masterPrompt = masterPrompt;
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Generates initial seed data for all FamilyHub modules.
  /// Equivalent to Python: FAMILYHUB_INIT
  Future<Map<String, dynamic>> generateSeedData() async {
    return _chatCompletion([
      {'role': 'system', 'content': _masterPrompt ?? _defaultMasterPrompt},
      {'role': 'user', 'content': 'FAMILYHUB_INIT'},
    ]);
  }

  /// Refreshes a specific module with updated content.
  /// Equivalent to Python: FAMILYHUB_REFRESH {module_name}
  Future<Map<String, dynamic>> refreshModule(String moduleName) async {
    return _chatCompletion([
      {'role': 'system', 'content': _masterPrompt ?? _defaultMasterPrompt},
      {'role': 'user', 'content': 'FAMILYHUB_REFRESH $moduleName'},
    ]);
  }

  /// Generates personalized content based on family profile.
  Future<Map<String, dynamic>> generatePersonalized({
    required String familyType,
    required List<int> childrenAges,
    required double budgetRange,
    required String region,
    String? specialRequests,
  }) async {
    final prompt = _text({
      'tr': '''Aile profili: $familyType
Çocuk yaşları: ${childrenAges.join(', ')}
Bütçe: $budgetRange EUR
Bölge: $region
Özel istek: ${specialRequests ?? 'Yok'}
Bu profile uygun içerik oluştur.''',
      'en': '''Family profile: $familyType
Children’s ages: ${childrenAges.join(', ')}
Budget: $budgetRange EUR
Region: $region
Special request: ${specialRequests ?? 'None'}
Create suitable content for this profile.''',
      'nl': '''Gezinsprofiel: $familyType
Leeftijden van de kinderen: ${childrenAges.join(', ')}
Budget: $budgetRange EUR
Regio: $region
Speciaal verzoek: ${specialRequests ?? 'Geen'}
Maak geschikte inhoud voor dit profiel.''',
      'fr': '''Profil familial : $familyType
Âge des enfants : ${childrenAges.join(', ')}
Budget : $budgetRange EUR
Région : $region
Demande particulière : ${specialRequests ?? 'Aucune'}
Créez un contenu adapté à ce profil.''',
    });
    return _chatCompletion([
      {'role': 'system', 'content': _masterPrompt ?? _defaultMasterPrompt},
      {'role': 'user', 'content': prompt},
    ]);
  }

  // ── Internal ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _chatCompletion(
    List<Map<String, String>> messages,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw AIContentException(_text(const {
        'tr': 'OpenAI API anahtarı yapılandırılmadı. Önce initialize() metodunu çağırın.',
        'en': 'The OpenAI API key is not configured. Call initialize() first.',
        'nl': 'De OpenAI API-sleutel is niet geconfigureerd. Roep eerst initialize() aan.',
        'fr': 'La clé API OpenAI n’est pas configurée. Appelez d’abord initialize().',
      }));
    }

    // Rate limiting
    if (_lastCallTime != null) {
      final elapsed = DateTime.now().difference(_lastCallTime!).inMilliseconds;
      if (elapsed < _minIntervalMs) {
        await Future.delayed(Duration(milliseconds: _minIntervalMs - elapsed));
      }
    }
    _lastCallTime = DateTime.now();

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 4000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw AIContentException(
          '${_text(const {
            'tr': 'OpenAI API hatası', 'en': 'OpenAI API error',
            'nl': 'OpenAI API-fout', 'fr': 'Erreur de l’API OpenAI',
          })} ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // ignore: avoid_dynamic_calls
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw AIContentException(_text(const {
          'tr': 'OpenAI API boş yanıt döndürdü',
          'en': 'The OpenAI API returned an empty response',
          'nl': 'De OpenAI API heeft een leeg antwoord geretourneerd',
          'fr': 'L’API OpenAI a renvoyé une réponse vide',
        }));
      }

      return jsonDecode(content) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw AIContentException('${_text(const {
        'tr': 'OpenAI yanıtındaki JSON geçersiz',
        'en': 'Invalid JSON in the OpenAI response',
        'nl': 'Ongeldige JSON in het OpenAI-antwoord',
        'fr': 'JSON non valide dans la réponse OpenAI',
      })}: $e');
    } catch (e) {
      throw AIContentException('${_text(const {
        'tr': 'OpenAI isteği başarısız oldu',
        'en': 'The OpenAI request failed',
        'nl': 'Het OpenAI-verzoek is mislukt',
        'fr': 'La requête OpenAI a échoué',
      })}: $e');
    }
  }

  String get _defaultMasterPrompt => '''
You are FamilyHub AI, a specialized content generator for families living in Belgium.
You generate structured JSON content for family management modules.
Always respond with valid JSON only.
Supported modules: child_development, meal_planning, household, budget, future_planning.
Language: ${_languageName(_languageCode)} ($_languageCode), Region: Belgium (BE).
''';

  String _languageName(String code) => switch (code) {
        'en' => 'English',
        'nl' => 'Dutch',
        'fr' => 'French',
        _ => 'Turkish',
      };
}

class AIContentException implements Exception {
  final String message;
  AIContentException(this.message);

  @override
  String toString() => 'AIContentException: $message';
}
