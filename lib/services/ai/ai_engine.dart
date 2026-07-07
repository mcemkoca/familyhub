import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import '../../core/analytics/analytics_service.dart';

/// Supported LLM providers with fallback chain:
/// OpenAI → Anthropic → Google Gemini → Local (rule-based)
enum LLMProvider { openAI, anthropic, googleGemini, local }

/// Response format hint for structured output
enum AIResponseFormat { text, json }

/// Unified response from any LLM provider
class AIResponse {
  final String content;
  final LLMProvider provider;
  final int? tokensUsed;
  final bool isFallback;
  final Duration latency;

  const AIResponse({
    required this.content,
    required this.provider,
    this.tokensUsed,
    this.isFallback = false,
    this.latency = Duration.zero,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'provider': provider.name,
    'tokensUsed': tokensUsed,
    'isFallback': isFallback,
    'latencyMs': latency.inMilliseconds,
  };
}

/// Production-ready multi-provider LLM engine with automatic fallback.
///
/// API keys are injected via `--dart-define` at build time:
///   --dart-define=OPENAI_API_KEY=sk-...
///   --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///   --dart-define=GEMINI_API_KEY=AIza...
class AIEngine {
  AIEngine._();

  static const String _openAIKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _anthropicKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
  );
  // Gemini anahtarı: PROD'da --dart-define=GEMINI_API_KEY=... ile verilmeli.
  // ÖNERİLEN üretim mimarisi: istekleri anahtarı sunucuda tutan bir proxy'den
  // (ör. Supabase Edge Function) geçirmek; böylece anahtar APK'ya hiç girmez.
  static const String _geminiKeyEnv = String.fromEnvironment('GEMINI_API_KEY');
  // Yalnızca GELİŞTİRME (debug) kolaylığı için gömülü anahtar.
  // Release derlemelerde KULLANILMAZ (aşağıdaki kDebugMode koşulu) — böylece
  // yayınlanan APK'da canlı olarak kullanılmaz; dart-define ya da proxy şarttır.
  static const String _geminiKeyDevFallback =
      'AQ.Ab8RN6LPYfXYg6UktuoFIiaAkrN_lBZ_VoPC15gnU0wS0Z5iwQ';
  static String get _geminiKey {
    if (_geminiKeyEnv.isNotEmpty) return _geminiKeyEnv;
    return kDebugMode ? _geminiKeyDevFallback : '';
  }

  static const Duration _timeout = Duration(seconds: 10);

  /// Sırayla denenecek Gemini modelleri. Her modelin ücretsiz katmanda AYRI
  /// kotası olduğundan, biri 429 (kota) verirse sıradakine geçilir.
  static const List<String> _geminiModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
    'gemini-2.0-flash',
  ];

  /// Primary entry-point: tries providers in fallback chain.
  static Future<AIResponse> generate({
    required String prompt,
    String? systemPrompt,
    AIResponseFormat format = AIResponseFormat.text,
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Try OpenAI
    if (_openAIKey.isNotEmpty) {
      try {
        final response = await _callOpenAI(
          prompt: prompt,
          systemPrompt: systemPrompt,
          format: format,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        stopwatch.stop();
        return AIResponse(
          content: response,
          provider: LLMProvider.openAI,
          latency: stopwatch.elapsed,
        );
      } catch (e) {
        AnalyticsService.track(
          'llm_fallback',
          properties: {
            'from': 'openai',
            'to': 'anthropic',
            'error': e.toString(),
          },
        );
      }
    }

    // Fallback to Anthropic
    if (_anthropicKey.isNotEmpty) {
      try {
        final response = await _callAnthropic(
          prompt: prompt,
          systemPrompt: systemPrompt,
          format: format,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        stopwatch.stop();
        return AIResponse(
          content: response,
          provider: LLMProvider.anthropic,
          isFallback: _openAIKey.isNotEmpty,
          latency: stopwatch.elapsed,
        );
      } catch (e) {
        AnalyticsService.track(
          'llm_fallback',
          properties: {
            'from': 'anthropic',
            'to': 'gemini',
            'error': e.toString(),
          },
        );
      }
    }

    // Fallback to Gemini
    if (_geminiKey.isNotEmpty) {
      try {
        final response = await _callGemini(
          prompt: prompt,
          systemPrompt: systemPrompt,
          format: format,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        stopwatch.stop();
        return AIResponse(
          content: response,
          provider: LLMProvider.googleGemini,
          isFallback: _openAIKey.isNotEmpty || _anthropicKey.isNotEmpty,
          latency: stopwatch.elapsed,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Gemini fallback: $e');
        AnalyticsService.track(
          'llm_fallback',
          properties: {'from': 'gemini', 'to': 'local', 'error': e.toString()},
        );
      }
    }

    // Final fallback: rule-based local response
    stopwatch.stop();
    AnalyticsService.track(
      'llm_fallback',
      properties: {
        'from': 'gemini',
        'to': 'local',
        'reason': 'all_providers_failed_or_no_keys',
      },
    );

    return _localFallback(prompt);
  }

  // ── OpenAI GPT-4o-mini (cost-effective) ────────────────────────────────

  static Future<String> _callOpenAI({
    required String prompt,
    required String? systemPrompt,
    required AIResponseFormat format,
    required int maxTokens,
    required double temperature,
  }) async {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = <String, dynamic>{
      'model': 'gpt-4o-mini',
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    };

    if (format == AIResponseFormat.json) {
      body['response_format'] = {'type': 'json_object'};
    }

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw _ProviderException('OpenAI', response.statusCode, response.body);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw _ProviderException('OpenAI', 200, 'Empty choices');
    }

    // ignore: avoid_dynamic_calls
    final content = choices[0]['message']['content'] as String?;
    if (content == null) {
      throw _ProviderException('OpenAI', 200, 'Null content');
    }

    return content;
  }

  // ── Anthropic Claude 3.5 Haiku (fast + cheap) ─────────────────────────

  static Future<String> _callAnthropic({
    required String prompt,
    required String? systemPrompt,
    required AIResponseFormat format,
    required int maxTokens,
    required double temperature,
  }) async {
    final body = <String, dynamic>{
      'model': 'claude-3-5-haiku-20241022',
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': [
        {
          'role': 'user',
          'content': format == AIResponseFormat.json
              ? '$prompt\n\nYanıtı JSON formatında ver.'
              : prompt,
        },
      ],
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw _ProviderException('Anthropic', response.statusCode, response.body);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    if (content.isEmpty) {
      throw _ProviderException('Anthropic', 200, 'Empty content');
    }

    // ignore: avoid_dynamic_calls
    final text = content[0]['text'] as String?;
    if (text == null) throw _ProviderException('Anthropic', 200, 'Null text');

    return text;
  }

  // ── Google Gemini 1.5 Flash (fast + cheap) ────────────────────────────

  static Future<String> _callGemini({
    required String prompt,
    required String? systemPrompt,
    required AIResponseFormat format,
    required int maxTokens,
    required double temperature,
  }) async {
    final fullPrompt = systemPrompt != null && systemPrompt.isNotEmpty
        ? '$systemPrompt\n\n$prompt'
        : prompt;

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': fullPrompt},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': temperature,
        if (format == AIResponseFormat.json)
          'responseMimeType': 'application/json',
        // gemini-2.5-flash düşünen model; düşünmeyi kapatarak token bütçesini
        // tamamen yanıta ayır (yoksa boş/eksik yanıt dönebilir).
        'thinkingConfig': {'thinkingBudget': 0},
      },
    };

    // Her modelin AYRI ücretsiz kotası var. Biri 429 (kota dolu) verirse
    // sıradaki modele geç — böylece günlük limit bir modelde bitse bile
    // asistan çalışmaya devam eder.
    http.Response? response;
    for (final model in _geminiModels) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiKey',
      );
      var quotaHit = false;
      for (var attempt = 0; attempt < 2; attempt++) {
        response = await http
            .post(uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body))
            .timeout(_timeout);
        if (response.statusCode == 429) {
          quotaHit = true;
          // Kısa bir kez bekleyip aynı modeli tekrar dene; yine 429 ise
          // sıradaki modele geç.
          if (attempt == 0) {
            final delay = _parseRetryDelay(response.body);
            if (delay.inSeconds <= 8) {
              await Future.delayed(delay);
              continue;
            }
          }
          break;
        }
        quotaHit = false;
        break;
      }
      if (response != null && response.statusCode == 200) break;
      if (!quotaHit) break; // 429 dışı hata → model değiştirmek fayda etmez
    }

    if (response == null || response.statusCode != 200) {
      throw _ProviderException(
          'Gemini', response?.statusCode ?? 0, response?.body ?? 'no response');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw _ProviderException('Gemini', 200, 'Empty candidates');
    }

    // ignore: avoid_dynamic_calls
    final parts = candidates[0]['content']['parts'] as List<dynamic>;
    // ignore: avoid_dynamic_calls
    final text = parts[0]['text'] as String?;
    if (text == null) throw _ProviderException('Gemini', 200, 'Null text');

    return text;
  }

  // 429 yanıt gövdesinden önerilen bekleme süresini çıkarır (varsayılan 6 sn,
  // en çok 12 sn).
  static Duration _parseRetryDelay(String body) {
    try {
      final m = RegExp(r'retry in ([0-9]+(?:\.[0-9]+)?)s').firstMatch(body);
      if (m != null) {
        final secs = double.parse(m.group(1)!).ceil() + 1;
        return Duration(seconds: secs.clamp(2, 12));
      }
    } catch (_) {}
    return const Duration(seconds: 6);
  }

  // ── Local rule-based fallback ─────────────────────────────────────────

  static AIResponse _localFallback(String prompt) {
    final lower = prompt.toLowerCase();

    // Event suggestions
    if (lower.contains('etkinlik') ||
        lower.contains('event') ||
        lower.contains('plan')) {
      return const AIResponse(
        content:
            '{"suggestions": ['
            '{"type": "event", "title": "Aile kahvaltısı planla", "description": "Hafta sonu için bir kahvaltı etkinliği oluşturun.", "action": "create_event"}, '
            '{"type": "event", "title": "Sinema gecesi", "description": "Bu hafta bir film seçip ailece izleyin.", "action": "create_event"}, '
            '{"type": "task", "title": "Alışveriş listesi hazırla", "description": "Haftalık market alışverişi için liste oluşturun.", "action": "create_task"}'
            ']}',
        provider: LLMProvider.local,
        isFallback: true,
      );
    }

    // Task / productivity suggestions
    if (lower.contains('görev') ||
        lower.contains('task') ||
        lower.contains('iş')) {
      return const AIResponse(
        content:
            '{"suggestions": ['
            '{"type": "task", "title": "Günlük görevleri gözden geçir", "description": "Bugün tamamlanması gereken görevleri kontrol edin.", "action": "navigate_tasks"}, '
            '{"type": "task", "title": "Yeni görev ekle", "description": "Bir aile üyesine görev atayın.", "action": "create_task"}'
            ']}',
        provider: LLMProvider.local,
        isFallback: true,
      );
    }

    // Budget / finance
    if (lower.contains('bütçe') ||
        lower.contains('budget') ||
        lower.contains('para') ||
        lower.contains('harcama')) {
      return const AIResponse(
        content:
            '{"suggestions": ['
            '{"type": "budget", "title": "Aylık bütçeyi gözden geçir", "description": "Bu ayki harcamalarınızı analiz edin.", "action": "navigate_budget"}, '
            '{"type": "budget", "title": "Tasarruf hedefi koy", "description": "Gelecek ay için bir tasarruf hedefi belirleyin.", "action": "navigate_budget"}'
            ']}',
        provider: LLMProvider.local,
        isFallback: true,
      );
    }

    // Safety / location
    if (lower.contains('güvenlik') ||
        lower.contains('safety') ||
        lower.contains('konum') ||
        lower.contains('location')) {
      return const AIResponse(
        content:
            '{"suggestions": ['
            '{"type": "safety", "title": "Aile konumlarını kontrol et", "description": "Aile üyelerinin güncel konumlarını görüntüleyin.", "action": "navigate_safety"}, '
            '{"type": "safety", "title": "Acil durum bilgilerini güncelle", "description": "Sağlık kartı ve acil durum bilgilerini kontrol edin.", "action": "navigate_health"}'
            ']}',
        provider: LLMProvider.local,
        isFallback: true,
      );
    }

    // Default / generic — Rich Daily Recommendations
    return const AIResponse(
      content:
          '{"suggestions": ['
          '{"id":"daily-recipe-1","type":"recipe","category":"dinner","title":"Bugünün Yemeği: Tavuk Sote","description":"Sevdiklerinizle paylaşabileceğiniz nefis bir akşam yemeği. Baharatlarla marine edilmiş tavuk göğsü, renkli biberlerle birlikte sotelendi.","action":"show_detail","priority":"medium","badge":"Aile Favorisi","durationMinutes":35,"calories":450,"servings":4,"difficulty":"Orta","ingredients":[{"name":"Tavuk göğsü","amount":"500g","inStock":true,"category":"meat"},{"name":"Biber","amount":"2 adet","inStock":true,"category":"produce"},{"name":"Domates","amount":"3 adet","inStock":true,"category":"produce"},{"name":"Krema","amount":"2 yemek kaşığı","inStock":false,"category":"dairy"},{"name":"Sarımsak","amount":"3 diş","inStock":true,"category":"produce"},{"name":"Zeytinyağı","amount":"3 yemek kaşığı","inStock":true,"category":"pantry"}],"tips":["Tavukları marine etmek için en az 15 dk bekletin.","Kremayı son dakikada ekleyip karıştırın.","Pirinç pilavı ile servis edin."],"steps":["Tavukları kuşbaşı doğrayıp baharatlarla marine edin.","Biber ve domatesleri dilimleyin.","Zeytinyağında tavukları kavurun.","Sebzeleri ekleyip soteleyin.","Kremayı ilave edip karıştırın."],"nutritionInfo":{"protein":38,"carbs":12,"fat":22,"fiber":3,"sugar":4},"assignedTo":null,"lastDone":null,"estimatedCost":"Orta","allowAlternatives":true,"shareable":true,"isNew":false,"progress":0}, '
          '{"id":"daily-chore-1","type":"chore","category":"cleaning","title":"Ev İşleri: Banyo derinlemesine temizlik","description":"Banyonun hijyenini üst seviyeye çıkarın. Fayanslar, küvet ve lavaboda biriken kireç lekelerine veda edin.","action":"show_detail","priority":"high","badge":"Zaman Tasarrufu","durationMinutes":45,"calories":180,"difficulty":"Orta","ingredients":[{"name":"Oksijen bazlı temizleyici","amount":"1 şişe","inStock":false,"category":"cleaning"},{"name":"Mikrofiber bez","amount":"3 adet","inStock":true,"category":"cleaning"},{"name":"Eski diş fırçası","amount":"1 adet","inStock":true,"category":"cleaning"}],"tips":["Çamaşır suyu yerine oksijen bazlı temizleyici kullanın - daha güvenli ve çevre dostu.","Fayans araları için eski diş fırçası kullanın.","Temizlik sonrası havalandırmayı unutmayın."],"steps":["Küveti ve lavaboyu ıslatın.","Oksijen bazlı temizleyiciyi yüzeylere sıkın.","10 dk bekletin.","Mikrofiber bezle silin.","Fayans aralarını fırçalayın."],"assignedTo":"Anne","lastDone":"14 gün önce","estimatedCost":"Düşük","allowAlternatives":true,"shareable":true,"isNew":false,"progress":0}, '
          '{"id":"daily-health-1","type":"health","category":"hydration","title":"Sağlık: Günlük su hedefi","description":"Aile üyelerinin günlük su tüketimini artırmak için hatırlatıcı kurun. Özellikle çocukların ve yaşlıların yeterli su içtiğinden emin olun.","action":"navigate_health","priority":"medium","badge":"Yeni","durationMinutes":5,"calories":0,"difficulty":"Kolay","ingredients":[],"tips":["Her öğün öncesi ve sonrası bir bardak su için.","Yanında su şişesi taşıyın.","Meyveli su veya bitki çayı ile çeşitlendirin."],"steps":["Sabah kalkınca 1 bardak su için.","Öğle yemeğinden önce ve sonra su için.","Akşam yemeğinden önce ve sonra su için."],"assignedTo":"Tüm Aile","lastDone":null,"estimatedCost":"Düşük","allowAlternatives":false,"shareable":true,"isNew":true,"progress":0}, '
          '{"id":"daily-edu-1","type":"education","category":"reading","title":"Eğitim: Aile okuma vakti","description":"Bu akşam 20 dakika ailecek kitap okuma zamanı. Çocuklar için resimli kitap, yetişkinler için roman önerisi.","action":"create_event","priority":"low","badge":"Trend","durationMinutes":20,"calories":0,"difficulty":"Kolay","ingredients":[],"tips":["Televizyon ve telefonları kapatın.","Rahat bir köşe oluşturun.","Herkes kendi kitabını seçsin."],"steps":["Her aile üyesi kendi kitabını seçsin.","20 dakika sessizce okuyun.","Okunanları kısaca paylaşın."],"assignedTo":"Tüm Aile","lastDone":"3 gün önce","estimatedCost":"Düşük","allowAlternatives":true,"shareable":true,"isNew":false,"progress":0}, '
          '{"id":"daily-finance-1","type":"finance","category":"budget_tip","title":"Finans: Haftalık bütçe kontrolü","description":"Bu haftanın harcamalarını gözden geçirin. Gereksiz abonelikleri ve dürtüsel alışverişleri tespit edin.","action":"navigate_budget","priority":"medium","badge":"Zaman Tasarrufu","durationMinutes":15,"calories":0,"difficulty":"Kolay","ingredients":[],"tips":["Banka bildirimlerini açın.","Harcama kategorilerini renklendirin.","Tasarruf hedefi koyun."],"steps":["Son 7 günün harcamalarını listeleyin.","Gereksiz harcamaları işaretleyin.","Gelecek hafta için limit belirleyin."],"assignedTo":"Baba","lastDone":"5 gün önce","estimatedCost":"Düşük","allowAlternatives":false,"shareable":true,"isNew":false,"progress":0}, '
          '{"id":"daily-social-1","type":"social","category":"activity","title":"Sosyal: Aile oyun gecesi","description":"Bu akşam televizyon kapalı, ailecek bir masa oyunu oynayın. Monopoly, Tabu veya kart oyunları tercih edilebilir.","action":"create_event","priority":"low","badge":"Aile Favorisi","durationMinutes":90,"calories":0,"difficulty":"Kolay","ingredients":[],"tips":["Herkesin sevdiği bir oyun seçin.","Atıştırmalıklar hazırlayın.","Kazanmak değil, eğlenmek önemli."],"steps":["Oyun seçimi yapın.","Atıştırmalıkları hazırlayın.","Oyun alanını düzenleyin.","Oyun kurallarını hatırlayın."],"assignedTo":"Tüm Aile","lastDone":"10 gün önce","estimatedCost":"Düşük","allowAlternatives":true,"shareable":true,"isNew":false,"progress":0}'
          ']}',
      provider: LLMProvider.local,
      isFallback: true,
    );
  }
}

// ── Internal exception ──────────────────────────────────────────────────

class _ProviderException implements Exception {
  final String provider;
  final int statusCode;
  final String body;

  _ProviderException(this.provider, this.statusCode, this.body);

  @override
  String toString() => '$provider error $statusCode: $body';
}
