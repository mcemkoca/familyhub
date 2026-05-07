// Smart Task Rotation Domain Models
// Akıllı Görev Rotasyonu Veri Modelleri

/// Görev kategorileri
enum TaskCategory {
  cleaning, // temizlik
  cooking, // yemek
  shopping, // alışveriş
  maintenance, // bakım
  education, // eğitim
  social, // sosyal
  admin, // idari
  urgent, // acil
}

/// Görev zorluğu
enum TaskDifficulty { easy, medium, hard, expert }

/// Enerji seviyesi
enum EnergyLevel { low, medium, high }

/// Zaman dilimi
enum TimeSlot { morning, afternoon, evening, any }

/// Görev durumu
enum RotationStatus { pending, assigned, inProgress, completed, postponed, rejected }

/// Görev modeli (Rotasyon için genişletilmiş)
class RotationTask {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final String priority; // low, normal, high, urgent
  final int estimatedDuration; // dakika
  final TaskDifficulty difficulty;
  final List<String> requiredSkills;
  final int? requiredAge;
  final bool isRecurring;
  final String? recurrencePattern; // "daily", "weekly:mon,wed,fri"
  final TimeSlot preferredTimeSlot;
  final String location; // "ev", "dışarı", "online"
  final EnergyLevel energyLevel;

  // Dağıtım durumu
  final String? assignedTo;
  final DateTime? assignedAt;
  final DateTime? dueDate;
  final RotationStatus status;
  final DateTime? completedAt;
  final int? completionQuality; // 1-5

  // Meta
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  const RotationTask({
    required this.id,
    required this.title,
    this.description,
    this.category = TaskCategory.cleaning,
    this.priority = 'normal',
    this.estimatedDuration = 30,
    this.difficulty = TaskDifficulty.easy,
    this.requiredSkills = const [],
    this.requiredAge,
    this.isRecurring = false,
    this.recurrencePattern,
    this.preferredTimeSlot = TimeSlot.any,
    this.location = 'ev',
    this.energyLevel = EnergyLevel.medium,
    this.assignedTo,
    this.assignedAt,
    this.dueDate,
    this.status = RotationStatus.pending,
    this.completedAt,
    this.completionQuality,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  RotationTask copyWith({
    String? assignedTo,
    DateTime? assignedAt,
    DateTime? dueDate,
    RotationStatus? status,
    DateTime? completedAt,
    int? completionQuality,
  }) {
    return RotationTask(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      estimatedDuration: estimatedDuration,
      difficulty: difficulty,
      requiredSkills: requiredSkills,
      requiredAge: requiredAge,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      preferredTimeSlot: preferredTimeSlot,
      location: location,
      energyLevel: energyLevel,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAt: assignedAt ?? this.assignedAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completionQuality: completionQuality ?? this.completionQuality,
      createdBy: createdBy,
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'priority': priority,
    'estimatedDuration': estimatedDuration,
    'difficulty': difficulty.name,
    'requiredSkills': requiredSkills,
    'requiredAge': requiredAge,
    'isRecurring': isRecurring,
    'recurrencePattern': recurrencePattern,
    'preferredTimeSlot': preferredTimeSlot.name,
    'location': location,
    'energyLevel': energyLevel.name,
    'assignedTo': assignedTo,
    'assignedAt': assignedAt?.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'status': status.name,
    'completedAt': completedAt?.toIso8601String(),
    'completionQuality': completionQuality,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory RotationTask.fromJson(Map<String, dynamic> json) {
    return RotationTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.cleaning,
      ),
      priority: json['priority'] as String? ?? 'normal',
      estimatedDuration: json['estimatedDuration'] as int? ?? 30,
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => TaskDifficulty.easy,
      ),
      requiredSkills:
          (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiredAge: json['requiredAge'] as int?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] as String?,
      preferredTimeSlot: TimeSlot.values.firstWhere(
        (e) => e.name == json['preferredTimeSlot'],
        orElse: () => TimeSlot.any,
      ),
      location: json['location'] as String? ?? 'ev',
      energyLevel: EnergyLevel.values.firstWhere(
        (e) => e.name == json['energyLevel'],
        orElse: () => EnergyLevel.medium,
      ),
      assignedTo: json['assignedTo'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      status: RotationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RotationStatus.pending,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completionQuality: json['completionQuality'] as int?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Üye rolü
enum MemberRole { parent, child, grandparent, grandparentM, other }

/// Zaman aralığı
class TimeRange {
  final String start; // "08:00"
  final String end; // "09:00"

  const TimeRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }
}

/// Aile üyesi (rotasyon için)
class RotationMember {
  final String id;
  final String name;
  final String? avatar;
  final MemberRole role;
  final int age;

  // Beceriler ve tercihler
  final List<String> skills;
  final List<String> preferredCategories;
  final List<String> avoidedCategories;

  // Zaman uygunluğu
  final Map<String, List<TimeRange>> availability; // "monday": [{start, end}]

  // Workload takibi
  final MemberWorkload workload;

  // Enerji profili
  final EnergyProfile energyProfile;

  // Konum
  final String currentLocation;

  // Bildirim tercihleri
  final NotificationPrefs notifications;

  const RotationMember({
    required this.id,
    required this.name,
    this.avatar,
    this.role = MemberRole.other,
    required this.age,
    this.skills = const [],
    this.preferredCategories = const [],
    this.avoidedCategories = const [],
    this.availability = const {},
    required this.workload,
    required this.energyProfile,
    this.currentLocation = 'ev',
    required this.notifications,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'role': role.name,
    'age': age,
    'skills': skills,
    'preferredCategories': preferredCategories,
    'avoidedCategories': avoidedCategories,
    'availability': availability.map(
      (k, v) => MapEntry(k, v.map((t) => t.toJson()).toList()),
    ),
    'workload': workload.toJson(),
    'energyProfile': energyProfile.toJson(),
    'currentLocation': currentLocation,
    'notifications': notifications.toJson(),
  };

  factory RotationMember.fromJson(Map<String, dynamic> json) {
    final availRaw = json['availability'] as Map<String, dynamic>?;
    final availability = <String, List<TimeRange>>{};
    if (availRaw != null) {
      for (final entry in availRaw.entries) {
        availability[entry.key] = (entry.value as List<dynamic>)
            .map((e) => TimeRange.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return RotationMember(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: MemberRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MemberRole.other,
      ),
      age: json['age'] as int? ?? 0,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredCategories:
          (json['preferredCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      avoidedCategories:
          (json['avoidedCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      availability: availability,
      workload: MemberWorkload.fromJson(
        json['workload'] as Map<String, dynamic>? ?? {},
      ),
      energyProfile: EnergyProfile.fromJson(
        json['energyProfile'] as Map<String, dynamic>? ?? {},
      ),
      currentLocation: json['currentLocation'] as String? ?? 'ev',
      notifications: NotificationPrefs.fromJson(
        json['notifications'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Workload takibi
class MemberWorkload {
  final int dailyMinutes;
  final int weeklyMinutes;
  final int monthlyMinutes;
  final int taskCount;
  final double completionRate; // 0-1
  final double averageQuality; // 1-5
  final int streakDays;
  final DateTime? lastTaskDate;

  const MemberWorkload({
    this.dailyMinutes = 0,
    this.weeklyMinutes = 0,
    this.monthlyMinutes = 0,
    this.taskCount = 0,
    this.completionRate = 1.0,
    this.averageQuality = 3.0,
    this.streakDays = 0,
    this.lastTaskDate,
  });

  Map<String, dynamic> toJson() => {
    'dailyMinutes': dailyMinutes,
    'weeklyMinutes': weeklyMinutes,
    'monthlyMinutes': monthlyMinutes,
    'taskCount': taskCount,
    'completionRate': completionRate,
    'averageQuality': averageQuality,
    'streakDays': streakDays,
    'lastTaskDate': lastTaskDate?.toIso8601String(),
  };

  factory MemberWorkload.fromJson(Map<String, dynamic> json) {
    return MemberWorkload(
      dailyMinutes: json['dailyMinutes'] as int? ?? 0,
      weeklyMinutes: json['weeklyMinutes'] as int? ?? 0,
      monthlyMinutes: json['monthlyMinutes'] as int? ?? 0,
      taskCount: json['taskCount'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 1.0,
      averageQuality: (json['averageQuality'] as num?)?.toDouble() ?? 3.0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastTaskDate: json['lastTaskDate'] != null
          ? DateTime.parse(json['lastTaskDate'] as String)
          : null,
    );
  }
}

/// Enerji profili
class EnergyProfile {
  final int morning; // 0-100
  final int afternoon;
  final int evening;
  final int currentEnergy;

  const EnergyProfile({
    this.morning = 70,
    this.afternoon = 60,
    this.evening = 50,
    this.currentEnergy = 60,
  });

  int getForSlot(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return morning;
      case TimeSlot.afternoon:
        return afternoon;
      case TimeSlot.evening:
        return evening;
      case TimeSlot.any:
        return currentEnergy;
    }
  }

  Map<String, dynamic> toJson() => {
    'morning': morning,
    'afternoon': afternoon,
    'evening': evening,
    'currentEnergy': currentEnergy,
  };

  factory EnergyProfile.fromJson(Map<String, dynamic> json) {
    return EnergyProfile(
      morning: json['morning'] as int? ?? 70,
      afternoon: json['afternoon'] as int? ?? 60,
      evening: json['evening'] as int? ?? 50,
      currentEnergy: json['currentEnergy'] as int? ?? 60,
    );
  }
}

/// Bildirim tercihleri
class NotificationPrefs {
  final bool pushEnabled;
  final bool smsEnabled;
  final int reminderMinutesBefore;
  final String quietHoursStart;
  final String quietHoursEnd;

  const NotificationPrefs({
    this.pushEnabled = true,
    this.smsEnabled = false,
    this.reminderMinutesBefore = 30,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'smsEnabled': smsEnabled,
    'reminderMinutesBefore': reminderMinutesBefore,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 30,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '08:00',
    );
  }
}

/// Adalet kuralı ağırlıkları
class FairnessWeights {
  final int equalTime; // Eşit zaman dağılımı
  final int skillMatch; // Beceri eşleştirmesi
  final int energyAware; // Enerji seviyesi
  final int preference; // Kişisel tercihler
  final int streakBalance; // Ardışık görev dengesi

  const FairnessWeights({
    this.equalTime = 40,
    this.skillMatch = 25,
    this.energyAware = 20,
    this.preference = 10,
    this.streakBalance = 5,
  });

  int get total =>
      equalTime + skillMatch + energyAware + preference + streakBalance;

  Map<String, dynamic> toJson() => {
    'equalTime': equalTime,
    'skillMatch': skillMatch,
    'energyAware': energyAware,
    'preference': preference,
    'streakBalance': streakBalance,
  };

  factory FairnessWeights.fromJson(Map<String, dynamic> json) {
    return FairnessWeights(
      equalTime: json['equalTime'] as int? ?? 40,
      skillMatch: json['skillMatch'] as int? ?? 25,
      energyAware: json['energyAware'] as int? ?? 20,
      preference: json['preference'] as int? ?? 10,
      streakBalance: json['streakBalance'] as int? ?? 5,
    );
  }
}

/// Kısıtlar
class FairnessConstraints {
  final int maxDailyMinutes;
  final int maxWeeklyTasks;
  final int childMaxMinutes;
  final int parentMinMinutes;
  final int sameTaskCooldown; // gün
  final int consecutiveCategoryLimit;

  const FairnessConstraints({
    this.maxDailyMinutes = 120,
    this.maxWeeklyTasks = 15,
    this.childMaxMinutes = 60,
    this.parentMinMinutes = 30,
    this.sameTaskCooldown = 3,
    this.consecutiveCategoryLimit = 2,
  });

  Map<String, dynamic> toJson() => {
    'maxDailyMinutes': maxDailyMinutes,
    'maxWeeklyTasks': maxWeeklyTasks,
    'childMaxMinutes': childMaxMinutes,
    'parentMinMinutes': parentMinMinutes,
    'sameTaskCooldown': sameTaskCooldown,
    'consecutiveCategoryLimit': consecutiveCategoryLimit,
  };

  factory FairnessConstraints.fromJson(Map<String, dynamic> json) {
    return FairnessConstraints(
      maxDailyMinutes: json['maxDailyMinutes'] as int? ?? 120,
      maxWeeklyTasks: json['maxWeeklyTasks'] as int? ?? 15,
      childMaxMinutes: json['childMaxMinutes'] as int? ?? 60,
      parentMinMinutes: json['parentMinMinutes'] as int? ?? 30,
      sameTaskCooldown: json['sameTaskCooldown'] as int? ?? 3,
      consecutiveCategoryLimit: json['consecutiveCategoryLimit'] as int? ?? 2,
    );
  }
}

/// Özel kural
class SpecialRule {
  final String name;
  final String condition;
  final String action;
  final bool isActive;

  const SpecialRule({
    required this.name,
    required this.condition,
    required this.action,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'condition': condition,
    'action': action,
    'isActive': isActive,
  };

  factory SpecialRule.fromJson(Map<String, dynamic> json) {
    return SpecialRule(
      name: json['name'] as String,
      condition: json['condition'] as String,
      action: json['action'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Ödül sistemi
class RewardSystem {
  final int pointsPerTask;
  final int bonusForStreak;
  final int bonusForQuality;
  final int bonusForEarlyCompletion;

  const RewardSystem({
    this.pointsPerTask = 10,
    this.bonusForStreak = 5,
    this.bonusForQuality = 3,
    this.bonusForEarlyCompletion = 2,
  });

  Map<String, dynamic> toJson() => {
    'pointsPerTask': pointsPerTask,
    'bonusForStreak': bonusForStreak,
    'bonusForQuality': bonusForQuality,
    'bonusForEarlyCompletion': bonusForEarlyCompletion,
  };

  factory RewardSystem.fromJson(Map<String, dynamic> json) {
    return RewardSystem(
      pointsPerTask: json['pointsPerTask'] as int? ?? 10,
      bonusForStreak: json['bonusForStreak'] as int? ?? 5,
      bonusForQuality: json['bonusForQuality'] as int? ?? 3,
      bonusForEarlyCompletion: json['bonusForEarlyCompletion'] as int? ?? 2,
    );
  }
}

/// Adalet kuralları
class FairnessRules {
  final String familyId;
  final FairnessWeights weights;
  final FairnessConstraints constraints;
  final List<SpecialRule> specialRules;
  final RewardSystem rewards;

  const FairnessRules({
    required this.familyId,
    this.weights = const FairnessWeights(),
    this.constraints = const FairnessConstraints(),
    this.specialRules = const [],
    this.rewards = const RewardSystem(),
  });

  Map<String, dynamic> toJson() => {
    'familyId': familyId,
    'weights': weights.toJson(),
    'constraints': constraints.toJson(),
    'specialRules': specialRules.map((r) => r.toJson()).toList(),
    'rewards': rewards.toJson(),
  };

  factory FairnessRules.fromJson(Map<String, dynamic> json) {
    return FairnessRules(
      familyId: json['familyId'] as String,
      weights: FairnessWeights.fromJson(
        json['weights'] as Map<String, dynamic>? ?? {},
      ),
      constraints: FairnessConstraints.fromJson(
        json['constraints'] as Map<String, dynamic>? ?? {},
      ),
      specialRules:
          (json['specialRules'] as List<dynamic>?)
              ?.map((e) => SpecialRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rewards: RewardSystem.fromJson(
        json['rewards'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Üye skoru
class MemberScore {
  double workloadBalance = 0; // 0-100
  double skillCoverage = 0;
  double energyLevel = 0;
  double restBonus = 0;
  double preferenceMatch = 0;
  double streakBalance = 0;
  double fairnessScore = 0;
}

/// Görev-üye uyumluluğu
class TaskCompatibility {
  double skillMatch = 0;
  double timeMatch = 0;
  double ageMatch = 0;
  double preferenceMatch = 0;
  double energyMatch = 0;
  double locationMatch = 0;
  double cooldownPenalty = 0;
  double overall = 0;
}

/// Atama kaydı
class Assignment {
  final String taskId;
  final String memberId;
  final String reason;
  final double fairnessBefore;
  final double fairnessAfter;
  final double predictedCompletion;

  const Assignment({
    required this.taskId,
    required this.memberId,
    required this.reason,
    this.fairnessBefore = 0,
    this.fairnessAfter = 0,
    this.predictedCompletion = 0,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'memberId': memberId,
    'reason': reason,
    'fairnessBefore': fairnessBefore,
    'fairnessAfter': fairnessAfter,
    'predictedCompletion': predictedCompletion,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      taskId: json['taskId'] as String,
      memberId: json['memberId'] as String,
      reason: json['reason'] as String,
      fairnessBefore: (json['fairnessBefore'] as num?)?.toDouble() ?? 0,
      fairnessAfter: (json['fairnessAfter'] as num?)?.toDouble() ?? 0,
      predictedCompletion:
          (json['predictedCompletion'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Rotasyon sonucu
class RotationResult {
  final String rotationId;
  final List<Assignment> assignments;
  final RotationMetrics metrics;
  final DateTime createdAt;

  const RotationResult({
    required this.rotationId,
    required this.assignments,
    required this.metrics,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'rotationId': rotationId,
    'assignments': assignments.map((a) => a.toJson()).toList(),
    'metrics': metrics.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory RotationResult.fromJson(Map<String, dynamic> json) {
    return RotationResult(
      rotationId: json['rotationId'] as String,
      assignments: (json['assignments'] as List<dynamic>)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: RotationMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Rotasyon metrikleri
class RotationMetrics {
  final double maxWorkloadDiff; // dakika
  final double skillMatchRate;
  final double energyOptimization;
  final double memberSatisfaction;

  const RotationMetrics({
    this.maxWorkloadDiff = 0,
    this.skillMatchRate = 0,
    this.energyOptimization = 0,
    this.memberSatisfaction = 0,
  });

  Map<String, dynamic> toJson() => {
    'maxWorkloadDiff': maxWorkloadDiff,
    'skillMatchRate': skillMatchRate,
    'energyOptimization': energyOptimization,
    'memberSatisfaction': memberSatisfaction,
  };

  factory RotationMetrics.fromJson(Map<String, dynamic> json) {
    return RotationMetrics(
      maxWorkloadDiff: (json['maxWorkloadDiff'] as num?)?.toDouble() ?? 0,
      skillMatchRate: (json['skillMatchRate'] as num?)?.toDouble() ?? 0,
      energyOptimization: (json['energyOptimization'] as num?)?.toDouble() ?? 0,
      memberSatisfaction: (json['memberSatisfaction'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Aile adalet istatistikleri
class FamilyFairnessStats {
  final List<double> fairnessTrend;
  final Map<String, double> workloadDistribution;
  final double skillMatchRate;
  final double completionRate;
  final List<Map<String, dynamic>> topTasks;
  final String? leastActiveMember;
  final List<String> aiSuggestions;

  const FamilyFairnessStats({
    this.fairnessTrend = const [],
    this.workloadDistribution = const {},
    this.skillMatchRate = 0,
    this.completionRate = 0,
    this.topTasks = const [],
    this.leastActiveMember,
    this.aiSuggestions = const [],
  });
}

/// Dağıtım çözümü (optimizasyon için)
class Solution {
  final List<Assignment> assignments;
  double fitness = 0;

  Solution({required this.assignments});

  Solution copy() {
    return Solution(
      assignments: assignments
          .map(
            (a) => Assignment(
              taskId: a.taskId,
              memberId: a.memberId,
              reason: a.reason,
              fairnessBefore: a.fairnessBefore,
              fairnessAfter: a.fairnessAfter,
              predictedCompletion: a.predictedCompletion,
            ),
          )
          .toList(),
    )..fitness = fitness;
  }
}
