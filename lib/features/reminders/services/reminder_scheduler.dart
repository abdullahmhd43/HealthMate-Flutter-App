/// Schedules repeating daily notifications. An interface so the provider can
/// be tested with a fake instead of the real notification plugin.
abstract class ReminderScheduler {
  /// Asks for the notification permission (Android 13+). True if allowed.
  Future<bool> requestPermission();

  /// A notification every day at [hour]:[minute], replacing any with this [id].
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);
}
