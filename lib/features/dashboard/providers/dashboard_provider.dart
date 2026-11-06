import 'package:flutter/foundation.dart';

import '../../health_records/providers/health_records_provider.dart';
import '../../settings/models/user_goals.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/dashboard_stats.dart';

/// Derives dashboard/analytics state from [HealthRecordsProvider] and goals
/// from [SettingsProvider]. It listens to both, so whenever a record is
/// added, edited or deleted (or a goal changes) every dependent screen
/// rebuilds with fresh numbers.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._records, this._settings, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _records.addListener(_onSourceChanged);
    _settings.addListener(_onSourceChanged);
    _recompute();
  }

  final HealthRecordsProvider _records;
  final SettingsProvider _settings;
  final DateTime Function() _clock;

  late DashboardStats _stats;

  DashboardStats get stats => _stats;
  UserGoals get goals => _settings.goals;
  DateTime get now => _clock();

  void _onSourceChanged() {
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    _stats = DashboardStats.compute(_records.allRecords, now: _clock());
  }

  @override
  void dispose() {
    _records.removeListener(_onSourceChanged);
    _settings.removeListener(_onSourceChanged);
    super.dispose();
  }
}
