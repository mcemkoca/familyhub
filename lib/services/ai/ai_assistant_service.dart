import 'dart:convert';
import '../../core/app_logger.dart';
import '../../domain/entities.dart';
import '../../features/context_memory/domain/memory_prompt_composer.dart';
import '../../features/context_memory/infrastructure/memory_repository.dart';
import '../../repositories/shopping_repository.dart';
import '../auth_service.dart';
import 'ai_engine.dart';

/// Intent types the AI assistant can detect and execute.
enum AssistantIntent {
  mealPlan,
  addToShopping,
  budgetCheck,
  weeklyPlan,
  unknown,
}

/// A single action the assistant took during intent execution.
class AssistantAction {
  final String description;
  final bool success;
  final String? detail;

  const AssistantAction({
    required this.description,
    this.success = true,
    this.detail,
  });
}

/// Result returned from [AIAssistantService.processCommand].
class AICommandResult {
  final String userMessage;
  final String assistantReply;
  final List<AssistantAction> actions;
  final AssistantIntent intent;
  final bool hasErrors;

  const AICommandResult({
    required this.userMessage,
    required this.assistantReply,
    required this.actions,
    required this.intent,
    this.hasErrors = false,
  });
}

/// V2.1 — Akıllı Aile Asistanı
///
/// Natural-language commands are parsed, cross-module intents are detected,
/// and actions are executed across kitchen + shopping + budget in one flow.
///
/// Example: "Bu hafta 4 kişilik ekonomik yemek planı yap,
///           eksik malzemeleri alışveriş listeme ekle,
///           bütçeyi 60 euro altında tut."
class AIAssistantService {
  AIAssistantService._();
  static final AIAssistantService instance = AIAssistantService._();

  final _shopping = ShoppingRepository();

  static const String _systemPrompt =
      'Sen FamilyHub\'ın akıllı aile asistanısın. '
      'Kullanıcının Türkçe komutlarını analiz et ve şu JSON formatında yanıt ver:\n'
      '{\n'
      '  "intent": "meal_plan|shopping_add|budget_check|weekly_plan|unknown",\n'
      '  "reply": "Kullanıcıya verilecek kısa yanıt (max 100 karakter)",\n'
      '  "meal_plan": [\n'
      '    {\n'
      '      "day": "Pazartesi",\n'
      '      "meal": "Yemek adı",\n'
      '      "ingredients": ["malzeme1", "malzeme2"],\n'
      '      "cost_eur": 8.5,\n'
      '      "servings": 4\n'
      '    }\n'
      '  ],\n'
      '  "shopping_items": ["ürün1", "ürün2"],\n'
      '  "budget_eur": 60,\n'
      '  "estimated_cost_eur": 55.0\n'
      '}\n'
      'meal_plan alanı yalnızca yemek planı istendiğinde doldur. '
      'shopping_items alanı alışveriş listesine eklenecek malzemeleri listele. '
      'Yanıt HER ZAMAN geçerli JSON olsun.';

  /// Sistem talimatına kullanıcının izinli bağlamını ekler (Context Memory).
  ///
  /// Hata durumunda temel talimat KORUNUR — memory sorunu AI'ı bozmaz.
  String _withMemoryContext(String basePrompt, String userText) {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return basePrompt;
      final packet = MemoryContextService().buildPacket(
        userId: userId,
        query: userText,
      );
      return composeSystemPrompt(basePrompt: basePrompt, packet: packet);
    } catch (e) {
      AppLogger.logBestEffort(e, module: 'ai', operation: 'memoryContext');
      return basePrompt;
    }
  }

  /// Processes a natural-language command and executes cross-module actions.
  Future<AICommandResult> processCommand(String userText) async {
    final intent = _detectIntent(userText);

    // Build a context-aware prompt
    final prompt = _buildPrompt(userText, intent);

    // Context Memory: kullanıcının izin verdiği bağlamı ekle. Kayıt yoksa
    // veya oturum yoksa sistem talimatı AYNEN kalır (davranış değişmez).
    final systemPrompt = _withMemoryContext(_systemPrompt, userText);

    AIResponse aiResponse;
    try {
      aiResponse = await AIEngine.generate(
        prompt: prompt,
        systemPrompt: systemPrompt,
        format: AIResponseFormat.json,
        maxTokens: 1500,
        temperature: 0.4,
      );
    } catch (e) {
      return AICommandResult(
        userMessage: userText,
        assistantReply: 'Bağlantı hatası: ${e.toString().replaceAll("Exception: ", "")}',
        actions: [],
        intent: intent,
        hasErrors: true,
      );
    }

    // Parse AI JSON response
    Map<String, dynamic> parsed;
    try {
      final raw = aiResponse.content.trim();
      // Strip markdown code fences if present
      final json = raw.startsWith('```')
          ? raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1)
          : raw;
      parsed = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return AICommandResult(
        userMessage: userText,
        assistantReply: aiResponse.content,
        actions: [],
        intent: intent,
      );
    }

    final reply = parsed['reply'] as String? ??
        parsed['message'] as String? ??
        'İşleminiz tamamlandı.';
    final actions = <AssistantAction>[];

    // Execute shopping list additions.
    // Model bazen düz string, bazen {name/item}-nesne dizisi döner.
    final shoppingItems = ((parsed['shopping_items'] as List?) ?? [])
        .map((e) => e is Map
            ? (e['name'] ?? e['item'] ?? e['text'] ?? '').toString()
            : e.toString())
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (shoppingItems.isNotEmpty) {
      for (final item in shoppingItems) {
        try {
          await _shopping.createItem(item, category: ShoppingCategory.grocery);
          actions.add(AssistantAction(description: '"$item" alışveriş listesine eklendi'));
        } catch (e) {
          actions.add(AssistantAction(
            description: '"$item" eklenemedi',
            success: false,
            detail: e.toString(),
          ));
        }
      }
    }

    // Check budget feasibility
    final budgetEur = (parsed['budget_eur'] as num?)?.toDouble();
    final estimatedEur = (parsed['estimated_cost_eur'] as num?)?.toDouble();
    if (budgetEur != null && estimatedEur != null) {
      final withinBudget = estimatedEur <= budgetEur;
      actions.add(AssistantAction(
        description: withinBudget
            ? 'Bütçe uygun: tahmini €${estimatedEur.toStringAsFixed(0)} / €${budgetEur.toStringAsFixed(0)}'
            : 'Bütçe aşıldı: tahmini €${estimatedEur.toStringAsFixed(0)} / €${budgetEur.toStringAsFixed(0)}',
        success: withinBudget,
      ));
    }

    // Log meal plan summary as an action
    final mealPlan = (parsed['meal_plan'] as List?) ?? [];
    if (mealPlan.isNotEmpty) {
      actions.add(AssistantAction(
        description: '${mealPlan.length} günlük yemek planı oluşturuldu',
        detail: mealPlan.map((m) {
          final mm = m as Map?;
          return '${mm?['day']}: ${mm?['meal']}';
        }).join(', '),
      ));
    }

    return AICommandResult(
      userMessage: userText,
      assistantReply: reply,
      actions: actions,
      intent: intent,
      hasErrors: actions.any((a) => !a.success),
    );
  }

  /// Simple keyword-based pre-classification to guide the AI prompt.
  AssistantIntent _detectIntent(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('yemek plan') ||
        lower.contains('haftalık plan') ||
        lower.contains('menü')) {
      return AssistantIntent.mealPlan;
    }
    if (lower.contains('alışveriş') || lower.contains('liste')) {
      return AssistantIntent.addToShopping;
    }
    if (lower.contains('bütçe') || lower.contains('harcama') || lower.contains('euro')) {
      return AssistantIntent.budgetCheck;
    }
    if (lower.contains('hafta') || lower.contains('plan')) {
      return AssistantIntent.weeklyPlan;
    }
    return AssistantIntent.unknown;
  }

  String _buildPrompt(String userText, AssistantIntent intent) {
    final buffer = StringBuffer();
    buffer.writeln('Kullanıcı komutu: "$userText"');

    if (intent == AssistantIntent.mealPlan || intent == AssistantIntent.weeklyPlan) {
      buffer.writeln('Bu bir yemek planı isteği. Ekonomik, sağlıklı ve hazırlanması kolay yemekler seç.');
      buffer.writeln('Her gün için malzemeleri listele ve tahmini maliyeti euro cinsinden belirt.');
      buffer.writeln('Alışveriş listesine eklenecek TÜM malzemeleri "shopping_items" alanında listele.');
    } else if (intent == AssistantIntent.addToShopping) {
      buffer.writeln('Bu bir alışveriş listesi isteği. "shopping_items" alanını doldur.');
    } else if (intent == AssistantIntent.budgetCheck) {
      buffer.writeln('Bu bir bütçe kontrolü isteği. Maliyet tahminini euro cinsinden ver.');
    }

    buffer.writeln('\nJSon formatında yanıt ver.');
    return buffer.toString();
  }
}
