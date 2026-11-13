import 'dart:io';

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

var _isolatedCounter = 0;

/// A brand-new, empty database in its own temp file. Unlike the shared
/// in-memory database (sqflite hands out the SAME in-memory instance to every
/// helper until it is closed), nothing leaks from one test into the next,
/// which matters for widget tests that cannot await a close in tearDown.
DatabaseHelper newIsolatedHelper() {
  final path = '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'healthmate_test_${DateTime.now().microsecondsSinceEpoch}_'
      '${_isolatedCounter++}.db';
  return DatabaseHelper(pathOverride: path);
}

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
