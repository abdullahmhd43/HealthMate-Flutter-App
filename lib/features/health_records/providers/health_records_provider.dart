import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/calorie_estimator.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/validators.dart';
import '../models/health_record.dart';
import '../repositories/health_record_repository.dart';
import '../services/sample_data_service.dart';

/// Single source of truth for health records.
///
/// * [allRecords] is every row in SQLite (used by the dashboard/analytics).
/// * [visibleRecords] is what the History screen shows after search/filter.
///
/// Every mutation writes to SQLite first, then reloads from SQLite, so the UI
/// can never drift away from what is stored.
class HealthRecordsProvider extends ChangeNotifier {
  HealthRecordsProvider(this._repository, this._samples);

  final HealthRecordRepository _repository;
  final SampleDataService _samples;

  List<HealthRecord> _all = const [];
  List<HealthRecord> _visible = const [];
  bool _loading = false;
  bool _initialised = false;
  String? _error;
  String _searchQuery = '';
  DateTimeRange? _range;

  /// Read-modify-write operations (water, sensor steps) run one at a time, and
  /// always start from the row stored in SQLite, so two quick actions can
  /// never overwrite each other with stale values.
  Future<void> _queue = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<HealthRecord?> _stored(String isoDate) async {
    try {
      return await _repository.getByDate(isoDate);
    } on RepositoryException {
      return findByDate(isoDate);
    }
  }

  List<HealthRecord> get allRecords => _all;
  List<HealthRecord> get visibleRecords => _visible;
  bool get isLoading => _loading;
  bool get isInitialised => _initialised;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  DateTimeRange? get dateRange => _range;
  bool get hasActiveFilters => _searchQuery.trim().isNotEmpty || _range != null;
  Set<int> get sampleIds => _samples.sampleIds;
  int get sampleCount =>
      _all.where((r) => r.id != null && sampleIds.contains(r.id)).length;

  bool isSample(HealthRecord record) =>
      record.id != null && sampleIds.contains(record.id);

  /// Seeds sample data on first run (only if the database is empty) and loads.
  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _samples.seedIfNeeded();
      await _reload();
    } on RepositoryException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while opening your data.';
    } finally {
      _loading = false;
      _initialised = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      await _reload();
    } on RepositoryException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while loading your records.';
    }
    notifyListeners();
  }

  /// Adds a record. Returns null on success, otherwise a user-facing message.
  Future<String?> addRecord(HealthRecord record) =>
      _mutate(() => _repository.insert(record), pre: () {
        return Validators.duplicateDate(record.date, _all);
      });

  /// Updates a record. Returns null on success, otherwise a message.
  Future<String?> updateRecord(HealthRecord record) async {
    final error =
        await _mutate(() => _repository.update(record), pre: () {
      return Validators.duplicateDate(record.date, _all,
          excludeId: record.id);
    });
    // An edited sample is now the user's own data: "Clear samples" must keep it.
    if (error == null && record.id != null) {
      await _samples.forget(record.id!);
    }
    return error;
  }

  /// Adds [ml] of water to today's record, creating today's record (with 0
  /// steps and 0 calories) if there is none. Returns null on success,
  /// otherwise a message.
  Future<String?> addWater(int ml, {DateTime? now}) {
    if (ml <= 0) {
      return Future.value('Water amount must be greater than 0');
    }
    return _serial(() => _addWater(ml, now: now));
  }

  Future<String?> _addWater(int ml, {DateTime? now}) async {
    final today = DateHelper.toIso(now ?? DateTime.now());
    final existing = await _stored(today);
    if (existing == null) {
      return addRecord(HealthRecord(
        date: today,
        steps: 0,
        calories: 0,
        water: ml.clamp(0, AppConstants.maxWater).toInt(),
      ));
    }
    final total = (existing.water + ml).clamp(0, AppConstants.maxWater).toInt();
    return updateRecord(existing.copyWith(water: total));
  }

  /// Saves steps counted by the phone sensor into today's record.
  ///
  /// Steps only ever go up (a higher manual entry is never overwritten), and
  /// water and any manually entered calories are kept: only the calories for
  /// the *new* steps are added. Creates today's record if there is none.
  /// Returns null on success, otherwise a message.
  Future<String?> setTodaySteps(
    int steps, {
    double? kcalPerStep,
    DateTime? now,
  }) =>
      _serial(() => _setTodaySteps(steps, kcalPerStep: kcalPerStep, now: now));

  Future<String?> _setTodaySteps(
    int steps, {
    double? kcalPerStep,
    DateTime? now,
  }) async {
    final clamped = steps.clamp(0, AppConstants.maxSteps).toInt();
    final today = DateHelper.toIso(now ?? DateTime.now());
    final existing = await _stored(today);
    if (existing == null) {
      return addRecord(HealthRecord(
        date: today,
        steps: clamped,
        calories: CalorieEstimator.fromSteps(clamped, kcalPerStep: kcalPerStep)
            .clamp(0, AppConstants.maxCalories)
            .toInt(),
        water: 0,
      ));
    }
    if (clamped <= existing.steps) return null;
    final extra = CalorieEstimator.fromSteps(clamped - existing.steps,
        kcalPerStep: kcalPerStep);
    return updateRecord(existing.copyWith(
      steps: clamped,
      calories: (existing.calories + extra)
          .clamp(0, AppConstants.maxCalories)
          .toInt(),
    ));
  }

  /// Deletes a record from SQLite. Returns null on success, otherwise a message.
  Future<String?> deleteRecord(int id) =>
      _mutate(() => _repository.delete(id));

  Future<HealthRecord?> getRecordById(int id) async {
    try {
      return await _repository.getById(id);
    } on RepositoryException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  HealthRecord? findByDate(String isoDate) {
    for (final record in _all) {
      if (record.date == isoDate) return record;
    }
    return null;
  }

  HealthRecord? findById(int id) {
    for (final record in _all) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }

  Future<void> setDateRange(DateTimeRange? range) async {
    _range = range;
    await _applyFilters();
  }

  Future<void> clearFilters() async {
    _searchQuery = '';
    _range = null;
    await _applyFilters();
  }

  Future<int> clearSampleRecords() async {
    try {
      final removed = await _samples.clearSamples();
      await _reload();
      notifyListeners();
      return removed;
    } on RepositoryException catch (e) {
      _error = e.message;
      notifyListeners();
      return 0;
    }
  }

  Future<int> restoreSampleRecords() async {
    try {
      final added = await _samples.restoreSamples();
      await _reload();
      notifyListeners();
      return added;
    } on RepositoryException catch (e) {
      _error = e.message;
      notifyListeners();
      return 0;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------

  Future<String?> _mutate(
    Future<Object?> Function() action, {
    String? Function()? pre,
  }) async {
    final preProblem = pre?.call();
    if (preProblem != null) return preProblem;
    try {
      await action();
      await _reload();
      _error = null;
      notifyListeners();
      return null;
    } on RepositoryException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _applyFilters() async {
    try {
      await _reloadVisible();
      _error = null;
    } on RepositoryException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  Future<void> _reload() async {
    _all = await _repository.getAll();
    await _reloadVisible();
  }

  Future<void> _reloadVisible() async {
    if (!hasActiveFilters) {
      _visible = _all;
      return;
    }
    _visible = await _repository.query(
      dateContains: _searchQuery,
      startDate: _range == null ? null : DateHelper.toIso(_range!.start),
      endDate: _range == null ? null : DateHelper.toIso(_range!.end),
    );
  }
}
