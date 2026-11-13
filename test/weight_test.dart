import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/features/health_records/repositories/health_record_repository.dart';
import 'package:healthmate/features/weight/models/weight_entry.dart';
import 'package:healthmate/features/weight/providers/weight_provider.dart';
import 'package:healthmate/features/weight/repositories/weight_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late DatabaseHelper helper;
  late WeightRepository repo;

  setUp(() {
    helper = newInMemoryHelper();
    repo = WeightRepository(helper);
  });

  tearDown(() async => helper.close());

  group('WeightRepository', () {
    test('saves and reads back, newest first', () async {
      await repo.save(const WeightEntry(date: '2026-11-01', weightKg: 70.5));
      await repo.save(const WeightEntry(date: '2026-11-03', weightKg: 69.8));
      await repo.save(const WeightEntry(date: '2026-11-02', weightKg: 70.1));

      final all = await repo.getAll();
      expect(all.map((e) => e.date), ['2026-11-03', '2026-11-02', '2026-11-01']);
      expect(all.first.weightKg, 69.8);
    });

    test('saving the same date replaces the weight', () async {
      final id1 =
          await repo.save(const WeightEntry(date: '2026-11-01', weightKg: 70));
      final id2 =
          await repo.save(const WeightEntry(date: '2026-11-01', weightKg: 69));

      expect(id2, id1);
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.weightKg, 69);
    });

    test('delete removes the row', () async {
      final id =
          await repo.save(const WeightEntry(date: '2026-11-01', weightKg: 70));
      await repo.delete(id);
      expect(await repo.getAll(), isEmpty);
      expect(() => repo.delete(id), throwsA(isA<RecordNotFoundException>()));
    });

    test('rejects invalid entries', () async {
      expect(() => repo.save(const WeightEntry(date: 'bad', weightKg: 70)),
          throwsA(isA<RepositoryException>()));
      expect(
          () => repo.save(const WeightEntry(date: '2026-11-01', weightKg: 5)),
          throwsA(isA<RepositoryException>()));
    });
  });

  group('WeightProvider', () {
    test('tracks latest weight and change since the first entry', () async {
      final provider = WeightProvider(repo);
      await provider.init();
      expect(provider.latest, isNull);
      expect(provider.changeSinceStart, isNull);

      await provider.add(const WeightEntry(date: '2026-10-01', weightKg: 72));
      expect(provider.changeSinceStart, isNull); // needs two entries
      await provider.add(const WeightEntry(date: '2026-11-01', weightKg: 70));

      expect(provider.latest!.weightKg, 70);
      expect(provider.changeSinceStart, closeTo(-2, 0.001));
    });

    test('delete updates the list', () async {
      final provider = WeightProvider(repo);
      await provider.add(const WeightEntry(date: '2026-11-01', weightKg: 70));
      final id = provider.entries.single.id!;

      expect(await provider.delete(id), isNull);
      expect(provider.entries, isEmpty);
    });

    test('returns a message for invalid weight', () async {
      final provider = WeightProvider(repo);
      expect(await provider.add(const WeightEntry(date: '2026-11-01', weightKg: 1)),
          isNotNull);
    });
  });

  group('database upgrade 1 -> 2', () {
    test('keeps existing health records and adds weight_logs', () async {
      final dir = await Directory.systemTemp.createTemp('healthmate_db_');
      final path = p.join(dir.path, 'upgrade.db');

      // Create a version 1 database exactly as the first release did.
      final v1 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute('''
            CREATE TABLE health_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              steps INTEGER NOT NULL,
              calories INTEGER NOT NULL,
              water INTEGER NOT NULL
            )
          '''),
        ),
      );
      await v1.insert('health_records',
          {'date': '2026-11-01', 'steps': 8000, 'calories': 320, 'water': 2000});
      await v1.close();

      // Open with the current helper, which is version 2.
      final upgraded = DatabaseHelper(pathOverride: path);
      final records = newRepository(upgraded);
      final weights = WeightRepository(upgraded);

      final all = await records.getAll();
      expect(all, hasLength(1));
      expect(all.single.steps, 8000);

      await weights.save(const WeightEntry(date: '2026-11-01', weightKg: 70));
      expect(await weights.getAll(), hasLength(1));

      await upgraded.close();
      await dir.delete(recursive: true);
    });
  });
}
