import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.label);
  final String label;
}

/// WHO adult BMI bands.
enum BmiCategory {
  underweight('Underweight', Color(0xFF1E88E5)),
  healthy('Healthy weight', Color(0xFF43A047)),
  overweight('Overweight', Color(0xFFF59E0B)),
  obese('Obese', Color(0xFFE53935));

  const BmiCategory(this.label, this.color);
  final String label;
  final Color color;

  static BmiCategory fromBmi(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.healthy;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}

/// The user's body details, used for BMI and personalised goals.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
  });

  final String name;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;

  /// True when age, height and weight are all known.
  bool get isComplete => age != null && heightCm != null && weightKg != null;

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
      );

  /// Body mass index, or null without height and weight.
  double? get bmi {
    final h = heightCm, w = weightKg;
    if (h == null || w == null || h <= 0) return null;
    final m = h / 100;
    return w / (m * m);
  }

  BmiCategory? get bmiCategory {
    final value = bmi;
    return value == null ? null : BmiCategory.fromBmi(value);
  }

  /// Estimated energy used per step. Uses stride length from height
  /// (about 0.415 x height) and body weight; falls back to the default
  /// average when the profile has no height or weight.
  double get kcalPerStep {
    final w = weightKg, h = heightCm;
    if (w == null || h == null) return AppConstants.caloriesPerStep;
    final strideMetres = h * 0.415 / 100;
    return 0.75 * w * strideMetres / 1000;
  }

  /// Suggested daily step goal for the user's age.
  int get recommendedSteps {
    final a = age;
    if (a == null) return 10000;
    if (a < 18) return 12000;
    if (a <= 64) return 10000;
    return 7000;
  }

  /// About 35 ml of water per kg of body weight, rounded to 50 ml.
  int get recommendedWater {
    final w = weightKg;
    if (w == null) return AppConstants.defaultWaterGoal;
    final rounded = (w * 35 / 50).round() * 50;
    return rounded.clamp(1500, 5000).toInt();
  }

  /// Calories burned by reaching [recommendedSteps], rounded to 10 kcal.
  int get recommendedCalories {
    final value = (recommendedSteps * kcalPerStep / 10).round() * 10;
    return value < 10 ? 10 : value;
  }
}
