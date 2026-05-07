import 'package:flutter/material.dart';

class AiSuggestion {
  final String id;
  final String title;
  final String description;
  final String type; // location, time, task, habit, schedule
  final String reason;
  final IconData icon;
  final Color color;
  final String? actionLabel; // "Ekle", "Tamamla", vb.
  final Map<String, dynamic>? actionPayload; // Görev eklerken kullanılacak data

  const AiSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.reason,
    required this.icon,
    required this.color,
    this.actionLabel = 'Ekle',
    this.actionPayload,
  });

  AiSuggestion copyWith({bool? isApplied}) {
    return AiSuggestion(
      id: id,
      title: title,
      description: description,
      type: type,
      reason: reason,
      icon: icon,
      color: color,
      actionLabel: actionLabel,
      actionPayload: actionPayload,
    );
  }
}

// ── Hub AI Suggestions (rich cards) ───────────────────────────────────────

class AISuggestion {
  final String id;
  final String title;
  final String description;
  final String type;
  final bool isNew;
  final String? badge;
  final bool isFavorite;
  final int? durationMinutes;
  final int? calories;
  final int? servings;
  final String? difficulty;
  final String? estimatedCost;
  final bool allowAlternatives;
  final bool shareable;
  final List<Ingredient> ingredients;
  final NutritionInfo? nutritionInfo;
  final int progress;
  final List<String> tips;
  final List<AlternativeOption> alternativeOptions;
  final String action;
  final String? userComment;
  final List<String>? steps;
  final String? assignedTo;
  final String? lastDone;
  final String? weatherContext;
  final List<String> tags;
  final int? minAge;
  final int? maxAge;

  const AISuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isNew = false,
    this.badge,
    this.isFavorite = false,
    this.durationMinutes,
    this.calories,
    this.servings,
    this.difficulty,
    this.estimatedCost,
    this.allowAlternatives = false,
    this.shareable = false,
    this.ingredients = const [],
    this.nutritionInfo,
    this.progress = 0,
    this.tips = const [],
    this.alternativeOptions = const [],
    this.action = '',
    this.userComment,
    this.steps,
    this.assignedTo,
    this.lastDone,
    this.weatherContext,
    this.tags = const [],
    this.minAge,
    this.maxAge,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isNew: json['is_new'] as bool? ?? json['isNew'] as bool? ?? false,
      badge: json['badge'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? json['isFavorite'] as bool? ?? false,
      durationMinutes: json['duration_minutes'] as int? ?? json['durationMinutes'] as int?,
      calories: json['calories'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      estimatedCost: json['estimated_cost'] as String? ?? json['estimatedCost'] as String?,
      allowAlternatives: json['allow_alternatives'] as bool? ?? json['allowAlternatives'] as bool? ?? false,
      shareable: json['shareable'] as bool? ?? false,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutritionInfo: json['nutrition_info'] != null || json['nutritionInfo'] != null
          ? NutritionInfo.fromJson((json['nutrition_info'] ?? json['nutritionInfo']) as Map<String, dynamic>)
          : null,
      progress: json['progress'] as int? ?? 0,
      tips: (json['tips'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      alternativeOptions: (json['alternative_options'] as List<dynamic>? ?? json['alternativeOptions'] as List<dynamic>? ?? [])
          .map((e) => AlternativeOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      action: json['action'] as String? ?? '',
      userComment: json['user_comment'] as String? ?? json['userComment'] as String?,
      steps: (json['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      assignedTo: json['assigned_to'] as String? ?? json['assignedTo'] as String?,
      lastDone: json['last_done'] as String? ?? json['lastDone'] as String?,
      weatherContext: json['weather_context'] as String? ?? json['weatherContext'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      minAge: json['min_age'] as int? ?? json['minAge'] as int?,
      maxAge: json['max_age'] as int? ?? json['maxAge'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'is_new': isNew,
    'badge': badge,
    'is_favorite': isFavorite,
    'duration_minutes': durationMinutes,
    'calories': calories,
    'servings': servings,
    'difficulty': difficulty,
    'estimated_cost': estimatedCost,
    'allow_alternatives': allowAlternatives,
    'shareable': shareable,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'nutrition_info': nutritionInfo?.toJson(),
    'progress': progress,
    'tips': tips,
    'alternative_options': alternativeOptions.map((a) => {'title': a.title, 'description': a.description, 'reason': a.reason}).toList(),
    'action': action,
    'user_comment': userComment,
    'steps': steps,
    'assigned_to': assignedTo,
    'last_done': lastDone,
    'weather_context': weatherContext,
    'tags': tags,
    'min_age': minAge,
    'max_age': maxAge,
  };

  AISuggestion copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    bool? isNew,
    String? badge,
    bool? isFavorite,
    int? durationMinutes,
    int? calories,
    int? servings,
    String? difficulty,
    String? estimatedCost,
    bool? allowAlternatives,
    bool? shareable,
    List<Ingredient>? ingredients,
    NutritionInfo? nutritionInfo,
    int? progress,
    List<String>? tips,
    List<AlternativeOption>? alternativeOptions,
    String? action,
    String? userComment,
    List<String>? steps,
    String? assignedTo,
    String? lastDone,
    String? weatherContext,
    List<String>? tags,
    int? minAge,
    int? maxAge,
  }) {
    return AISuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isNew: isNew ?? this.isNew,
      badge: badge ?? this.badge,
      isFavorite: isFavorite ?? this.isFavorite,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      calories: calories ?? this.calories,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      allowAlternatives: allowAlternatives ?? this.allowAlternatives,
      shareable: shareable ?? this.shareable,
      ingredients: ingredients ?? this.ingredients,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      progress: progress ?? this.progress,
      tips: tips ?? this.tips,
      alternativeOptions: alternativeOptions ?? this.alternativeOptions,
      action: action ?? this.action,
      userComment: userComment ?? this.userComment,
      steps: steps ?? this.steps,
      assignedTo: assignedTo ?? this.assignedTo,
      lastDone: lastDone ?? this.lastDone,
      weatherContext: weatherContext ?? this.weatherContext,
      tags: tags ?? this.tags,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
    );
  }
}

class Ingredient {
  final String name;
  final String amount;
  final bool inStock;

  const Ingredient({
    required this.name,
    required this.amount,
    this.inStock = true,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    name: json['name'] as String? ?? '',
    amount: json['amount'] as String? ?? '',
    inStock: json['in_stock'] as bool? ?? json['inStock'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'in_stock': inStock,
  };
}

class NutritionInfo {
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  const NutritionInfo({this.protein, this.carbs, this.fat, this.fiber});

  bool get hasAnyValue => protein != null || carbs != null || fat != null || fiber != null;

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
    protein: (json['protein'] as num?)?.toDouble(),
    carbs: (json['carbs'] as num?)?.toDouble(),
    fat: (json['fat'] as num?)?.toDouble(),
    fiber: (json['fiber'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
  };
}

class AlternativeOption {
  final String title;
  final String description;
  final String? reason;

  const AlternativeOption({
    required this.title,
    required this.description,
    this.reason,
  });

  factory AlternativeOption.fromJson(Map<String, dynamic> json) => AlternativeOption(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    reason: json['reason'] as String?,
  );
}
