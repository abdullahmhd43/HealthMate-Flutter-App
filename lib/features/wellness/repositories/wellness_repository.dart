import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../health_records/repositories/health_record_repository.dart';
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import '../models/workout_entry.dart';

/// SQLite access for `sleep_logs`, `workout_logs` and `mood_logs`.
/// Every query is parameterised and every entry is validated first.
class WellnessRepository {
  WellnessRepository(this._helper);

  final DatabaseHelper _helper;

  Future<T> _guard<T>(
    String message,
    Future<T> Function(Database db) body,
  ) async {
    try {
      return await body(await _helper.database);
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (err) {
      throw RepositoryException(message, err);
    }
  }

  /// Insert, or replace the row that already uses [date] (one row per date).
  Future<int> _upsertByDate(
    Database db,
    String table,
    String date,
    Map<String, Object?> values,
  ) async {
    final existing = await db.query(
      table,
      columns: ['id'],
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(table, values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert(table, values);
  }

  Future<void> _deleteById(Database db, String table, int id) async {
    final count = await db.delete(table, where: 'id = ?', whereArgs: [id]);
    if (count == 0) throw RecordNotFoundException();
  }

  // ---------------------------------------------------------------- sleep
  Future<int> saveSleep(SleepEntry entry) {
    final problem = entry.validate();
    if (problem != null) throw RepositoryException(problem);
    return _guard(
      'Could not save your sleep.',
      (db) => _upsertByDate(
        db,
        AppConstants.sleepTable,
        entry.date,
        entry.toMap()..remove('id'),
      ),
    );
  }

  Future<List<SleepEntry>> getSleep() => _guard(
        'Could not load your sleep history.',
        (db) async {
          final rows =
              await db.query(AppConstants.sleepTable, orderBy: 'date DESC');
          return rows.map(SleepEntry.fromMap).toList();
        },
      );

  Future<void> deleteSleep(int id) => _guard(
        'Could not delete the entry.',
        (db) => _deleteById(db, AppConstants.sleepTable, id),
      );

  // ------------------------------------------------------------- workouts
  Future<int> addWorkout(WorkoutEntry entry) {
    final problem = entry.validate();
    if (problem != null) throw RepositoryException(problem);
    return _guard(
      'Could not save your workout.',
      (db) => db.insert(
        AppConstants.workoutTable,
        entry.toMap()..remove('id'),
      ),
    );
  }

  Future<List<WorkoutEntry>> getWorkouts() => _guard(
        'Could not load your workouts.',
        (db) async {
          final rows = await db.query(AppConstants.workoutTable,
              orderBy: 'date DESC, id DESC');
          return rows.map(WorkoutEntry.fromMap).toList();
        },
      );

  Future<void> deleteWorkout(int id) => _guard(
        'Could not delete the workout.',
        (db) => _deleteById(db, AppConstants.workoutTable, id),
      );

  // ----------------------------------------------------------------- mood
  Future<int> saveMood(MoodEntry entry) {
    final problem = entry.validate();
    if (problem != null) throw RepositoryException(problem);
    return _guard(
      'Could not save your mood.',
      (db) => _upsertByDate(
        db,
        AppConstants.moodTable,
        entry.date,
        entry.toMap()..remove('id'),
      ),
    );
  }

  Future<List<MoodEntry>> getMoods() => _guard(
        'Could not load your mood history.',
        (db) async {
          final rows =
              await db.query(AppConstants.moodTable, orderBy: 'date DESC');
          return rows.map(MoodEntry.fromMap).toList();
        },
      );

  Future<void> deleteMood(int id) => _guard(
        'Could not delete the entry.',
        (db) => _deleteById(db, AppConstants.moodTable, id),
      );
}
