import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_helper.dart';
import '../models/health_record.dart';
import '../repositories/health_record_repository.dart';

/// Creates and removes demonstration records.
///
/// The `health_records` table keeps exactly the mandatory columns, so the ids
/// of sample rows are remembered in SharedPreferences. That lets the UI label
/// them "Sample" and lets the user remove only them.
class SampleDataService {
  SampleDataService(this._repository, this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final HealthRecordRepository _repository;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const String _seededKey = 'sample_data_seeded';
  static const String _idsKey = 'sample_record_ids';

  // steps, calories, water (ml) for the 14 days BEFORE today, oldest first.
  // Today is left empty so real steps and water are never mixed with samples.
  static const List<List<int>> _samples = [
    [6240, 310, 1800],
    [8120, 420, 2100],
    [10450, 560, 2600],
    [4980, 250, 1500],
    [12030, 690, 3000],
    [7310, 380, 2000],
    [9020, 470, 2300],
    [5600, 290, 1700],
    [11200, 610, 2800],
    [8800, 450, 2200],
    [3900, 200, 1400],
    [9750, 520, 2450],
    [10100, 540, 2550],
    [7850, 420, 2000],
  ];

  Set<int> get sampleIds =>
      (_prefs.getStringList(_idsKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  /// Inserts the sample records once, and only when the database is empty.
  /// Returns true if records were inserted.
  Future<bool> seedIfNeeded() async {
    if (_prefs.getBool(_seededKey) ?? false) return false;
    final existing = await _repository.count();
    // Never seed over real data, and never seed again after the first run.
    if (existing > 0) {
      await _prefs.setBool(_seededKey, true);
      return false;
    }
    final added = await _insertSamples();
    // Marked only after a successful insert, so a failure is retried.
    await _prefs.setBool(_seededKey, true);
    return added > 0;
  }

  /// Adds sample records for any of the 14 days before today that have none.
  /// Returns how many were added.
  Future<int> restoreSamples() => _insertSamples();

  /// Stops treating [id] as a sample (the user edited it or real data was
  /// added to it), so "Clear samples" no longer deletes it.
  Future<void> forget(int id) async {
    final ids = sampleIds;
    if (!ids.remove(id)) return;
    await _prefs.setStringList(_idsKey, ids.map((e) => '$e').toList());
  }

  /// Deletes only the sample rows. Returns how many were removed.
  Future<int> clearSamples() async {
    final ids = sampleIds.toList();
    final removed = await _repository.deleteMany(ids);
    await _prefs.setStringList(_idsKey, <String>[]);
    return removed;
  }

  Future<int> _insertSamples() async {
    final today = DateHelper.dateOnly(_clock());
    final records = <HealthRecord>[];
    for (var i = 0; i < _samples.length; i++) {
      final daysAgo = _samples.length - i; // 14 ... 1 (never today)
      final date = DateTime(today.year, today.month, today.day - daysAgo);
      records.add(HealthRecord(
        date: DateHelper.toIso(date),
        steps: _samples[i][0],
        calories: _samples[i][1],
        water: _samples[i][2],
      ));
    }
    final ids = await _repository.insertAll(records);
    if (ids.isNotEmpty) {
      await _prefs
          .setStringList(_idsKey, {...sampleIds, ...ids}.map((e) => '$e').toList());
    }
    return ids.length;
  }
}
