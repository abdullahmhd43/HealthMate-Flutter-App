import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Opens and owns the SQLite database (`healthmate.db`).
///
/// The database is opened lazily, exactly once per helper instance, and the
/// same connection is reused for the life of the app so it is never recreated
/// unnecessarily.
class DatabaseHelper {
  DatabaseHelper({this.pathOverride});

  /// Shared instance used by the running app.
  static final DatabaseHelper instance = DatabaseHelper();

  /// Optional explicit path. Tests pass `inMemoryDatabasePath`.
  final String? pathOverride;

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    _opening ??= _open();
    try {
      _database = await _opening;
      return _database!;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final path =
        pathOverride ?? p.join(await getDatabasesPath(), AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.recordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL
      )
    ''');
    await _createWeightTable(db);
    await _createWellnessTables(db);
  }

  Future<void> _createWeightTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.weightTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        weight_kg REAL NOT NULL
      )
    ''');
  }

  /// Sleep, workout and mood logs (added in database version 3).
  Future<void> _createWellnessTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.sleepTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        hours REAL NOT NULL,
        quality INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.workoutTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        calories INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_date '
      'ON ${AppConstants.workoutTable}(date)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.moodTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        mood INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// Runs when [AppConstants.databaseVersion] is raised. Add each schema
  /// change as an `if (oldVersion < N)` block so existing user data is kept.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 2 added the weight_logs table. health_records is untouched, so
    // existing user data is kept.
    if (oldVersion < 2) {
      await _createWeightTable(db);
    }
    // Version 3 added sleep_logs, workout_logs and mood_logs.
    if (oldVersion < 3) {
      await _createWellnessTables(db);
    }
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _opening = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
