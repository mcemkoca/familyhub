import '../entities.dart';

/// Aggregated hub data fetched in parallel via Future.wait.
/// Reduces N+1 provider rebuilds and network round-trips.
class HubState {
  final TodaySummary todaySummary;
  final List<HubEvent> upcomingEvents;
  final List<HubTask> myTasks;
  final List<FamilyMood> familyMoods;
  final List<FamilyMember> familyMembers;
  final String? familyId;

  const HubState({
    required this.todaySummary,
    required this.upcomingEvents,
    required this.myTasks,
    required this.familyMoods,
    required this.familyMembers,
    this.familyId,
  });

  factory HubState.empty() => const HubState(
        todaySummary: TodaySummary(
          eventCount: 0,
          taskCount: 0,
          unreadMessages: 0,
          onlineMembers: 0,
          totalMembers: 0,
        ),
        upcomingEvents: [],
        myTasks: [],
        familyMoods: [],
        familyMembers: [],
      );
}
