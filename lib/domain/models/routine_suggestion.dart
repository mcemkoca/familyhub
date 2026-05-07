import 'routine.dart';

enum SuggestionType { newRoutine, modifyRoutine, removeRoutine, reorderSteps }

enum SuggestionStatus { pending, accepted, rejected, implemented }

class RoutineSuggestion {
  final String id;
  final String familyId;
  final SuggestionType type;
  final String reason;
  final double confidence;
  final List<SuggestionBasis> basedOn;
  final Routine? suggestedRoutine;
  final SuggestionStatus status;

  const RoutineSuggestion({
    required this.id,
    required this.familyId,
    this.type = SuggestionType.newRoutine,
    required this.reason,
    this.confidence = 0.5,
    this.basedOn = const [],
    this.suggestedRoutine,
    this.status = SuggestionStatus.pending,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'type': type.name,
        'reason': reason,
        'confidence': confidence,
        'based_on': basedOn.map((b) => b.toJson()).toList(),
        'suggested_routine': suggestedRoutine?.toJson(),
        'status': status.name,
      };

  factory RoutineSuggestion.fromJson(Map<String, dynamic> json) =>
      RoutineSuggestion(
        id: json['id'] as String? ?? '',
        familyId: json['family_id'] as String? ?? '',
        type: SuggestionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SuggestionType.newRoutine,
        ),
        reason: json['reason'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        basedOn: (json['based_on'] as List?)
                ?.map((b) => SuggestionBasis.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        suggestedRoutine: json['suggested_routine'] != null
            ? Routine.fromJson(json['suggested_routine'] as Map<String, dynamic>)
            : null,
        status: SuggestionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SuggestionStatus.pending,
        ),
      );
}

class SuggestionBasis {
  final String pattern;
  final String data;

  const SuggestionBasis({
    required this.pattern,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'data': data,
      };

  factory SuggestionBasis.fromJson(Map<String, dynamic> json) =>
      SuggestionBasis(
        pattern: json['pattern'] as String? ?? '',
        data: json['data'] as String? ?? '',
      );
}
