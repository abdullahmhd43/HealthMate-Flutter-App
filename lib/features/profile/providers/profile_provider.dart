import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Holds the user's profile, persisted with SharedPreferences.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._prefs) {
    _profile = _read();
  }

  final SharedPreferences _prefs;

  static const String _nameKey = 'profile_name';
  static const String _ageKey = 'profile_age';
  static const String _genderKey = 'profile_gender';
  static const String _heightKey = 'profile_height';
  static const String _weightKey = 'profile_weight';

  late UserProfile _profile;

  UserProfile get profile => _profile;

  UserProfile _read() {
    final genderName = _prefs.getString(_genderKey);
    return UserProfile(
      name: _prefs.getString(_nameKey) ?? '',
      age: _prefs.getInt(_ageKey),
      gender: Gender.values.where((g) => g.name == genderName).firstOrNull,
      heightCm: _prefs.getDouble(_heightKey),
      weightKg: _prefs.getDouble(_weightKey),
    );
  }

  Future<void> save(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _prefs.setString(_nameKey, profile.name);
    await _setOrRemoveInt(_ageKey, profile.age);
    await _setOrRemoveString(_genderKey, profile.gender?.name);
    await _setOrRemoveDouble(_heightKey, profile.heightCm);
    await _setOrRemoveDouble(_weightKey, profile.weightKg);
  }

  /// Updates only the weight (used when a new weight is logged).
  Future<void> updateWeight(double kg) => save(_profile.copyWith(weightKg: kg));

  Future<void> _setOrRemoveInt(String key, int? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, value);
    }
  }

  Future<void> _setOrRemoveDouble(String key, double? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setDouble(key, value);
    }
  }

  Future<void> _setOrRemoveString(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }
}
