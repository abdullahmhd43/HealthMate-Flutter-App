import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_helper.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../services/step_sensor.dart';
import '../services/step_tracker.dart';

enum StepStatus { off, starting, active, permissionDenied, unavailable }

/// Automatic step counting. Reads the phone sensor, works out today's steps
/// and saves them into today's record in SQLite (only ever increasing them,
/// and keeping water and manually entered values).
class StepCounterProvider extends ChangeNotifier {
  StepCounterProvider({
    required SharedPreferences prefs,
    required StepSensor sensor,
    required HealthRecordsProvider records,
    required ProfileProvider profile,
    DateTime Function()? clock,
  })  : _prefs = prefs,
        _sensor = sensor,
        _records = records,
        _profile = profile,
        _clock = clock ?? DateTime.now,
        _tracker = StepTracker(prefs);

  static const String _enabledKey = 'auto_steps_enabled';

  /// Save to SQLite after this many new steps...
  static const int syncEverySteps = 25;

  /// ...or after this much time, whichever comes first.
  static const Duration syncEveryDuration = Duration(seconds: 60);

  final SharedPreferences _prefs;
  final StepSensor _sensor;
  final HealthRecordsProvider _records;
  final ProfileProvider _profile;
  final DateTime Function() _clock;
  final StepTracker _tracker;

  StepStatus _status = StepStatus.off;
  int _todaySteps = 0;
  int _lastSynced = 0;
  DateTime? _lastSyncTime;
  String? _lastSyncDate;
  bool _syncing = false;
  StreamSubscription<int>? _subscription;

  bool get enabled => _prefs.getBool(_enabledKey) ?? false;
  StepStatus get status => _status;
  int get todaySteps => _todaySteps;

  /// Call once at app start: resumes counting if it was switched on before.
  Future<void> init() async {
    if (enabled) await _start();
  }

  Future<void> setEnabled(bool value) async {
    if (value) {
      await _start();
      // Only remember "on" when counting really started, so a denied
      // permission does not leave the switch on (and re-ask at every launch).
      await _prefs.setBool(_enabledKey, _status == StepStatus.active);
    } else {
      await _prefs.setBool(_enabledKey, false);
      await _stop();
    }
  }

  Future<void> _start() async {
    _status = StepStatus.starting;
    notifyListeners();

    var granted = false;
    try {
      granted = await _sensor.requestPermission();
    } catch (_) {
      granted = false;
    }
    if (!granted) {
      _status = StepStatus.permissionDenied;
      notifyListeners();
      return;
    }

    await _subscription?.cancel();
    try {
      _subscription = _sensor.stepStream.listen(
        _onSensorValue,
        onError: (Object _) {
          _status = StepStatus.unavailable;
          notifyListeners();
        },
      );
      _lastSyncTime = _clock();
      _status = StepStatus.active;
    } catch (_) {
      _status = StepStatus.unavailable;
    }
    notifyListeners();
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_todaySteps > 0) await syncNow();
    _todaySteps = 0;
    _lastSynced = 0;
    _status = StepStatus.off;
    notifyListeners();
  }

  void _onSensorValue(int cumulative) {
    final now = _clock();
    final today = DateHelper.toIso(now);
    if (_lastSyncDate != today) {
      // A new day: yesterday's "already saved" count must not block saving.
      _lastSyncDate = today;
      _lastSynced = 0;
    }
    _todaySteps = _tracker.onSensorValue(cumulative, now);
    notifyListeners();

    final newSteps = _todaySteps - _lastSynced;
    final waited = _lastSyncTime == null ||
        now.difference(_lastSyncTime!) >= syncEveryDuration;
    if (newSteps >= syncEverySteps || (waited && newSteps > 0)) {
      syncNow();
    }
  }

  /// Saves today's steps to SQLite right away.
  Future<void> syncNow() async {
    if (_syncing || _todaySteps <= 0) return;
    _syncing = true;
    final now = _clock();
    final steps = _todaySteps;
    _lastSyncTime = now;
    try {
      final error = await _records.setTodaySteps(
        steps,
        kcalPerStep: _profile.profile.kcalPerStep,
        now: now,
      );
      // Only count it as saved when it really was, so a failed save is retried.
      if (error == null) _lastSynced = steps;
    } catch (_) {
      // Keep _lastSynced as it was: the next reading tries again.
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
