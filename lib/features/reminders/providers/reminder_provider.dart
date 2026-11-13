import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import '../services/reminder_scheduler.dart';

/// Daily check-in and water reminders. Choices are saved in SharedPreferences
/// and (re)scheduled every time the app starts.
class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._prefs, this._scheduler);

  final SharedPreferences _prefs;
  final ReminderScheduler _scheduler;

  static const int dailyId = 100;
  static const int waterBaseId = 200;

  static const _dailyKey = 'reminder_daily_on';
  static const _hourKey = 'reminder_daily_hour';
  static const _minuteKey = 'reminder_daily_minute';
  static const _waterKey = 'reminder_water_on';

  ReminderSettings _settings = const ReminderSettings();

  ReminderSettings get settings => _settings;

  Future<void> init() async {
    const defaults = ReminderSettings();
    _settings = ReminderSettings(
      dailyEnabled: _prefs.getBool(_dailyKey) ?? defaults.dailyEnabled,
      dailyHour: _prefs.getInt(_hourKey) ?? defaults.dailyHour,
      dailyMinute: _prefs.getInt(_minuteKey) ?? defaults.dailyMinute,
      waterEnabled: _prefs.getBool(_waterKey) ?? defaults.waterEnabled,
    );
    notifyListeners();
    if (_settings.anyEnabled) {
      try {
        await _apply(_settings);
      } catch (_) {
        // The reminders could not be restored; the switches stay as saved.
      }
    }
  }

  /// Each setter returns null on success, otherwise a message for the user.
  Future<String?> setDailyEnabled(bool value) =>
      _update(_settings.copyWith(dailyEnabled: value));

  Future<String?> setDailyTime(int hour, int minute) =>
      _update(_settings.copyWith(dailyHour: hour, dailyMinute: minute));

  Future<String?> setWaterEnabled(bool value) =>
      _update(_settings.copyWith(waterEnabled: value));

  Future<String?> _update(ReminderSettings next) async {
    final turningOn = (next.dailyEnabled && !_settings.dailyEnabled) ||
        (next.waterEnabled && !_settings.waterEnabled);
    if (turningOn) {
      var granted = false;
      try {
        granted = await _scheduler.requestPermission();
      } catch (_) {
        granted = false;
      }
      if (!granted) {
        return 'Notifications are blocked. Allow them for HealthMate in your '
            'phone settings, then try again.';
      }
    }

    try {
      await _apply(next);
    } catch (_) {
      return 'Could not schedule the reminder. Please try again.';
    }

    _settings = next;
    await _prefs.setBool(_dailyKey, next.dailyEnabled);
    await _prefs.setInt(_hourKey, next.dailyHour);
    await _prefs.setInt(_minuteKey, next.dailyMinute);
    await _prefs.setBool(_waterKey, next.waterEnabled);
    notifyListeners();
    return null;
  }

  Future<void> _apply(ReminderSettings settings) async {
    if (settings.dailyEnabled) {
      await _scheduler.scheduleDaily(
        id: dailyId,
        hour: settings.dailyHour,
        minute: settings.dailyMinute,
        title: 'How was your day?',
        body: 'Log your steps, water and mood in HealthMate.',
      );
    } else {
      await _scheduler.cancel(dailyId);
    }

    for (var i = 0; i < ReminderSettings.waterHours.length; i++) {
      final id = waterBaseId + i;
      if (settings.waterEnabled) {
        await _scheduler.scheduleDaily(
          id: id,
          hour: ReminderSettings.waterHours[i],
          minute: 0,
          title: 'Time for some water 💧',
          body: 'A glass of water keeps you on track for today\'s goal.',
        );
      } else {
        await _scheduler.cancel(id);
      }
    }
  }
}
