import '../domain/models/household_task.dart';
import '../domain/models/family_member_model.dart';

class FairTaskDistributor {
  /// Distributes tasks among family members considering:
  /// 1. Weekly capacity (hours)
  /// 2. Task difficulty (1-5)
  /// 3. Age and skill alignment
  /// 4. Previous week workload from history
  List<AssignedTask> distributeTasks({
    required List<FamilyMemberModel> members,
    required List<HouseholdTask> tasks,
    Map<String, double> previousWorkload = const {},
  }) {
    if (members.isEmpty || tasks.isEmpty) return [];

    // Calculate capacity per member (default 10 hours/week for adults, less for children)
    final capacities = <String, double>{};
    for (final member in members) {
      final age = member.age ?? 30;
      double capacity;
      if (age < 10) {
        capacity = 2;
      } else if (age < 16) {
        capacity = 5;
      } else {
        capacity = 10;
      }
      capacities[member.id] = capacity;
    }

    // Normalize previous workload
    final normalizedWorkload = <String, double>{};
    for (final member in members) {
      normalizedWorkload[member.id] = previousWorkload[member.id] ?? 0.0;
    }

    // Sort tasks by difficulty descending (hardest first)
    final sortedTasks = List<HouseholdTask>.from(tasks)
      ..sort((a, b) => b.difficultyLevel.compareTo(a.difficultyLevel));

    final assignments = <AssignedTask>[];
    final currentWorkload = Map<String, double>.from(normalizedWorkload);

    for (final task in sortedTasks) {
      // Find member with lowest relative workload who has capacity
      String? bestMemberId;
      double bestRatio = double.infinity;

      for (final member in members) {
        final capacity = capacities[member.id] ?? 10;
        final workload = currentWorkload[member.id] ?? 0;
        final taskDuration = (task.estimatedDurationMinutes ?? 30) / 60.0;
        final difficulty = task.difficultyLevel;

        // Skip if over capacity
        if (workload + taskDuration * difficulty > capacity * 1.2) continue;

        // Age-skill filter: very hard tasks (4-5) only for adults
        if (difficulty >= 4 && (member.age ?? 30) < 16) continue;

        final ratio = workload / capacity;
        if (ratio < bestRatio) {
          bestRatio = ratio;
          bestMemberId = member.id;
        }
      }

      // Fallback to any member if no optimal found
      bestMemberId ??= members.first.id;

      final duration = (task.estimatedDurationMinutes ?? 30) / 60.0;
      currentWorkload[bestMemberId] = (currentWorkload[bestMemberId] ?? 0) + duration * task.difficultyLevel;

      assignments.add(AssignedTask(
        task: task,
        assignedToId: bestMemberId,
      ));
    }

    return assignments;
  }
}

class AssignedTask {
  final HouseholdTask task;
  final String assignedToId;

  AssignedTask({
    required this.task,
    required this.assignedToId,
  });
}
