import 'package:flutter/foundation.dart';

import '../../health_records/repositories/health_record_repository.dart';
import '../models/weight_entry.dart';
import '../repositories/weight_repository.dart';

/// Weight log state. [entries] is newest first.
class WeightProvider extends ChangeNotifier {
  WeightProvider(this._repository);

  final WeightRepository _repository;

  List<WeightEntry> _entries = const [];
  bool _loading = false;
  String? _error;

  List<WeightEntry> get entries => _entries;
  bool get isLoading => _loading;
  String? get error => _error;

  WeightEntry? get latest => _entries.isEmpty ? null : _entries.first;

  /// Latest weight minus the first ever logged weight (null with < 2 entries).
  double? get changeSinceStart => _entries.length < 2
      ? null
      : _entries.first.weightKg - _entries.last.weightKg;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
      _error = null;
    } on RepositoryException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while loading your weight history.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Saves a weight. Returns null on success, otherwise a message.
  Future<String?> add(WeightEntry entry) async {
    try {
      await _repository.save(entry);
      _entries = await _repository.getAll();
      _error = null;
      notifyListeners();
      return null;
    } on RepositoryException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> delete(int id) async {
    try {
      await _repository.delete(id);
      _entries = await _repository.getAll();
      notifyListeners();
      return null;
    } on RepositoryException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }
}
