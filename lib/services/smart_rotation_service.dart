import 'dart:math';
import 'package:uuid/uuid.dart';
import '../domain/models/smart_rotation.dart';

/// Akıllı Görev Rotasyon Servisi
/// Adalet algoritması + genetik optimizasyon ile görev dağıtımı
class SmartRotationService {
  static final _uuid = const Uuid();
  static final Random _random = Random();

  // ── ANA DAĞITIM FONKSİYONU ──────────────────────────────────────────────

  static Future<RotationResult> distributeTasks({
    required List<RotationTask> tasks,
    required List<RotationMember> members,
    required FairnessRules rules,
    DateTime? targetDate,
  }) async {
    final date = targetDate ?? DateTime.now();
    final pendingTasks = tasks
        .where(
          (t) => t.status == RotationStatus.pending && t.assignedTo == null,
        )
        .toList();

    if (pendingTasks.isEmpty || members.isEmpty) {
      return RotationResult(
        rotationId: _uuid.v4(),
        assignments: const [],
        metrics: const RotationMetrics(),
        createdAt: DateTime.now(),
      );
    }

    // 1. Üye skorlarını hesapla
    final memberScores = <String, MemberScore>{};
    for (final member in members) {
      memberScores[member.id] = _calculateMemberScore(
        member: member,
        rules: rules,
        targetDate: date,
      );
    }

    // 2. Uyumluluk matrisi
    final compatibilityMatrix = <String, Map<String, TaskCompatibility>>{};
    for (final task in pendingTasks) {
      compatibilityMatrix[task.id] = {};
      for (final member in members) {
        compatibilityMatrix[task.id]![member.id] = _calculateCompatibility(
          task: task,
          member: member,
          memberScore: memberScores[member.id]!,
          rules: rules,
        );
      }
    }

    // 3. Genetik algoritma ile optimize et
    final assignments = _optimizeAssignments(
      tasks: pendingTasks,
      members: members,
      compatibilityMatrix: compatibilityMatrix,
      rules: rules,
    );

    // 4. Atama nedenlerini ekle
    final enrichedAssignments = assignments.map((a) {
      final compat = compatibilityMatrix[a.taskId]![a.memberId]!;
      final reasons = <String>[];
      if (compat.skillMatch > 0.7) reasons.add('Beceri uyumu yüksek');
      if (compat.energyMatch > 0.7) reasons.add('Enerji seviyesi uygun');
      if (compat.timeMatch > 0) reasons.add('Zaman müsait');
      if (compat.preferenceMatch > 0.7) reasons.add('Tercih ettiği kategori');
      if (reasons.isEmpty) reasons.add('Adalet dengesi için atandı');

      return Assignment(
        taskId: a.taskId,
        memberId: a.memberId,
        reason: reasons.join(', '),
        fairnessBefore: memberScores[a.memberId]!.fairnessScore,
        fairnessAfter: _estimateFairnessAfter(
          memberScores[a.memberId]!,
          pendingTasks.firstWhere((t) => t.id == a.taskId),
        ),
        predictedCompletion: (compat.overall * 100).clamp(0, 100),
      );
    }).toList();

    // 5. Metrikleri hesapla
    final metrics = _calculateMetrics(
      enrichedAssignments,
      pendingTasks,
      members,
      compatibilityMatrix,
    );

    return RotationResult(
      rotationId: _uuid.v4(),
      assignments: enrichedAssignments,
      metrics: metrics,
      createdAt: DateTime.now(),
    );
  }

  // ── ÜYE SKORU HESAPLAMA ─────────────────────────────────────────────────

  static MemberScore _calculateMemberScore({
    required RotationMember member,
    required FairnessRules rules,
    required DateTime targetDate,
  }) {
    final score = MemberScore();

    // A. Mevcut workload (40% ağırlık)
    final currentWorkload = member.workload.weeklyMinutes;
    final avgWorkload = 60.0; // Varsayılan ortalama
    score.workloadBalance =
        100 -
        ((currentWorkload - avgWorkload).abs() / avgWorkload * 100).clamp(
          0,
          100,
        );

    // B. Beceri kapsamı (25%)
    score.skillCoverage = member.skills.isEmpty ? 50 : 80;

    // C. Enerji seviyesi (20%)
    final timeSlot = _getTimeSlot(targetDate);
    score.energyLevel = member.energyProfile.getForSlot(timeSlot).toDouble();

    final hoursSinceLastTask = member.workload.lastTaskDate != null
        ? DateTime.now().difference(member.workload.lastTaskDate!).inHours
        : 48;
    score.restBonus = (hoursSinceLastTask / 24 * 10).clamp(0, 20);
    score.energyLevel = (score.energyLevel + score.restBonus).clamp(0, 100);

    // D. Tercih uyumu (10%)
    score.preferenceMatch = member.preferredCategories.isEmpty ? 50 : 75;

    // E. Streak dengesi (5%)
    score.streakBalance = member.workload.streakDays > 7 ? 50 : 100;

    // F. Genel adalet skoru
    score.fairnessScore =
        (score.workloadBalance * rules.weights.equalTime / 100 +
        score.skillCoverage * rules.weights.skillMatch / 100 +
        score.energyLevel * rules.weights.energyAware / 100 +
        score.preferenceMatch * rules.weights.preference / 100 +
        score.streakBalance * rules.weights.streakBalance / 100);

    return score;
  }

  // ── GÖREV-ÜYE UYUMLULUĞU ────────────────────────────────────────────────

  static TaskCompatibility _calculateCompatibility({
    required RotationTask task,
    required RotationMember member,
    required MemberScore memberScore,
    required FairnessRules rules,
  }) {
    final compat = TaskCompatibility();

    // 1. Beceri eşleşmesi
    if (task.requiredSkills.isNotEmpty) {
      final matching = task.requiredSkills
          .where((s) => member.skills.contains(s))
          .length;
      compat.skillMatch = matching / task.requiredSkills.length;
    } else {
      compat.skillMatch = 1.0;
    }

    // 2. Zaman uygunluğu
    final dayName = _dayNameToEnglish(DateTime.now().weekday);
    final slots = member.availability[dayName] ?? [];
    compat.timeMatch = slots.isNotEmpty ? 1.0 : 0.3;

    // 3. Yaş uygunluğu
    compat.ageMatch = member.age >= (task.requiredAge ?? 0) ? 1.0 : 0.0;

    // 4. Kategori tercihi
    if (member.avoidedCategories.contains(task.category.name)) {
      compat.preferenceMatch = 0.2;
    } else if (member.preferredCategories.contains(task.category.name)) {
      compat.preferenceMatch = 1.0;
    } else {
      compat.preferenceMatch = 0.6;
    }

    // 5. Enerji eşleşmesi
    final requiredEnergy = task.energyLevel.index * 33;
    compat.energyMatch = memberScore.energyLevel >= requiredEnergy ? 1.0 : 0.5;

    // 6. Konum eşleşmesi
    compat.locationMatch =
        (task.location == 'ev' && member.currentLocation == 'ev') ||
            (task.location == 'dışarı' && member.currentLocation != 'ev') ||
            task.location == 'online'
        ? 1.0
        : 0.7;

    // 7. Cooldown kontrolü
    final lastSame = _getLastSameTaskDate(member, task.category.name);
    if (lastSame != null) {
      final daysSince = DateTime.now().difference(lastSame).inDays;
      if (daysSince < rules.constraints.sameTaskCooldown) {
        compat.cooldownPenalty = 0.5;
      }
    }

    // Genel uyumluluk
    compat.overall =
        (compat.skillMatch * 0.25 +
        compat.timeMatch * 0.20 +
        compat.ageMatch * 0.15 +
        compat.preferenceMatch * 0.15 +
        compat.energyMatch * 0.10 +
        compat.locationMatch * 0.10 +
        (1 - compat.cooldownPenalty) * 0.05);

    return compat;
  }

  // ── GENETİK ALGORİTMA ───────────────────────────────────────────────────

  static List<Assignment> _optimizeAssignments({
    required List<RotationTask> tasks,
    required List<RotationMember> members,
    required Map<String, Map<String, TaskCompatibility>> compatibilityMatrix,
    required FairnessRules rules,
  }) {
    if (tasks.isEmpty || members.isEmpty) return [];

    // Başlangıç popülasyonu (50 çözüm)
    var population = _generateInitialPopulation(tasks, members, 50);

    // 30 nesil evrim
    for (var gen = 0; gen < 30; gen++) {
      final fitnessScores = population
          .map(
            (sol) => _calculateFitness(
              sol,
              tasks,
              members,
              compatibilityMatrix,
              rules,
            ),
          )
          .toList();

      // Seçilim (turnuva)
      final selected = _tournamentSelection(population, fitnessScores, 25);

      // Çaprazlama
      final offspring = _crossover(selected, tasks, members, 20);

      // Mutasyon
      final mutated = _mutate(offspring, tasks, members, 0.15);

      population = [...selected, ...mutated];
    }

    // En iyi çözüm
    final best = population.reduce((a, b) {
      final fa = _calculateFitness(
        a,
        tasks,
        members,
        compatibilityMatrix,
        rules,
      );
      final fb = _calculateFitness(
        b,
        tasks,
        members,
        compatibilityMatrix,
        rules,
      );
      return fa > fb ? a : b;
    });

    return best.assignments;
  }

  static List<Solution> _generateInitialPopulation(
    List<RotationTask> tasks,
    List<RotationMember> members,
    int count,
  ) {
    final population = <Solution>[];
    for (var i = 0; i < count; i++) {
      final assignments = <Assignment>[];
      for (final task in tasks) {
        // Rastgele ama adalete yakın dağıtım
        final sorted = List<RotationMember>.from(members)..shuffle(_random);
        final chosen = sorted.first;
        assignments.add(
          Assignment(
            taskId: task.id,
            memberId: chosen.id,
            reason: 'Başlangıç dağıtımı',
          ),
        );
      }
      population.add(Solution(assignments: assignments));
    }
    return population;
  }

  static double _calculateFitness(
    Solution solution,
    List<RotationTask> tasks,
    List<RotationMember> members,
    Map<String, Map<String, TaskCompatibility>> compatibilityMatrix,
    FairnessRules rules,
  ) {
    var fitness = 0.0;

    // A. Toplam uyumluluk
    for (final a in solution.assignments) {
      final compat = compatibilityMatrix[a.taskId]?[a.memberId];
      if (compat != null) {
        fitness += compat.overall * 100;
      }
    }

    // B. Workload dengesi (düşük varyans = iyi)
    final workloads = <String, int>{};
    for (final a in solution.assignments) {
      final task = tasks.firstWhere((t) => t.id == a.taskId);
      workloads[a.memberId] =
          (workloads[a.memberId] ?? 0) + task.estimatedDuration;
    }

    final values = workloads.values.toList();
    if (values.length > 1) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
          values.length;
      fitness -= sqrt(variance) * 3;
    }

    // C. Kural ihlali cezası
    for (final a in solution.assignments) {
      final task = tasks.firstWhere((t) => t.id == a.taskId);
      final member = members.firstWhere((m) => m.id == a.memberId);
      if (_violatesRules(task, member, rules)) {
        fitness -= 500;
      }
    }

    return fitness;
  }

  static List<Solution> _tournamentSelection(
    List<Solution> population,
    List<double> fitnessScores,
    int count,
  ) {
    final selected = <Solution>[];
    for (var i = 0; i < count; i++) {
      final idx1 = _random.nextInt(population.length);
      final idx2 = _random.nextInt(population.length);
      selected.add(
        fitnessScores[idx1] > fitnessScores[idx2]
            ? population[idx1].copy()
            : population[idx2].copy(),
      );
    }
    return selected;
  }

  static List<Solution> _crossover(
    List<Solution> parents,
    List<RotationTask> tasks,
    List<RotationMember> members,
    int count,
  ) {
    final offspring = <Solution>[];
    for (var i = 0; i < count && parents.length >= 2; i++) {
      final p1 = parents[_random.nextInt(parents.length)];
      final p2 = parents[_random.nextInt(parents.length)];
      final childAssignments = <Assignment>[];

      for (var j = 0; j < p1.assignments.length; j++) {
        childAssignments.add(
          _random.nextBool() ? p1.assignments[j] : p2.assignments[j],
        );
      }
      offspring.add(Solution(assignments: childAssignments));
    }
    return offspring;
  }

  static List<Solution> _mutate(
    List<Solution> solutions,
    List<RotationTask> tasks,
    List<RotationMember> members,
    double rate,
  ) {
    for (final sol in solutions) {
      for (var i = 0; i < sol.assignments.length; i++) {
        if (_random.nextDouble() < rate) {
          final newMember = members[_random.nextInt(members.length)];
          sol.assignments[i] = Assignment(
            taskId: sol.assignments[i].taskId,
            memberId: newMember.id,
            reason: 'Mutasyon',
          );
        }
      }
    }
    return solutions;
  }

  // ── KURAL KONTROLÜ ──────────────────────────────────────────────────────

  static bool _violatesRules(
    RotationTask task,
    RotationMember member,
    FairnessRules rules,
  ) {
    // Yaş limiti
    if (task.requiredAge != null && member.age < task.requiredAge!) return true;

    // Günlük dakika limiti
    if (member.workload.dailyMinutes + task.estimatedDuration >
        rules.constraints.maxDailyMinutes) {
      return true;
    }

    // Çocuk limiti
    if (member.role == MemberRole.child &&
        member.workload.dailyMinutes + task.estimatedDuration >
            rules.constraints.childMaxMinutes) {
      return true;
    }

    // Özel kurallar
    for (final rule in rules.specialRules.where((r) => r.isActive)) {
      if (_matchesSpecialRule(task, member, rule)) return true;
    }

    return false;
  }

  static bool _matchesSpecialRule(
    RotationTask task,
    RotationMember member,
    SpecialRule rule,
  ) {
    final lower = rule.condition.toLowerCase();
    final day = _dayNameTurkish(DateTime.now().weekday).toLowerCase();
    final category = _categoryTurkish(task.category).toLowerCase();

    if (lower.contains('cuma') &&
        day.contains('cuma') &&
        lower.contains('temizlik') &&
        category.contains('temizlik')) {
      return true;
    }

    if (lower.contains(member.name.toLowerCase()) && lower.contains(category)) {
      return true;
    }

    return false;
  }

  // ── METRİK HESAPLAMA ────────────────────────────────────────────────────

  static RotationMetrics _calculateMetrics(
    List<Assignment> assignments,
    List<RotationTask> tasks,
    List<RotationMember> members,
    Map<String, Map<String, TaskCompatibility>> matrix,
  ) {
    // Workload farkı
    final workloads = <String, int>{};
    for (final a in assignments) {
      final task = tasks.firstWhere((t) => t.id == a.taskId);
      workloads[a.memberId] =
          (workloads[a.memberId] ?? 0) + task.estimatedDuration;
    }
    final values = workloads.values.toList();
    double maxDiff = 0;
    if (values.isNotEmpty) {
      maxDiff = (values.reduce(max) - values.reduce(min)).toDouble();
    }

    // Beceri eşleşme oranı
    double totalMatch = 0;
    var matchCount = 0;
    for (final a in assignments) {
      final compat = matrix[a.taskId]?[a.memberId];
      if (compat != null) {
        totalMatch += compat.skillMatch;
        matchCount++;
      }
    }
    final skillRate = matchCount > 0
        ? (totalMatch / matchCount * 100).toDouble()
        : 0.0;

    // Enerji optimizasyonu
    double totalEnergy = 0;
    var energyCount = 0;
    for (final a in assignments) {
      final compat = matrix[a.taskId]?[a.memberId];
      if (compat != null) {
        totalEnergy += compat.energyMatch;
        energyCount++;
      }
    }
    final energyOpt = energyCount > 0
        ? (totalEnergy / energyCount * 100).toDouble()
        : 0.0;

    // Memnuniyet tahmini
    final satisfaction = (skillRate + energyOpt) / 2;

    return RotationMetrics(
      maxWorkloadDiff: maxDiff,
      skillMatchRate: skillRate,
      energyOptimization: energyOpt,
      memberSatisfaction: satisfaction,
    );
  }

  // ── YARDIMCI FONKSİYONLAR ───────────────────────────────────────────────

  static TimeSlot _getTimeSlot(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return TimeSlot.morning;
    if (hour < 18) return TimeSlot.afternoon;
    return TimeSlot.evening;
  }

  static DateTime? _getLastSameTaskDate(
    RotationMember member,
    String category,
  ) {
    // Retrieve last task date for cooldown calculation
    if (member.workload.lastTaskDate == null) return null;
    return member.workload.lastTaskDate;
  }

  static double _estimateFairnessAfter(MemberScore score, RotationTask task) {
    // Görev eklendikten sonra tahmini adalet skoru
    final workloadPenalty = task.estimatedDuration / 120 * 5;
    return (score.fairnessScore - workloadPenalty).clamp(0, 100);
  }

  static String _dayNameToEnglish(int weekday) {
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return names[weekday - 1];
  }

  static String _dayNameTurkish(int weekday) {
    const names = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return names[weekday - 1];
  }

  static String _categoryTurkish(TaskCategory cat) {
    const map = {
      TaskCategory.cleaning: 'Temizlik',
      TaskCategory.cooking: 'Yemek',
      TaskCategory.shopping: 'Alışveriş',
      TaskCategory.maintenance: 'Bakım',
      TaskCategory.education: 'Eğitim',
      TaskCategory.social: 'Sosyal',
      TaskCategory.admin: 'İdari',
      TaskCategory.urgent: 'Acil',
    };
    return map[cat] ?? 'Genel';
  }

}
