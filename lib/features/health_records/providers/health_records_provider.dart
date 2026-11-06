import 'package:flutter/material.dart';

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
  Future<String?> updateRecord(HealthRecord record) =>
      _mutate(() => _repository.update(record), pre: () {
        return Validators.duplicateDate(record.date, _all,
            excludeId: record.id);
      });

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
