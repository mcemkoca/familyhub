/// Typed data models for the FamilyHub Content Engine.
/// All models are immutable and JSON-serializable.
library;

// ── Child Development ───────────────────────────────────────────────────

class ChildDevelopmentData {
  final String module;
  final String version;
  final String language;
  final String region;
  final Map<String, AgeGroup> ageGroups;
  final List<String> universalSafetyNotes;
  final List<String> sources;

  const ChildDevelopmentData({
    required this.module,
    required this.version,
    required this.language,
    required this.region,
    required this.ageGroups,
    required this.universalSafetyNotes,
    required this.sources,
  });

  factory ChildDevelopmentData.fromJson(Map<String, dynamic> json) {
    return ChildDevelopmentData(
      module: json['module'] as String,
      version: json['version'] as String,
      language: json['language'] as String,
      region: json['region'] as String,
      ageGroups: (json['age_groups'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, AgeGroup.fromJson(v as Map<String, dynamic>)),
      ),
      universalSafetyNotes: (json['universal_safety_notes'] as List<dynamic>)
          .cast<String>(),
      sources: (json['sources'] as List<dynamic>).cast<String>(),
    );
  }
}

class AgeGroup {
  final Milestones milestones;
  final List<String> redFlags;
  final List<Activity> activities;
  final List<String> nutritionTips;
  final SleepGuidelines sleepGuidelines;

  const AgeGroup({
    required this.milestones,
    required this.redFlags,
    required this.activities,
    required this.nutritionTips,
    required this.sleepGuidelines,
  });

  factory AgeGroup.fromJson(Map<String, dynamic> json) {
    return AgeGroup(
      milestones: Milestones.fromJson(
        json['milestones'] as Map<String, dynamic>,
      ),
      redFlags: (json['red_flags'] as List<dynamic>).cast<String>(),
      activities: (json['activities'] as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutritionTips: (json['nutrition_tips'] as List<dynamic>).cast<String>(),
      sleepGuidelines: SleepGuidelines.fromJson(
        json['sleep_guidelines'] as Map<String, dynamic>,
      ),
    );
  }
}

class Milestones {
  final List<String> physical;
  final List<String> cognitive;
  final List<String> language;
  final List<String> socialEmotional;

  const Milestones({
    required this.physical,
    required this.cognitive,
    required this.language,
    required this.socialEmotional,
  });

  factory Milestones.fromJson(Map<String, dynamic> json) {
    return Milestones(
      physical: (json['physical'] as List<dynamic>).cast<String>(),
      cognitive: (json['cognitive'] as List<dynamic>).cast<String>(),
      language: (json['language'] as List<dynamic>).cast<String>(),
      socialEmotional: (json['social_emotional'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

class Activity {
  final String name;
  final String description;
  final int durationMinutes;
  final List<String> materials;
  final String learningOutcome;
  final String safetyNotes;
  final String? turkishCulturalContext;
  final String? ageRange;

  const Activity({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.materials,
    required this.learningOutcome,
    required this.safetyNotes,
    this.turkishCulturalContext,
    this.ageRange,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'] as String,
      description: json['description'] as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 15,
      materials: (json['materials'] as List<dynamic>).cast<String>(),
      learningOutcome: json['learning_outcome'] as String? ?? '',
      safetyNotes: json['safety_notes'] as String? ?? '',
      turkishCulturalContext: json['turkish_cultural_context'] as String?,
      ageRange: json['age_range'] as String?,
    );
  }
}

class SleepGuidelines {
  final String hours;
  final List<String> scheduleTips;

  const SleepGuidelines({required this.hours, required this.scheduleTips});

  factory SleepGuidelines.fromJson(Map<String, dynamic> json) {
    return SleepGuidelines(
      hours: json['hours'] as String,
      scheduleTips: (json['schedule_tips'] as List<dynamic>).cast<String>(),
    );
  }
}

// ── Meal Planning ───────────────────────────────────────────────────────

class MealPlanningData {
  final String module;
  final String version;
  final List<Recipe> recipes;
  final Map<String, DailyMeals> weeklyTemplate;
  final List<String> mealTips;

  const MealPlanningData({
    required this.module,
    required this.version,
    required this.recipes,
    required this.weeklyTemplate,
    required this.mealTips,
  });

  factory MealPlanningData.fromJson(Map<String, dynamic> json) {
    return MealPlanningData(
      module: json['module'] as String,
      version: json['version'] as String,
      recipes: (json['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyTemplate: (json['weekly_template'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, DailyMeals.fromJson(v as Map<String, dynamic>)),
      ),
      mealTips: (json['meal_tips'] as List<dynamic>).cast<String>(),
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final String prepTime;
  final String cookTime;
  final int servings;
  final String difficulty;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final List<String> nutritionalHighlights;
  final String kidFriendlyModifications;
  final double costEstimateEur;
  final String season;
  final List<String> tags;
  final String? turkishCuisineCategory;
  final String? story;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    required this.nutritionalHighlights,
    required this.kidFriendlyModifications,
    required this.costEstimateEur,
    required this.season,
    required this.tags,
    this.turkishCuisineCategory,
    this.story,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      prepTime: json['prep_time'] as String,
      cookTime: json['cook_time'] as String,
      servings: json['servings'] as int,
      difficulty: json['difficulty'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>).cast<String>(),
      nutritionalHighlights: (json['nutritional_highlights'] as List<dynamic>)
          .cast<String>(),
      kidFriendlyModifications: json['kid_friendly_modifications'] as String,
      costEstimateEur: (json['cost_estimate_eur'] as num).toDouble(),
      season: json['season'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      turkishCuisineCategory: json['turkish_cuisine_category'] as String?,
      story: json['story'] as String?,
    );
  }
}

class Ingredient {
  final String item;
  final String amount;
  final String? alternative;
  final String? belgiumAvailability;

  const Ingredient({
    required this.item,
    required this.amount,
    this.alternative,
    this.belgiumAvailability,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      item: json['item'] as String,
      amount: json['amount'] as String,
      alternative: json['alternative'] as String?,
      belgiumAvailability: json['belgium_availability'] as String?,
    );
  }
}

class DailyMeals {
  final String breakfast;
  final String lunch;
  final String dinner;

  const DailyMeals({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory DailyMeals.fromJson(Map<String, dynamic> json) {
    return DailyMeals(
      breakfast: json['breakfast'] as String,
      lunch: json['lunch'] as String,
      dinner: json['dinner'] as String,
    );
  }
}

// ── Household ───────────────────────────────────────────────────────────

class HouseholdData {
  final String module;
  final String version;
  final List<DailyRoutine> dailyRoutines;
  final Map<String, String> weeklySchedule;
  final Map<String, RoomGuide> roomGuides;
  final Map<String, List<String>> seasonalTasks;
  final Gamification gamification;
  final List<String> ecoTips;

  const HouseholdData({
    required this.module,
    required this.version,
    required this.dailyRoutines,
    required this.weeklySchedule,
    required this.roomGuides,
    required this.seasonalTasks,
    required this.gamification,
    required this.ecoTips,
  });

  factory HouseholdData.fromJson(Map<String, dynamic> json) {
    return HouseholdData(
      module: json['module'] as String,
      version: json['version'] as String,
      dailyRoutines: (json['daily_routines'] as List<dynamic>)
          .map((e) => DailyRoutine.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklySchedule: (json['weekly_schedule'] as Map<String, dynamic>)
          .cast<String, String>(),
      roomGuides: (json['room_guides'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, RoomGuide.fromJson(v as Map<String, dynamic>)),
      ),
      seasonalTasks: (json['seasonal_tasks'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
      ),
      gamification: Gamification.fromJson(
        json['gamification'] as Map<String, dynamic>,
      ),
      ecoTips: (json['eco_tips'] as List<dynamic>).cast<String>(),
    );
  }
}

class DailyRoutine {
  final String name;
  final String time;
  final List<String> tasks;
  final String familyRole;

  const DailyRoutine({
    required this.name,
    required this.time,
    required this.tasks,
    required this.familyRole,
  });

  factory DailyRoutine.fromJson(Map<String, dynamic> json) {
    return DailyRoutine(
      name: json['name'] as String,
      time: json['time'] as String,
      tasks: (json['tasks'] as List<dynamic>).cast<String>(),
      familyRole: json['family_role'] as String,
    );
  }
}

class RoomGuide {
  final String deepCleanFrequency;
  final List<String> tips;

  const RoomGuide({required this.deepCleanFrequency, required this.tips});

  factory RoomGuide.fromJson(Map<String, dynamic> json) {
    return RoomGuide(
      deepCleanFrequency: json['deep_clean_frequency'] as String,
      tips: (json['tips'] as List<dynamic>).cast<String>(),
    );
  }
}

class Gamification {
  final Map<String, int> pointSystem;
  final List<String> rewards;

  const Gamification({required this.pointSystem, required this.rewards});

  factory Gamification.fromJson(Map<String, dynamic> json) {
    return Gamification(
      pointSystem: (json['point_system'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      rewards: (json['rewards'] as List<dynamic>).cast<String>(),
    );
  }
}

// ── Budget ──────────────────────────────────────────────────────────────

class BudgetData {
  final String module;
  final String version;
  final String currency;
  final SampleBudget sampleBudget;
  final BelgiumBenefits belgiumBenefits;
  final List<SavingStrategy> savingStrategies;
  final List<CostCuttingTip> costCuttingTips;
  final EmergencyFund emergencyFund;

  const BudgetData({
    required this.module,
    required this.version,
    required this.currency,
    required this.sampleBudget,
    required this.belgiumBenefits,
    required this.savingStrategies,
    required this.costCuttingTips,
    required this.emergencyFund,
  });

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    return BudgetData(
      module: json['module'] as String,
      version: json['version'] as String,
      currency: json['currency'] as String,
      sampleBudget: SampleBudget.fromJson(
        json['sample_family_budget'] as Map<String, dynamic>,
      ),
      belgiumBenefits: BelgiumBenefits.fromJson(
        json['belgium_specific_benefits'] as Map<String, dynamic>,
      ),
      savingStrategies: (json['saving_strategies'] as List<dynamic>)
          .map((e) => SavingStrategy.fromJson(e as Map<String, dynamic>))
          .toList(),
      costCuttingTips: (json['cost_cutting_tips'] as List<dynamic>)
          .map((e) => CostCuttingTip.fromJson(e as Map<String, dynamic>))
          .toList(),
      emergencyFund: EmergencyFund.fromJson(
        json['emergency_fund'] as Map<String, dynamic>,
      ),
    );
  }
}

class SampleBudget {
  final int monthlyIncome;
  final Map<String, BudgetCategory> allocation;

  const SampleBudget({required this.monthlyIncome, required this.allocation});

  factory SampleBudget.fromJson(Map<String, dynamic> json) {
    return SampleBudget(
      monthlyIncome: json['monthly_income'] as int,
      allocation: (json['allocation'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, BudgetCategory.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

class BudgetCategory {
  final int amount;
  final double percentage;
  final String type;

  const BudgetCategory({
    required this.amount,
    required this.percentage,
    required this.type,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      amount: json['amount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      type: json['type'] as String,
    );
  }
}

class BelgiumBenefits {
  final Map<String, dynamic> raw;
  const BelgiumBenefits({required this.raw});
  factory BelgiumBenefits.fromJson(Map<String, dynamic> json) =>
      BelgiumBenefits(raw: json);
}

class SavingStrategy {
  final String name;
  final String description;
  final String difficulty;
  final String estimatedSavings;

  const SavingStrategy({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.estimatedSavings,
  });

  factory SavingStrategy.fromJson(Map<String, dynamic> json) {
    return SavingStrategy(
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      estimatedSavings: json['estimated_savings'] as String,
    );
  }
}

class CostCuttingTip {
  final String category;
  final String tip;
  final int monthlySavingsEur;

  const CostCuttingTip({
    required this.category,
    required this.tip,
    required this.monthlySavingsEur,
  });

  factory CostCuttingTip.fromJson(Map<String, dynamic> json) {
    return CostCuttingTip(
      category: json['category'] as String,
      tip: json['tip'] as String,
      monthlySavingsEur: json['monthly_savings_eur'] as int,
    );
  }
}

class EmergencyFund {
  final int recommendedMonths;
  final int forFamiliesMonths;
  final String calculationExample;

  const EmergencyFund({
    required this.recommendedMonths,
    required this.forFamiliesMonths,
    required this.calculationExample,
  });

  factory EmergencyFund.fromJson(Map<String, dynamic> json) {
    return EmergencyFund(
      recommendedMonths: json['recommended_months'] as int,
      forFamiliesMonths: json['for_families_months'] as int,
      calculationExample: json['calculation_example'] as String,
    );
  }
}

// ── Future Planning ─────────────────────────────────────────────────────

class FuturePlanningData {
  final String module;
  final String version;
  final Map<String, dynamic> educationPathways;
  final EmergencyPlan emergencyPlan;
  final GoalFramework goalFramework;
  final List<String> legalChecklist;

  const FuturePlanningData({
    required this.module,
    required this.version,
    required this.educationPathways,
    required this.emergencyPlan,
    required this.goalFramework,
    required this.legalChecklist,
  });

  factory FuturePlanningData.fromJson(Map<String, dynamic> json) {
    return FuturePlanningData(
      module: json['module'] as String,
      version: json['version'] as String,
      educationPathways:
          json['education_pathways_belgium'] as Map<String, dynamic>,
      emergencyPlan: EmergencyPlan.fromJson(
        json['emergency_plan_template'] as Map<String, dynamic>,
      ),
      goalFramework: GoalFramework.fromJson(
        json['goal_setting_framework'] as Map<String, dynamic>,
      ),
      legalChecklist: (json['legal_checklist_belgium'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

class EmergencyPlan {
  final List<EmergencyContact> contacts;
  final List<String> documentsToKeep;
  final Map<String, String> financialBuffer;

  const EmergencyPlan({
    required this.contacts,
    required this.documentsToKeep,
    required this.financialBuffer,
  });

  factory EmergencyPlan.fromJson(Map<String, dynamic> json) {
    return EmergencyPlan(
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      documentsToKeep: (json['documents_to_keep'] as List<dynamic>)
          .cast<String>(),
      financialBuffer: (json['financial_buffer'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  }
}

class EmergencyContact {
  final String name;
  final String number;
  final String role;

  const EmergencyContact({
    required this.name,
    required this.number,
    required this.role,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      number: json['number'] as String,
      role: json['role'] as String,
    );
  }
}

class GoalFramework {
  final GoalPeriod shortTerm;
  final GoalPeriod mediumTerm;
  final GoalPeriod longTerm;

  const GoalFramework({
    required this.shortTerm,
    required this.mediumTerm,
    required this.longTerm,
  });

  factory GoalFramework.fromJson(Map<String, dynamic> json) {
    return GoalFramework(
      shortTerm: GoalPeriod.fromJson(
        json['short_term'] as Map<String, dynamic>,
      ),
      mediumTerm: GoalPeriod.fromJson(
        json['medium_term'] as Map<String, dynamic>,
      ),
      longTerm: GoalPeriod.fromJson(json['long_term'] as Map<String, dynamic>),
    );
  }
}

class GoalPeriod {
  final String horizon;
  final List<String> examples;

  const GoalPeriod({required this.horizon, required this.examples});

  factory GoalPeriod.fromJson(Map<String, dynamic> json) {
    return GoalPeriod(
      horizon: json['horizon'] as String,
      examples: (json['examples'] as List<dynamic>).cast<String>(),
    );
  }
}
