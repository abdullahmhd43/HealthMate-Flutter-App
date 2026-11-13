import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/features/health_records/repositories/health_record_repository.dart';
import 'package:healthmate/features/wellness/models/mood_entry.dart';
import 'package:healthmate/features/wellness/models/sleep_entry.dart';
import 'package:healthmate/features/wellness/models/workout_entry.dart';
import 'package:healthmate/features/wellness/providers/wellness_provider.dart';
import 'package:healthmate/features/wellness/repositories/wellness_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late DatabaseHelper helper;
  late WellnessRepository repo;

  setUp(() {
    helper = newInMemoryHelper();
    repo = WellnessRepository(helper);
  });

  tearDown(() async => helper.close());

  group('sleep', () {
    test('saves, reads newest first and replaces the same date', () async {
      await repo.saveSleep(
          const SleepEntry(date: '2026-11-01', hours: 7, quality: 3));
      await repo.saveSleep(
          const SleepEntry(date: '2026-11-03', hours: 8, quality: 5));
      final id = await repo.saveSleep(
          const SleepEntry(date: '2026-11-02', hours: 6, quality: 2));
      final replacedId = await repo.saveSleep(
          const SleepEntry(date: '2026-11-02', hours: 6.5, quality: 3));

      expect(replacedId, id);
      final all = await repo.getSleep();
      expect(all.map((e) => e.date), ['2026-11-03', '2026-11-02', '2026-11-01']);
      expect(all[1].hours, 6.5);
    });

    test('rejects impossible hours and bad quality', () async {
      expect(
          () => repo.saveSleep(
              const SleepEntry(date: '2026-11-01', hours: 0, quality: 3)),
          throwsA(isA<RepositoryException>()));
      expect(
          () => repo.saveSleep(
              const SleepEntry(date: '2026-11-01', hours: 30, quality: 3)),
          throwsA(isA<RepositoryException>()));
      expect(
          () => repo.saveSleep(
              const SleepEntry(date: '2026-11-01', hours: 7, quality: 9)),
          throwsA(isA<RepositoryException>()));
    });

    test('delete removes the row, then reports it missing', () async {
      final id = await repo.saveSleep(
          const SleepEntry(date: '2026-11-01', hours: 7, quality: 3));
      await repo.deleteSleep(id);
      expect(await repo.getSleep(), isEmpty);
      expect(() => repo.deleteSleep(id),
          throwsA(isA<RecordNotFoundException>()));
    });
  });

  group('workouts', () {
    test('allows several sessions on one day', () async {
      await repo.addWorkout(const WorkoutEntry(
          date: '2026-11-01', type: 'Running', minutes: 30, calories: 300));
      await repo.addWorkout(const WorkoutEntry(
          date: '2026-11-01', type: 'Yoga', minutes: 20, note: 'evening'));
      await repo.addWorkout(
          const WorkoutEntry(date: '2026-11-02', type: 'Gym', minutes: 45));

      final all = await repo.getWorkouts();
      expect(all, hasLength(3));
      expect(all.first.date, '2026-11-02');
      expect(all.last.type, 'Running'); // same day: older id last
      expect(all.firstWhere((w) => w.type == 'Yoga').note, 'evening');
    });

    test('rejects zero minutes, too many calories and long notes', () async {
      Future<void> add(WorkoutEntry e) => repo.addWorkout(e);
      expect(
          () => add(const WorkoutEntry(
              date: '2026-11-01', type: 'Gym', minutes: 0)),
          throwsA(isA<RepositoryException>()));
      expect(
          () => add(const WorkoutEntry(
              date: '2026-11-01', type: 'Gym', minutes: 30, calories: 99999)),
          throwsA(isA<RepositoryException>()));
      expect(
          () => add(WorkoutEntry(
              date: '2026-11-01', type: 'Gym', minutes: 30, note: 'x' * 61)),
          throwsA(isA<RepositoryException>()));
    });

    test('delete removes only that session', () async {
      final a = await repo.addWorkout(
          const WorkoutEntry(date: '2026-11-01', type: 'Gym', minutes: 30));
      await repo.addWorkout(
          const WorkoutEntry(date: '2026-11-01', type: 'Yoga', minutes: 20));
      await repo.deleteWorkout(a);
      final all = await repo.getWorkouts();
      expect(all.single.type, 'Yoga');
    });
  });

  group('mood', () {
    test('saves one mood per date and replaces on re-save', () async {
      await repo.saveMood(const MoodEntry(date: '2026-11-01', mood: 2));
      await repo
          .saveMood(const MoodEntry(date: '2026-11-01', mood: 5, note: 'better'));
      final all = await repo.getMoods();
      expect(all, hasLength(1));
      expect(all.single.mood, 5);
      expect(all.single.note, 'better');
    });

    test('rejects a mood outside 1 to 5', () async {
      expect(() => repo.saveMood(const MoodEntry(date: '2026-11-01', mood: 0)),
          throwsA(isA<RepositoryException>()));
      expect(() => repo.saveMood(const MoodEntry(date: '2026-11-01', mood: 6)),
          throwsA(isA<RepositoryException>()));
    });

    test('mood scale helpers clamp out-of-range values', () {
      expect(MoodScale.emoji(0), MoodScale.emojis.first);
      expect(MoodScale.label(9), 'Great');
    });
  });

  group('WellnessProvider', () {
    late WellnessProvider provider;

    setUp(() {
      provider = WellnessProvider(repo, clock: () => DateTime(2026, 11, 10, 9));
    });

    test('today getters are empty before anything is logged', () async {
      await provider.init();
      expect(provider.sleepToday, isNull);
      expect(provider.moodToday, isNull);
      expect(provider.workoutMinutesToday, 0);
      expect(provider.averageSleepLast7, isNull);
      expect(provider.lastDays(7), hasLength(7));
      expect(provider.lastDays(7).last, DateTime(2026, 11, 10));
    });

    test('sleep today and the 7 day average ignore older nights', () async {
      expect(
          await provider.saveSleep(
              const SleepEntry(date: '2026-11-10', hours: 7.5, quality: 4)),
          isNull);
      await provider.saveSleep(
          const SleepEntry(date: '2026-11-09', hours: 6.5, quality: 3));
      await provider.saveSleep(
          const SleepEntry(date: '2026-10-01', hours: 3, quality: 1));

      expect(provider.sleepToday!.hours, 7.5);
      expect(provider.averageSleepLast7, closeTo(7.0, 0.001));
    });

    test('workout minutes add up per day and over the week', () async {
      await provider.addWorkout(
          const WorkoutEntry(date: '2026-11-10', type: 'Gym', minutes: 30));
      await provider.addWorkout(
          const WorkoutEntry(date: '2026-11-10', type: 'Yoga', minutes: 15));
      await provider.addWorkout(
          const WorkoutEntry(date: '2026-11-08', type: 'Running', minutes: 40));
      await provider.addWorkout(
          const WorkoutEntry(date: '2026-10-01', type: 'Running', minutes: 99));

      expect(provider.workoutMinutesToday, 45);
      expect(provider.workoutsToday, hasLength(2));
      expect(provider.workoutMinutesLast7, 85);
    });

    test('mood average and delete', () async {
      await provider.saveMood(const MoodEntry(date: '2026-11-10', mood: 5));
      await provider.saveMood(const MoodEntry(date: '2026-11-09', mood: 3));
      expect(provider.averageMoodLast7, closeTo(4.0, 0.001));
      expect(provider.moodToday!.mood, 5);

      expect(await provider.deleteMood(provider.moodToday!.id!), isNull);
      expect(provider.moodToday, isNull);
    });

    test('returns a message instead of throwing for invalid input', () async {
      expect(
          await provider.saveSleep(
              const SleepEntry(date: '2026-11-10', hours: 99, quality: 3)),
          isNotNull);
      expect(
          await provider.addWorkout(
              const WorkoutEntry(date: '2026-11-10', type: 'Gym', minutes: 0)),
          isNotNull);
    });
  });

  group('database upgrade 2 -> 3', () {
    test('keeps records and weights and adds the wellness tables', () async {
      final dir = await Directory.systemTemp.createTemp('healthmate_db3_');
      final path = p.join(dir.path, 'upgrade.db');

      // A version 2 database exactly as the previous release created it.
      final v2 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE health_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL UNIQUE,
                steps INTEGER NOT NULL,
                calories INTEGER NOT NULL,
                water INTEGER NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE weight_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL UNIQUE,
                weight_kg REAL NOT NULL
              )
            ''');
          },
        ),
      );
      await v2.insert('health_records',
          {'date': '2026-11-01', 'steps': 8000, 'calories': 320, 'water': 2000});
      await v2.insert('weight_logs', {'date': '2026-11-01', 'weight_kg': 70.5});
      await v2.close();

      final upgraded = DatabaseHelper(pathOverride: path);
      final wellness = WellnessRepository(upgraded);

      // Old data survived.
      final records = await newRepository(upgraded).getAll();
      expect(records.single.steps, 8000);
      final db = await upgraded.database;
      expect((await db.query('weight_logs')).single['weight_kg'], 70.5);

      // New tables work.
      await wellness.saveSleep(
          const SleepEntry(date: '2026-11-01', hours: 7, quality: 4));
      await wellness.addWorkout(
          const WorkoutEntry(date: '2026-11-01', type: 'Gym', minutes: 30));
      await wellness.saveMood(const MoodEntry(date: '2026-11-01', mood: 4));
      expect(await wellness.getSleep(), hasLength(1));
      expect(await wellness.getWorkouts(), hasLength(1));
      expect(await wellness.getMoods(), hasLength(1));

      await upgraded.close();
      await dir.delete(recursive: true);
    });
  });
}
