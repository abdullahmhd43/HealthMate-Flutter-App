import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/features/health_records/models/health_record.dart';
import 'package:healthmate/features/health_records/repositories/health_record_repository.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late DatabaseHelper helper;
  late HealthRecordRepository repo;

  setUp(() {
    helper = newInMemoryHelper();
    repo = newRepository(helper);
  });

  tearDown(() async => helper.close());

  group('empty database', () {
    test('returns no records and a zero count', () async {
      expect(await repo.getAll(), isEmpty);
      expect(await repo.count(), 0);
      expect(await repo.getById(1), isNull);
    });
  });

  group('insert and retrieve', () {
    test('insert returns an id and the row can be read back', () async {
      final id = await repo.insert(
          record('2026-11-01', steps: 7850, calories: 420, water: 2000));
      expect(id, greaterThan(0));

      final loaded = await repo.getById(id);
      expect(loaded, isNotNull);
      expect(loaded!.date, '2026-11-01');
      expect(loaded.steps, 7850);
      expect(loaded.calories, 420);
      expect(loaded.water, 2000);
    });

    test('getAll returns newest date first', () async {
      await repo.insert(record('2026-11-01'));
      await repo.insert(record('2026-11-03'));
      await repo.insert(record('2026-11-02'));

      final all = await repo.getAll();
      expect(all.map((r) => r.date).toList(),
          ['2026-11-03', '2026-11-02', '2026-11-01']);
    });

    test('rejects a duplicate date', () async {
      await repo.insert(record('2026-11-01'));
      expect(
        () => repo.insert(record('2026-11-01', steps: 1)),
        throwsA(isA<DuplicateDateException>()),
      );
      expect(await repo.count(), 1);
    });

    test('rejects invalid records before they reach the database', () async {
      expect(() => repo.insert(record('not-a-date')),
          throwsA(isA<RepositoryException>()));
      expect(() => repo.insert(record('2026-11-01', steps: -5)),
          throwsA(isA<RepositoryException>()));
      expect(await repo.count(), 0);
    });
  });

  group('update', () {
    test('changes the stored values', () async {
      final id = await repo.insert(record('2026-11-01'));
      await repo.update(
          record('2026-11-02', steps: 9999, calories: 555, water: 2750, id: id));

      final loaded = await repo.getById(id);
      expect(loaded!.date, '2026-11-02');
      expect(loaded.steps, 9999);
      expect(loaded.calories, 555);
      expect(loaded.water, 2750);
      expect(await repo.count(), 1);
    });

    test('cannot move a record onto another record\'s date', () async {
      await repo.insert(record('2026-11-01'));
      final id = await repo.insert(record('2026-11-02'));
      expect(() => repo.update(record('2026-11-01', id: id)),
          throwsA(isA<DuplicateDateException>()));
    });

    test('throws when the record does not exist', () async {
      expect(() => repo.update(record('2026-11-01', id: 999)),
          throwsA(isA<RecordNotFoundException>()));
    });
  });

  group('delete', () {
    test('removes the row from SQLite', () async {
      final id = await repo.insert(record('2026-11-01'));
      await repo.insert(record('2026-11-02'));

      await repo.delete(id);

      expect(await repo.getById(id), isNull);
      expect(await repo.count(), 1);
    });

    test('throws when the record does not exist', () async {
      expect(() => repo.delete(42), throwsA(isA<RecordNotFoundException>()));
    });
  });

  group('search and date filter', () {
    setUp(() async {
      await repo.insert(record('2026-10-30'));
      await repo.insert(record('2026-11-01'));
      await repo.insert(record('2026-11-02'));
      await repo.insert(record('2026-11-15'));
      await repo.insert(record('2026-12-01'));
    });

    test('search by full date finds exactly one record', () async {
      final result = await repo.searchByDate('2026-11-02');
      expect(result.map((r) => r.date), ['2026-11-02']);
    });

    test('search by month prefix finds every record in that month', () async {
      final result = await repo.searchByDate('2026-11');
      expect(result.map((r) => r.date), ['2026-11-15', '2026-11-02', '2026-11-01']);
    });

    test('search accepts dd/MM/yyyy input', () async {
      final result = await repo.searchByDate('15/11/2026');
      expect(result.map((r) => r.date), ['2026-11-15']);
    });

    test('search with no match returns an empty list', () async {
      expect(await repo.searchByDate('1999-01-01'), isEmpty);
    });

    test('search treats % and _ as plain characters', () async {
      expect(await repo.searchByDate('%'), isEmpty);
      expect(await repo.searchByDate('2026_11'), isEmpty);
    });

    test('date range is inclusive at both ends', () async {
      final result = await repo.getByDateRange('2026-11-01', '2026-11-15');
      expect(result.map((r) => r.date), ['2026-11-15', '2026-11-02', '2026-11-01']);
    });

    test('range and search can be combined', () async {
      final result = await repo.query(
        dateContains: '2026-11',
        startDate: '2026-11-02',
        endDate: '2026-12-31',
      );
      expect(result.map((r) => r.date), ['2026-11-15', '2026-11-02']);
    });
  });

  group('sample/bulk inserts', () {
    test('insertAll skips dates that already exist', () async {
      await repo.insert(record('2026-11-01'));
      final ids = await repo.insertAll([
        record('2026-11-01'),
        record('2026-11-02'),
      ]);
      expect(ids, hasLength(1));
      expect(await repo.count(), 2);
    });
  });

  group('HealthRecord model', () {
    test('toMap/fromMap round trip', () {
      const original = HealthRecord(
          id: 3, date: '2026-11-01', steps: 1, calories: 2, water: 3);
      expect(HealthRecord.fromMap(original.toMap()), original);
    });
  });
}
