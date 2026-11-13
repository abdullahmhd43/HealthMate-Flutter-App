import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../health_records/repositories/health_record_repository.dart';
import '../models/weight_entry.dart';

/// SQLite access for `weight_logs`. All queries are parameterised.
class WeightRepository {
  WeightRepository(this._helper);

  final DatabaseHelper _helper;

  static const String _table = AppConstants.weightTable;

  /// Saves a weight. If the date already has an entry, it is replaced.
  /// Returns the row id.
  Future<int> save(WeightEntry entry) async {
    final problem = entry.validate();
    if (problem != null) throw RepositoryException(problem);
    try {
      final db = await _helper.database;
      final existing = await db.query(
        _table,
        columns: ['id'],
        where: 'date = ?',
        whereArgs: [entry.date],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        await db.update(
          _table,
          {'weight_kg': entry.weightKg},
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      }
      return await db.insert(_table, entry.toMap()..remove('id'));
    } on DatabaseException catch (err) {
      throw RepositoryException('Could not save your weight.', err);
    }
  }

  /// All entries, newest first.
  Future<List<WeightEntry>> getAll() async {
    try {
      final db = await _helper.database;
      final rows = await db.query(_table, orderBy: 'date DESC');
      return rows.map(WeightEntry.fromMap).toList();
    } on DatabaseException catch (err) {
      throw RepositoryException('Could not load your weight history.', err);
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await _helper.database;
      final count = await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      if (count == 0) throw RecordNotFoundException();
    } on DatabaseException catch (err) {
      throw RepositoryException('Could not delete the entry.', err);
    }
  }
}
