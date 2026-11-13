import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/features/health_records/providers/health_records_provider.dart';
import 'package:healthmate/features/health_records/services/sample_data_service.dart';
import 'package:healthmate/features/profile/providers/profile_provider.dart';
import 'package:healthmate/features/steps/providers/step_counter_provider.dart';
import 'package:healthmate/features/steps/services/step_sensor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

class FakeSensor implements StepSensor {
  FakeSensor({this.granted = true});

  bool granted;
  final StreamController<int> controller = StreamController<int>.broadcast();

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Stream<int> get stepStream => controller.stream;
}

void main() {
  setUpAll(initTestDatabaseFactory);

  late DatabaseHelper helper;
  late SharedPreferences prefs;
  late HealthRecordsProvider records;
  late ProfileProvider profile;
  late FakeSensor sensor;
  late StepCounterProvider steps;

  final now = DateTime(2026, 11, 6, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    helper = newInMemoryHelper();
    final repo = newRepository(helper);
    records = HealthRecordsProvider(
        repo, SampleDataService(repo, prefs, clock: () => now));
    profile = ProfileProvider(prefs);
    sensor = FakeSensor();
    steps = StepCounterProvider(
      prefs: prefs,
      sensor: sensor,
      records: records,
      profile: profile,
      clock: () => now,
    );
  });

  tearDown(() async {
    steps.dispose();
    await sensor.controller.close();
    await helper.close();
  });

  test('starts off, and turning it on makes it active', () async {
    expect(steps.status, StepStatus.off);
    expect(steps.enabled, isFalse);

    await steps.setEnabled(true);

    expect(steps.enabled, isTrue);
    expect(steps.status, StepStatus.active);
  });

  test('a denied permission is reported, not crashed on', () async {
    sensor.granted = false;
    await steps.setEnabled(true);
    expect(steps.status, StepStatus.permissionDenied);
    // The switch must not stay on (and re-ask at every launch).
    expect(steps.enabled, isFalse);
  });

  test('sensor readings become today\'s steps', () async {
    await steps.setEnabled(true);
    sensor.controller.add(10000);
    sensor.controller.add(10010);
    await pumpEventQueue();

    expect(steps.todaySteps, 10);
  });

  test('syncNow creates today\'s record with the estimated calories', () async {
    await records.init();
    await records.clearSampleRecords();
    await steps.setEnabled(true);
    sensor.controller.add(5000);
    sensor.controller.add(5010);
    await pumpEventQueue();

    await steps.syncNow();

    final today = records.findByDate('2026-11-06')!;
    expect(today.steps, 10);
    expect(today.water, 0);
    expect(today.calories, 0); // 10 steps x 0.04 kcal rounds to 0
  });

  test('setTodaySteps keeps water, adds only the new calories, never lowers',
      () async {
    await records.init();
    await records.clearSampleRecords();
    await records.addRecord(
        record('2026-11-06', steps: 100, calories: 10, water: 500));

    expect(await records.setTodaySteps(200, kcalPerStep: 0.04, now: now), isNull);
    var today = records.findByDate('2026-11-06')!;
    expect(today.steps, 200);
    expect(today.calories, 14); // 10 + 100 new steps x 0.04
    expect(today.water, 500);

    // A lower reading must not overwrite a higher stored value.
    await records.setTodaySteps(150, kcalPerStep: 0.04, now: now);
    today = records.findByDate('2026-11-06')!;
    expect(today.steps, 200);
  });

  test('turning it off stops listening', () async {
    await steps.setEnabled(true);
    await steps.setEnabled(false);
    expect(steps.status, StepStatus.off);

    sensor.controller.add(9999);
    await pumpEventQueue();
    expect(steps.todaySteps, 0);
  });

  test('steps keep saving after midnight', () async {
    var clock = DateTime(2026, 11, 6, 23, 50);
    final repo = newRepository(helper);
    final recs = HealthRecordsProvider(
        repo, SampleDataService(repo, prefs, clock: () => clock));
    final counter = StepCounterProvider(
      prefs: prefs,
      sensor: sensor,
      records: recs,
      profile: profile,
      clock: () => clock,
    );
    addTearDown(counter.dispose);
    await recs.init();
    await recs.clearSampleRecords();
    await counter.setEnabled(true);

    sensor.controller.add(1000);
    sensor.controller.add(1400); // 400 steps, saved (over the 25-step limit)
    await pumpEventQueue();
    expect(recs.findByDate('2026-11-06')!.steps, 400);

    clock = DateTime(2026, 11, 7, 0, 10);
    sensor.controller.add(1450); // 50 steps on the new day
    await pumpEventQueue();

    expect(recs.findByDate('2026-11-07')?.steps, 50);
  });
}
