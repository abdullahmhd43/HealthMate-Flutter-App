import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// The real scheduler, built on `flutter_local_notifications` (version 19).
/// Uses inexact alarms, so no special "exact alarm" permission is needed.
class LocalNotificationScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _ensureInitialised() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_deviceLocation());
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions are asked later (when a reminder is switched on), not at start.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    _ready = true;
  }

  /// Finds a time zone that matches the phone's UTC offset in both January and
  /// July of this year, so daylight-saving changes are followed correctly (a
  /// match on today's offset alone could pick a region with other DST rules).
  tz.Location _deviceLocation() {
    final now = DateTime.now();
    final winter = DateTime(now.year, 1, 1, 12);
    final summer = DateTime(now.year, 7, 1, 12);
    bool matches(tz.Location location, DateTime when) =>
        location.timeZone(when.millisecondsSinceEpoch).offset ==
        when.timeZoneOffset.inMilliseconds;

    for (final location in tz.timeZoneDatabase.locations.values) {
      if (matches(location, now) &&
          matches(location, winter) &&
          matches(location, summer)) {
        return location;
      }
    }
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (matches(location, now)) return location;
    }
    return tz.UTC;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialised();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureInitialised();
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'healthmate_reminders',
          'Health reminders',
          channelDescription: 'Daily check-in and water reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureInitialised();
    await _plugin.cancel(id);
  }
}
