import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final prompt = '''
Aile profili: $familyType
Çocuk yaşları: ${childrenAges.join(', ')}
Bütçe: $budgetRange EUR
Bölge: $region
Özel istek: ${specialRequests ?? 'Yok'}
Bu profile uygun içerik oluştur.
'''; // Keep Turkish prompt as in original spec
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
      throw AIContentException('OpenAI API key not configured. Call initialize() first.');
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
          'OpenAI API error ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // ignore: avoid_dynamic_calls
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw AIContentException('Empty response from OpenAI API');
      }

      return jsonDecode(content) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw AIContentException('Invalid JSON in OpenAI response: $e');
    } catch (e) {
      throw AIContentException('OpenAI request failed: $e');
    }
  }

  static const String _defaultMasterPrompt = '''
You are FamilyHub AI, a specialized content generator for Turkish families living in Belgium.
You generate structured JSON content for family management modules.
Always respond with valid JSON only.
Supported modules: child_development, meal_planning, household, budget, future_planning.
Language: Turkish (tr), Region: Belgium (BE).
'''; // Safe fallback if no master prompt file is loaded
}

class AIContentException implements Exception {
  final String message;
  AIContentException(this.message);

  @override
  String toString() => 'AIContentException: $message';
}
