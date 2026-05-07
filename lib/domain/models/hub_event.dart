/// Lightweight event model for the hub upcoming-events list.
class HubEvent {
  final String id;
  final String title;
  final DateTime start;

  HubEvent({
    required this.id,
    required this.title,
    required this.start,
  });

  factory HubEvent.fromJson(Map<String, dynamic> json) => HubEvent(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Etkinlik',
        start: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      );
}
