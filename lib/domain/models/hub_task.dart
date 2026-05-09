/// Lightweight task model for the hub my-tasks list.
class HubTask {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String priority;

  HubTask({
    required this.id,
    required this.title,
    this.dueDate,
    this.priority = 'medium',
  });

  factory HubTask.fromJson(Map<String, dynamic> json) => HubTask(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Görev',
        dueDate: DateTime.tryParse((json['due_date'] as String?) ?? ''),
        priority: json['priority'] as String? ?? 'medium',
      );
}
