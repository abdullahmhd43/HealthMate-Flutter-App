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
  }

  /// Runs when [AppConstants.databaseVersion] is raised. Add each schema
  /// change as an `if (oldVersion < N)` block so existing user data is kept.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 is the first schema, so there is nothing to migrate yet.
    // Example for a future version 2:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE health_records ADD COLUMN notes TEXT');
    // }
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
