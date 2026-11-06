import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/core/utils/date_helper.dart';
import 'package:healthmate/features/dashboard/providers/dashboard_provider.dart';
import 'package:healthmate/features/health_records/providers/health_records_provider.dart';
import 'package:healthmate/features/health_records/repositories/health_record_repository.dart';
import 'package:healthmate/features/health_records/services/sample_data_service.dart';
import 'package:healthmate/features/settings/models/user_goals.dart';
import 'package:healthmate/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late DatabaseHelper helper;
  late HealthRecordRepository repo;
  late SharedPreferences prefs;
  late SampleDataService samples;
  late HealthRecordsProvider provider;

  final fixedNow = DateTime(2026, 11, 6, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    helper = newInMemoryHelper();
    repo = newRepository(helper);
    samples = SampleDataService(repo, prefs, clock: () => fixedNow);
    provider = HealthRecordsProvider(repo, samples);
  });

  tearDown(() async => helper.close());

  group('HealthRecordsProvider', () {
    test('init seeds sample data once, only into an empty database', () async {
      await provider.init();
      expect(provider.allRecords, hasLength(14));
      expect(provider.sampleCount, 14);

      // A second provider over the same data must not duplicate samples.
      final second = HealthRecordsProvider(repo, samples);
      await second.init();
      expect(second.allRecords, hasLength(14));
      expect(await repo.count(), 14);
    });

    test('does not seed over existing user data', () async {
      await repo.insert(record('2026-11-01'));
      await provider.init();
      expect(provider.allRecords, hasLength(1));
      expect(provider.sampleCount, 0);
    });

    test('does not reseed after the user deletes everything', () async {
      await provider.init();
      await provider.clearSampleRecords();
      expect(provider.allRecords, isEmpty);

      final again = HealthRecordsProvider(repo, samples);
      await again.init();
      expect(again.allRecords, isEmpty);
    });

    test('addRecord saves to SQLite and notifies listeners', () async {
      await provider.init();
      await provider.clearSampleRecords();
      var notified = 0;
      provider.addListener(() => notified++);

      final error = await provider.addRecord(record('2026-11-06', steps: 8000));

      expect(error, isNull);
      expect(notified, greaterThan(0));
      expect(provider.allRecords.single.steps, 8000);
      expect(await repo.count(), 1); // really in SQLite
    });

    test('addRecord rejects a duplicate date with a message', () async {
      await provider.init();
      await provider.clearSampleRecords();
      await provider.addRecord(record('2026-11-06'));

      final error = await provider.addRecord(record('2026-11-06', steps: 1));

      expect(error, contains('already exists'));
      expect(provider.allRecords, hasLength(1));
    });

    test('updateRecord changes the stored row and the list', () async {
      await provider.init();
      await provider.clearSampleRecords();
      await provider.addRecord(record('2026-11-06', steps: 1000));
      final saved = provider.allRecords.single;

      final error =
          await provider.updateRecord(saved.copyWith(steps: 2222, water: 1234));

      expect(error, isNull);
      expect(provider.allRecords.single.steps, 2222);
      expect((await repo.getById(saved.id!))!.water, 1234);
    });

    test('a record can be saved with its own date unchanged', () async {
      await provider.init();
      await provider.clearSampleRecords();
      await provider.addRecord(record('2026-11-06'));
      final saved = provider.allRecords.single;

      expect(await provider.updateRecord(saved.copyWith(calories: 999)), isNull);
    });

    test('deleteRecord removes it from SQLite and the list', () async {
      await provider.init();
      await provider.clearSampleRecords();
      await provider.addRecord(record('2026-11-06'));
      final id = provider.allRecords.single.id!;

      final error = await provider.deleteRecord(id);

      expect(error, isNull);
      expect(provider.allRecords, isEmpty);
      expect(await repo.getById(id), isNull);
    });

    test('deleting a missing record returns a message, not a crash', () async {
      await provider.init();
      expect(await provider.deleteRecord(9999), isNotNull);
    });

    test('search filters visibleRecords but not allRecords', () async {
      await provider.init();
      await provider.clearSampleRecords();
      await provider.addRecord(record('2026-10-05'));
      await provider.addRecord(record('2026-11-05'));

      await provider.setSearchQuery('2026-10');

      expect(provider.visibleRecords.map((r) => r.date), ['2026-10-05']);
      expect(provider.allRecords, hasLength(2));
      expect(provider.hasActiveFilters, isTrue);
    });

    test('date range filter works and clearFilters resets', () async {
      await provider.init();
      await provider.clearSampleRecords();
      for (final d in ['2026-11-01', '2026-11-05', '2026-11-10']) {
        await provider.addRecord(record(d));
      }

      await provider.setDateRange(DateTimeRange(
          start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 10)));
      expect(provider.visibleRecords.map((r) => r.date),
          ['2026-11-10', '2026-11-05']);

      await provider.clearFilters();
      expect(provider.visibleRecords, hasLength(3));
      expect(provider.hasActiveFilters, isFalse);
    });

    test('no search results yields an empty list', () async {
      await provider.init();
      await provider.setSearchQuery('1990-01-01');
      expect(provider.visibleRecords, isEmpty);
    });

    test('clearSampleRecords keeps user-entered records', () async {
      await provider.init();
      // Today's sample exists; remove it, then add a real record for it.
      final today = provider.findByDate(DateHelper.toIso(fixedNow))!;
      await provider.deleteRecord(today.id!);
      await provider.addRecord(record('2026-11-06', steps: 777));

      await provider.clearSampleRecords();

      expect(provider.allRecords.single.steps, 777);
    });
  });

  group('DashboardProvider', () {
    test('recomputes when records change', () async {
      final settings = SettingsProvider(prefs);
      await provider.init();
      await provider.clearSampleRecords();
      final dashboard =
          DashboardProvider(provider, settings, clock: () => fixedNow);
      expect(dashboard.stats.hasRecords, isFalse);

      var notified = 0;
      dashboard.addListener(() => notified++);

      await provider.addRecord(
          record('2026-11-06', steps: 8000, calories: 400, water: 2000));
      expect(dashboard.stats.today.steps, 8000);
      expect(dashboard.stats.totalCalories, 400);
      expect(notified, greaterThan(0));

      final id = provider.allRecords.single.id!;
      await provider.updateRecord(
          provider.allRecords.single.copyWith(steps: 9000));
      expect(dashboard.stats.today.steps, 9000);

      await provider.deleteRecord(id);
      expect(dashboard.stats.today.steps, 0);
      expect(dashboard.stats.hasRecords, isFalse);

      dashboard.dispose();
    });

    test('exposes goals and reacts to goal changes', () async {
      final settings = SettingsProvider(prefs);
      final dashboard =
          DashboardProvider(provider, settings, clock: () => fixedNow);
      expect(dashboard.goals.steps, 10000);

      await settings.updateGoals(const UserGoals(steps: 12000, water: 3000, calories: 600));

      expect(dashboard.goals.steps, 12000);
      expect(prefs.getInt('goal_steps'), 12000);
      dashboard.dispose();
    });
  });

  group('SettingsProvider', () {
    test('goals and theme persist across instances', () async {
      final a = SettingsProvider(prefs);
      await a.updateGoals(const UserGoals(steps: 9000, water: 2000, calories: 450));
      await a.setThemeMode(ThemeMode.dark);

      final b = SettingsProvider(prefs);
      expect(b.goals.steps, 9000);
      expect(b.goals.water, 2000);
      expect(b.goals.calories, 450);
      expect(b.themeMode, ThemeMode.dark);
    });
  });
}
