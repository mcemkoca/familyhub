import 'routine.dart';

enum TemplateCategory { health, productivity, family, cleaning, education }

class RoutineTemplate {
  final String id;
  final String name;
  final String? description;
  final TemplateCategory category;
  final RoutineDifficulty difficulty;
  final int estimatedTotalDuration;
  final List<TemplateStep> steps;
  final Suitability suitability;
  final int usageCount;
  final double averageRating;
  final List<TemplateReview> userReviews;

  const RoutineTemplate({
    required this.id,
    required this.name,
    this.description,
    this.category = TemplateCategory.family,
    this.difficulty = RoutineDifficulty.medium,
    this.estimatedTotalDuration = 30,
    this.steps = const [],
    this.suitability = const Suitability(),
    this.usageCount = 0,
    this.averageRating = 0,
    this.userReviews = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'estimated_total_duration': estimatedTotalDuration,
        'steps': steps.map((s) => s.toJson()).toList(),
        'suitability': suitability.toJson(),
        'usage_count': usageCount,
        'average_rating': averageRating,
        'user_reviews': userReviews.map((r) => r.toJson()).toList(),
      };

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) => RoutineTemplate(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        category: TemplateCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => TemplateCategory.family,
        ),
        difficulty: RoutineDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => RoutineDifficulty.medium,
        ),
        estimatedTotalDuration: json['estimated_total_duration'] as int? ?? 30,
        steps: (json['steps'] as List?)
                ?.map((s) => TemplateStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        suitability: json['suitability'] != null
            ? Suitability.fromJson(json['suitability'] as Map<String, dynamic>)
            : const Suitability(),
        usageCount: json['usage_count'] as int? ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        userReviews: (json['user_reviews'] as List?)
                ?.map((r) => TemplateReview.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TemplateStep {
  final String id;
  final String title;
  final String? description;
  final int estimatedDuration;
  final String category;

  const TemplateStep({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration = 5,
    this.category = 'general',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'estimated_duration': estimatedDuration,
        'category': category,
      };

  factory TemplateStep.fromJson(Map<String, dynamic> json) => TemplateStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        estimatedDuration: json['estimated_duration'] as int? ?? 5,
        category: json['category'] as String? ?? 'general',
      );
}

class Suitability {
  final int? minAge;
  final int? maxAge;
  final String? familySize;
  final List<String> lifestyle;

  const Suitability({
    this.minAge,
    this.maxAge,
    this.familySize,
    this.lifestyle = const [],
  });

  Map<String, dynamic> toJson() => {
        'min_age': minAge,
        'max_age': maxAge,
        'family_size': familySize,
        'lifestyle': lifestyle,
      };

  factory Suitability.fromJson(Map<String, dynamic> json) => Suitability(
        minAge: json['min_age'] as int?,
        maxAge: json['max_age'] as int?,
        familySize: json['family_size'] as String?,
        lifestyle: (json['lifestyle'] as List?)?.cast<String>() ?? [],
      );
}

class TemplateReview {
  final String userId;
  final double rating;
  final String? comment;

  const TemplateReview({
    required this.userId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      };

  factory TemplateReview.fromJson(Map<String, dynamic> json) => TemplateReview(
        userId: json['user_id'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String?,
      );
}
