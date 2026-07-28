import 'dart:convert';

/// family-ai Edge Function structured response kontratı (§13).
///
/// Serbest metin yerine tipli yanıt. Flutter parser tüm tipleri exhaustive ele
/// alır; BİLİNMEYEN tip uygulamayı çökertmez (safe fallback).
enum FamilyAiResponseType {
  answer,
  clarification,
  actionProposal,
  actionResult,
  error,
  safetyNotice,
  navigation,
  unknown,
}

class ExecutedAction {
  final String tool;
  final String status; // "success" | "error"
  final bool persisted;
  final String? resourceId;
  const ExecutedAction({
    required this.tool,
    required this.status,
    required this.persisted,
    this.resourceId,
  });

  /// KRİTİK (§12): bir işlem yalnızca gerçekten kalıcı yazıldıysa başarılıdır.
  /// Model metni ASLA başarı kanıtı sayılmaz.
  bool get isRealSuccess => status == 'success' && persisted == true;

  factory ExecutedAction.fromJson(Map<String, dynamic> j) => ExecutedAction(
        tool: j['tool']?.toString() ?? '',
        status: j['status']?.toString() ?? 'error',
        persisted: j['persisted'] == true,
        resourceId: j['resourceId']?.toString() ?? j['resource_id']?.toString(),
      );
}

class FamilyAiResponse {
  final String requestId;
  final FamilyAiResponseType type;
  final String text;
  final List<String> suggestions;
  final List<ExecutedAction> executedActions;
  final List<String> warnings;
  final String? model;
  final String? errorCode;

  const FamilyAiResponse({
    required this.requestId,
    required this.type,
    required this.text,
    this.suggestions = const [],
    this.executedActions = const [],
    this.warnings = const [],
    this.model,
    this.errorCode,
  });

  /// UI "işlem tamamlandı" göstergesini SADECE gerçek başarı varsa gösterir.
  /// Model "takvime eklendi" dese bile, executed_actions içinde isRealSuccess
  /// yoksa completed action gösterilmez.
  bool get hasCompletedAction => executedActions.any((a) => a.isRealSuccess);

  static FamilyAiResponseType _parseType(String? raw) {
    switch (raw) {
      case 'answer':
        return FamilyAiResponseType.answer;
      case 'clarification':
        return FamilyAiResponseType.clarification;
      case 'action_proposal':
        return FamilyAiResponseType.actionProposal;
      case 'action_result':
        return FamilyAiResponseType.actionResult;
      case 'error':
        return FamilyAiResponseType.error;
      case 'safety_notice':
        return FamilyAiResponseType.safetyNotice;
      case 'navigation':
        return FamilyAiResponseType.navigation;
      default:
        return FamilyAiResponseType.unknown; // bilinmeyen → crash YOK
    }
  }

  factory FamilyAiResponse.fromJson(Map<String, dynamic> j) {
    return FamilyAiResponse(
      requestId: j['request_id']?.toString() ?? '',
      type: _parseType(j['type']?.toString()),
      text: j['text']?.toString() ?? '',
      suggestions: ((j['suggestions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      executedActions: ((j['executed_actions'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExecutedAction.fromJson)
          .toList(),
      warnings: ((j['warnings'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      model: j['model']?.toString(),
      errorCode: j['error_code']?.toString(),
    );
  }

  /// Ham gövdeyi güvenle parse eder; bozuk JSON → error tipi (crash yok).
  static FamilyAiResponse parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return FamilyAiResponse.fromJson(decoded);
      }
    } catch (_) {}
    return const FamilyAiResponse(
      requestId: '',
      type: FamilyAiResponseType.error,
      text: '',
      errorCode: 'INVALID_RESPONSE',
    );
  }
}
