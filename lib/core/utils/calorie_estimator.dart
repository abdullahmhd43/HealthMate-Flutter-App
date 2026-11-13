import '../constants/app_constants.dart';

/// Estimates calories burned from steps walked.
///
/// This is an approximation (about 0.04 kcal per step for an average adult),
/// not a medical measurement. The user can always overwrite the estimate.
class CalorieEstimator {
  CalorieEstimator._();

  /// [kcalPerStep] can come from the user's profile (weight and height);
  /// it defaults to the average value.
  static int fromSteps(int steps, {double? kcalPerStep}) => steps <= 0
      ? 0
      : (steps * (kcalPerStep ?? AppConstants.caloriesPerStep)).round();

  /// Parses typed text; returns null when it is not a valid whole number.
  static int? fromText(String text, {double? kcalPerStep}) {
    final steps = int.tryParse(text.trim());
    return steps == null || steps < 0
        ? null
        : fromSteps(steps, kcalPerStep: kcalPerStep);
  }
}
