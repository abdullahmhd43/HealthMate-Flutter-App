import 'package:flutter/foundation.dart';

import '../../../core/utils/date_helper.dart';
import '../../health_records/repositories/health_record_repository.dart';
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import '../models/workout_entry.dart';
import '../repositories/wellness_repository.dart';

/// Sleep, workout and mood state. Lists are newest first. Every mutation
/// writes to SQLite and then reloads, so the UI always matches the database.
class WellnessProvider extends ChangeNotifier {
  WellnessProvider(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final WellnessRepository _repository;
  final DateTime Function() _clock;

  List<SleepEntry> _sleep = const [];
  List<WorkoutEntry> _workouts = const [];
  List<MoodEntry> _moods = const [];
  bool _loading = false;
  String? _error;

  List<SleepEntry> get sleep => _sleep;
  List<WorkoutEntry> get workouts => _workouts;
  List<MoodEntry> get moods => _moods;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      await _reload();
      _error = null;
    } on RepositoryException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while loading your wellness data.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async {
    _sleep = await _repository.getSleep();
    _workouts = await _repository.getWorkouts();
    _moods = await _repository.getMoods();
  }

  /// Runs a write, reloads, and returns null on success or a message.
  Future<String?> _run(Future<Object?> Function() action) async {
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

  Future<String?> saveSleep(SleepEntry entry) =>
      _run(() => _repository.saveSleep(entry));
  Future<String?> deleteSleep(int id) =>
      _run(() => _repository.deleteSleep(id));

  Future<String?> addWorkout(WorkoutEntry entry) =>
      _run(() => _repository.addWorkout(entry));
  Future<String?> deleteWorkout(int id) =>
      _run(() => _repository.deleteWorkout(id));

  Future<String?> saveMood(MoodEntry entry) =>
      _run(() => _repository.saveMood(entry));
  Future<String?> deleteMood(int id) =>
      _run(() => _repository.deleteMood(id));

  // ------------------------------------------------------------- derived
  DateTime get today => DateHelper.dateOnly(_clock());

  /// The last [count] days ending today, oldest first.
  List<DateTime> lastDays(int count) => [
        for (var i = count - 1; i >= 0; i--)
          DateTime(today.year, today.month, today.day - i),
      ];

  SleepEntry? sleepOn(DateTime day) {
    final iso = DateHelper.toIso(day);
    for (final e in _sleep) {
      if (e.date == iso) return e;
    }
    return null;
  }

  MoodEntry? moodOn(DateTime day) {
    final iso = DateHelper.toIso(day);
    for (final e in _moods) {
      if (e.date == iso) return e;
    }
    return null;
  }

  List<WorkoutEntry> workoutsOn(DateTime day) {
    final iso = DateHelper.toIso(day);
    return _workouts.where((e) => e.date == iso).toList();
  }

  int workoutMinutesOn(DateTime day) =>
      workoutsOn(day).fold<int>(0, (sum, e) => sum + e.minutes);

  SleepEntry? get sleepToday => sleepOn(today);
  MoodEntry? get moodToday => moodOn(today);
  List<WorkoutEntry> get workoutsToday => workoutsOn(today);
  int get workoutMinutesToday => workoutMinutesOn(today);

  /// Average hours over the nights logged in the last 7 days (null if none).
  double? get averageSleepLast7 {
    final entries = lastDays(7).map(sleepOn).whereType<SleepEntry>().toList();
    if (entries.isEmpty) return null;
    return entries.fold<double>(0, (sum, e) => sum + e.hours) / entries.length;
  }

  /// Average mood over the days logged in the last 7 days (null if none).
  double? get averageMoodLast7 {
    final entries = lastDays(7).map(moodOn).whereType<MoodEntry>().toList();
    if (entries.isEmpty) return null;
    return entries.fold<int>(0, (sum, e) => sum + e.mood) / entries.length;
  }

  int get workoutMinutesLast7 =>
      lastDays(7).fold<int>(0, (sum, d) => sum + workoutMinutesOn(d));
}
