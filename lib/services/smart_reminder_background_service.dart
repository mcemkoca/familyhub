// Stub: workmanager removed due to Gradle/Kotlin compatibility issues.
// TODO: Re-enable with workmanager ^1.0.0+ when upgraded.
class SmartReminderBackgroundService {
  static Future<void> initialize() async {}
  static Future<void> scheduleReminder(String id, DateTime when) async {}
  static Future<void> cancelReminder(String id) async {}
}
