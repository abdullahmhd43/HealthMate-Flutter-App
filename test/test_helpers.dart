import 'package:healthmate/core/database/database_helper.dart';
import 'package:healthmate/features/health_records/models/health_record.dart';
import 'package:healthmate/features/health_records/repositories/health_record_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once per test file (in `setUpAll`) to run sqflite on the desktop VM.
void initTestDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// A brand-new, empty, in-memory database.
DatabaseHelper newInMemoryHelper() =>
    DatabaseHelper(pathOverride: inMemoryDatabasePath);

HealthRecord record(
  String date, {
  int steps = 5000,
  int calories = 300,
  int water = 1500,
  int? id,
}) =>
    HealthRecord(
      id: id,
      date: date,
      steps: steps,
      calories: calories,
      water: water,
    );

HealthRecordRepository newRepository(DatabaseHelper helper) =>
    HealthRecordRepository(helper);
