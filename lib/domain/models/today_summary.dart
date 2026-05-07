/// Aggregated daily metrics for the hub overview.
class TodaySummary {
  final int eventCount;
  final int taskCount;
  final int unreadMessages;
  final int onlineMembers;
  final int totalMembers;
  final String? nextEventTitle;
  final DateTime? nextEventTime;

  const TodaySummary({
    required this.eventCount,
    required this.taskCount,
    required this.unreadMessages,
    required this.onlineMembers,
    required this.totalMembers,
    this.nextEventTitle,
    this.nextEventTime,
  });
}
