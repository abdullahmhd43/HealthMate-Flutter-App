import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_goals.dart';

/// Daily goals and theme preference, persisted with SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _goals = UserGoals(
      steps: _prefs.getInt(_stepsKey) ?? const UserGoals().steps,
      water: _prefs.getInt(_waterKey) ?? const UserGoals().water,
      calories: _prefs.getInt(_caloriesKey) ?? const UserGoals().calories,
    );
    final stored = _prefs.getString(_themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  final SharedPreferences _prefs;

  static const String _stepsKey = 'goal_steps';
  static const String _waterKey = 'goal_water';
  static const String _caloriesKey = 'goal_calories';
  static const String _themeKey = 'theme_mode';

  late UserGoals _goals;
  late ThemeMode _themeMode;

  UserGoals get goals => _goals;
  ThemeMode get themeMode => _themeMode;

  Future<void> updateGoals(UserGoals goals) async {
    _goals = goals;
    notifyListeners();
    await _prefs.setInt(_stepsKey, goals.steps);
    await _prefs.setInt(_waterKey, goals.water);
    await _prefs.setInt(_caloriesKey, goals.calories);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }
}
