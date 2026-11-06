import '../../../core/constants/app_constants.dart';

/// The user's daily targets. These are goals, not recorded values.
class UserGoals {
  const UserGoals({
    this.steps = AppConstants.defaultStepGoal,
    this.water = AppConstants.defaultWaterGoal,
    this.calories = AppConstants.defaultCalorieGoal,
  });

  final int steps;
  final int water;
  final int calories;

  UserGoals copyWith({int? steps, int? water, int? calories}) => UserGoals(
        steps: steps ?? this.steps,
        water: water ?? this.water,
        calories: calories ?? this.calories,
      );

  /// Fraction of [goal] reached by [value] (0.0 for a missing goal). May
  /// exceed 1.0 when the goal is beaten.
  static double progress(num value, int goal) =>
      goal <= 0 ? 0 : value / goal;
}
