import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_helper.dart';

/// Turns the phone's "steps since boot" counter into "steps today".
///
/// The Android sensor never resets at midnight, so each day needs a starting
/// point. Everything is stored in SharedPreferences so it survives restarts.
///
/// * Same day: today = carry + (reading - base).
/// * First reading of a new day: if the previous reading was yesterday and the
///   counter has not gone backwards, yesterday's last reading is the base, so
///   steps walked while the app was closed (overnight, early morning) are
///   counted. After a longer gap (or a reboot) counting restarts from the
///   new reading, because the steps cannot be placed on a day.
/// * Reboot (reading lower than the previous reading): the counter restarted
///   from 0, so the steps already counted today are carried over. This works
///   for any number of reboots.
///
/// Steps taken before the first reading ever received cannot be known.
class StepTracker {
  StepTracker(this._prefs);

  final SharedPreferences _prefs;

  static const _dateKey = 'steps_base_date';
  static const _baseKey = 'steps_base_value';
  static const _carryKey = 'steps_carry';
  static const _lastKey = 'steps_last_today';
  static const _lastReadingKey = 'steps_last_reading';

  /// Returns today's step count for the sensor reading [cumulative].
  int onSensorValue(int cumulative, DateTime now) {
    final today = DateHelper.toIso(now);
    final yesterday =
        DateHelper.toIso(DateTime(now.year, now.month, now.day - 1));
    final lastDate = _prefs.getString(_dateKey);
    final lastReading = _prefs.getInt(_lastReadingKey);
    var base = _prefs.getInt(_baseKey) ?? cumulative;
    var carry = _prefs.getInt(_carryKey) ?? 0;
    final lastToday = _prefs.getInt(_lastKey) ?? 0;

    if (lastDate != today) {
      // First reading ever, or the first reading of a new day.
      carry = 0;
      final continuedFromYesterday = lastDate == yesterday &&
          lastReading != null &&
          cumulative >= lastReading;
      base = continuedFromYesterday ? lastReading : cumulative;
    } else if (lastReading != null && cumulative < lastReading) {
      // The phone rebooted: the sensor counter started again from 0.
      carry = lastToday;
      base = 0;
    }

    final steps = carry + (cumulative - base);
    final result = steps < 0 ? 0 : steps;

    _prefs.setString(_dateKey, today);
    _prefs.setInt(_baseKey, base);
    _prefs.setInt(_carryKey, carry);
    _prefs.setInt(_lastKey, result);
    _prefs.setInt(_lastReadingKey, cumulative);
    return result;
  }
}
