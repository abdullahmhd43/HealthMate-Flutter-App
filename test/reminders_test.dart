import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/reminders/models/reminder_settings.dart';
import 'package:healthmate/features/reminders/providers/reminder_provider.dart';
import 'package:healthmate/features/reminders/services/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScheduler implements ReminderScheduler {
  bool permission = true;
  bool failScheduling = false;
  final Map<int, String> scheduled = {};
  final List<int> cancelled = [];

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (failScheduling) throw Exception('plugin error');
    scheduled[id] = '$hour:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeScheduler scheduler;
  late ReminderProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = FakeScheduler();
    provider = ReminderProvider(prefs, scheduler);
    await provider.init();
  });

  test('everything starts switched off', () {
    expect(provider.settings.anyEnabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
  });

  test('daily reminder is scheduled at the chosen time', () async {
    expect(await provider.setDailyEnabled(true), isNull);
    expect(scheduler.scheduled[ReminderProvider.dailyId], '20:00');

    expect(await provider.setDailyTime(7, 5), isNull);
    expect(scheduler.scheduled[ReminderProvider.dailyId], '7:05');
    expect(provider.settings.dailyTimeLabel, '7:05 AM');
  });

  test('water reminders schedule one notification per hour slot', () async {
    expect(await provider.setWaterEnabled(true), isNull);
    expect(scheduler.scheduled, hasLength(ReminderSettings.waterHours.length));
    expect(scheduler.scheduled[ReminderProvider.waterBaseId], '9:00');

    expect(await provider.setWaterEnabled(false), isNull);
    expect(scheduler.scheduled, isEmpty);
  });

  test('turning the daily reminder off cancels it', () async {
    await provider.setDailyEnabled(true);
    await provider.setDailyEnabled(false);
    expect(scheduler.scheduled.containsKey(ReminderProvider.dailyId), isFalse);
    expect(scheduler.cancelled, contains(ReminderProvider.dailyId));
  });

  test('blocked notifications give a message and keep the switch off',
      () async {
    scheduler.permission = false;
    final error = await provider.setDailyEnabled(true);
    expect(error, contains('blocked'));
    expect(provider.settings.dailyEnabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
  });

  test('a scheduling failure gives a message and changes nothing', () async {
    scheduler.failScheduling = true;
    final error = await provider.setWaterEnabled(true);
    expect(error, isNotNull);
    expect(provider.settings.waterEnabled, isFalse);
  });

  test('choices are saved and restored on the next start', () async {
    await provider.setDailyEnabled(true);
    await provider.setDailyTime(18, 30);
    await provider.setWaterEnabled(true);

    final freshScheduler = FakeScheduler();
    final restored = ReminderProvider(prefs, freshScheduler);
    await restored.init();

    expect(restored.settings.dailyEnabled, isTrue);
    expect(restored.settings.dailyHour, 18);
    expect(restored.settings.dailyMinute, 30);
    expect(restored.settings.waterEnabled, isTrue);
    // And the alarms were scheduled again.
    expect(freshScheduler.scheduled[ReminderProvider.dailyId], '18:30');
    expect(freshScheduler.scheduled, hasLength(1 + ReminderSettings.waterHours.length));
  });

  test('time label handles midnight and noon', () {
    expect(const ReminderSettings(dailyHour: 0).dailyTimeLabel, '12:00 AM');
    expect(const ReminderSettings(dailyHour: 12).dailyTimeLabel, '12:00 PM');
    expect(const ReminderSettings(dailyHour: 23, dailyMinute: 9).dailyTimeLabel,
        '11:09 PM');
  });
}
