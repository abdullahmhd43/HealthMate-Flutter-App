import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_helper.dart';
import '../models/health_record.dart';

/// Base class for errors raised by the data layer. The [message] is safe to
/// show to the user.
class RepositoryException implements Exception {
  RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException: $message';
}

/// Thrown when a record already exists for the given date.
class DuplicateDateException extends RepositoryException {
  DuplicateDateException(this.date)
      : super('A record for this date already exists.');

  final String date;
}

/// Thrown when the record to update or delete no longer exists.
class RecordNotFoundException extends RepositoryException {
  RecordNotFoundException() : super('That record could not be found.');
}

/// All SQLite access for `health_records`. Every query is parameterised.
class HealthRecordRepository {
  HealthRecordRepository(this._helper);

  final DatabaseHelper _helper;

  static const String _table = AppConstants.recordsTable;

  Future<int> insert(HealthRecord record) async {
    final problem = record.validate();
    if (problem != null) throw RepositoryException(problem);
    try {
      final db = await _helper.database;
      final values = record.toMap()..remove('id');
      return await db.insert(_table, values,
          conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateDateException(record.date);
      throw RepositoryException('Could not save the record.', e);
    }
  }

  /// Inserts many records in one transaction. Dates that already exist are
  /// skipped. Returns the ids of the rows that were inserted.
  Future<List<int>> insertAll(List<HealthRecord> records) async {
    try {
      final db = await _helper.database;
      final ids = <int>[];
      await db.transaction((txn) async {
        for (final record in records) {
          final clash = await txn.query(
            _table,
            columns: ['id'],
            where: 'date = ?',
            whereArgs: [record.date],
            limit: 1,
          );
          if (clash.isNotEmpty) continue;
          ids.add(await txn.insert(
            _table,
            record.toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.abort,
          ));
        }
      });
      return ids;
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not save the records.', e);
    }
  }

  Future<List<HealthRecord>> getAll() async {
    try {
      final db = await _helper.database;
      final rows = await db.query(_table, orderBy: 'date DESC');
      return rows.map(HealthRecord.fromMap).toList();
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not load your records.', e);
    }
  }

  Future<HealthRecord?> getById(int id) async {
    try {
      final db = await _helper.database;
      final rows =
          await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
      return rows.isEmpty ? null : HealthRecord.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not load the record.', e);
    }
  }

  Future<HealthRecord?> getByDate(String isoDate) async {
    try {
      final db = await _helper.database;
      final rows = await db
          .query(_table, where: 'date = ?', whereArgs: [isoDate], limit: 1);
      return rows.isEmpty ? null : HealthRecord.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not load the record.', e);
    }
  }

  Future<int> update(HealthRecord record) async {
    final id = record.id;
    if (id == null) throw RepositoryException('Cannot update an unsaved record.');
    final problem = record.validate();
    if (problem != null) throw RepositoryException(problem);
    try {
      final db = await _helper.database;
      final count = await db.update(
        _table,
        record.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (count == 0) throw RecordNotFoundException();
      return count;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateDateException(record.date);
      throw RepositoryException('Could not update the record.', e);
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _helper.database;
      final count = await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      if (count == 0) throw RecordNotFoundException();
      return count;
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not delete the record.', e);
    }
  }

  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final db = await _helper.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      return await db.delete(_table,
          where: 'id IN ($placeholders)', whereArgs: ids);
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not delete the records.', e);
    }
  }

  Future<int> count() async {
    try {
      final db = await _helper.database;
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
      return Sqflite.firstIntValue(result) ?? 0;
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not read the records.', e);
    }
  }

  /// Searches and/or filters records, newest first.
  ///
  /// * [dateContains] matches any part of the stored `yyyy-MM-dd` date, so
  ///   `2026-11` finds every record in November 2026.
  /// * [startDate] / [endDate] (inclusive, ISO) filter by date range.
  Future<List<HealthRecord>> query({
    String? dateContains,
    String? startDate,
    String? endDate,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];

    final search = dateContains == null
        ? ''
        : DateHelper.normalizeSearch(dateContains);
    if (search.isNotEmpty) {
      clauses.add("date LIKE ? ESCAPE '\\'");
      args.add('%${_escapeLike(search)}%');
    }
    if (startDate != null) {
      clauses.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      clauses.add('date <= ?');
      args.add(endDate);
    }

    try {
      final db = await _helper.database;
      final rows = await db.query(
        _table,
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC',
      );
      return rows.map(HealthRecord.fromMap).toList();
    } on DatabaseException catch (e) {
      throw RepositoryException('Could not search your records.', e);
    }
  }

  Future<List<HealthRecord>> searchByDate(String text) =>
      query(dateContains: text);

  Future<List<HealthRecord>> getByDateRange(String startDate, String endDate) =>
      query(startDate: startDate, endDate: endDate);

  static String _escapeLike(String input) => input
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}
