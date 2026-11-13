import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/steps/services/step_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late StepTracker tracker;

  final morning = DateTime(2026, 11, 6, 8);
  final evening = DateTime(2026, 11, 6, 20);
  final nextDay = DateTime(2026, 11, 7, 7);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tracker = StepTracker(prefs);
  });

  test('the first reading starts today at 0', () {
    expect(tracker.onSensorValue(120000, morning), 0);
  });

  test('later readings add the steps walked since the first one', () {
    tracker.onSensorValue(120000, morning);
    expect(tracker.onSensorValue(120450, morning), 450);
    expect(tracker.onSensorValue(123000, evening), 3000);
  });

  test('a new day counts the steps walked since the last reading', () {
    tracker.onSensorValue(120000, morning);
    expect(tracker.onSensorValue(125000, evening), 5000);
    // Steps walked overnight / before the app was opened belong to the new day.
    expect(tracker.onSensorValue(125200, nextDay), 200);
    expect(tracker.onSensorValue(125700, nextDay), 700);
  });

  test('after a gap of more than a day counting restarts from 0', () {
    tracker.onSensorValue(120000, morning);
    final later = DateTime(2026, 11, 9, 9);
    expect(tracker.onSensorValue(150000, later), 0);
    expect(tracker.onSensorValue(150100, later), 100);
  });

  test('a phone reboot (counter back to a small number) keeps today\'s steps',
      () {
    tracker.onSensorValue(120000, morning);
    expect(tracker.onSensorValue(124000, morning), 4000);
    // Phone restarted: the sensor counts from 0 again.
    expect(tracker.onSensorValue(50, evening), 4050);
    expect(tracker.onSensorValue(300, evening), 4300);
  });

  test('a second reboot on the same day is also handled', () {
    tracker.onSensorValue(120000, morning);
    tracker.onSensorValue(124000, morning); // 4000
    expect(tracker.onSensorValue(100, evening), 4100); // reboot 1
    expect(tracker.onSensorValue(500, evening), 4500);
    expect(tracker.onSensorValue(30, evening), 4530); // reboot 2
  });

  test('walking past the old counter value after a reboot is not missed', () {
    tracker.onSensorValue(1000, morning);
    tracker.onSensorValue(1500, morning); // 500
    expect(tracker.onSensorValue(10, evening), 510); // reboot
    expect(tracker.onSensorValue(2000, evening), 2500);
  });

  test('the count survives the app being restarted', () {
    tracker.onSensorValue(1000, morning);
    tracker.onSensorValue(1800, morning);

    final restarted = StepTracker(prefs); // same SharedPreferences
    expect(restarted.onSensorValue(2000, evening), 1000);
  });
}
