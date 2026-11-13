import 'dart:math' as math;

import '../../../core/utils/health_level.dart';
import '../../dashboard/models/dashboard_stats.dart';
import '../../profile/models/user_profile.dart';
import '../../settings/models/user_goals.dart';

/// How the user is doing on water compared with the time of day.
enum HydrationStatus {
  /// Today's water target has been reached.
  done('Target reached'),

  /// Well ahead of where you should be at this time of day.
  ahead('Ahead of schedule'),

  /// Close to where you should be.
  onTrack('On track'),

  /// Noticeably behind: time to drink.
  behind('Behind schedule');

  const HydrationStatus(this.label);
  final String label;
}

/// Everything the "Today's Summary" screen shows, worked out from real data
/// (today's record, the user's goals and profile, and the current time).
///
/// Nothing here is hardcoded: all values come from the arguments.
class DailySummary {
  const DailySummary({
    required this.steps,
    required this.stepGoal,
    required this.distanceKm,
    required this.remainingDistanceKm,
    required this.caloriesFromSteps,
    required this.calories,
    required this.calorieGoal,
    required this.waterDrunk,
    required this.waterBase,
    required this.waterActivityBonus,
    required this.hoursLeft,
    required this.expectedWaterByNow,
    required this.hasRecord,
  });

  /// Steps walked today.
  final int steps;
  final int stepGoal;

  /// Estimated distance walked today, from steps and the user's height.
  final double distanceKm;

  /// Estimated distance still to walk to reach the step goal.
  final double remainingDistanceKm;

  /// Estimated calories for the steps walked (profile weight and height).
  final int caloriesFromSteps;

  /// Calories burned today, as saved in today's record.
  final int calories;
  final int calorieGoal;

  /// Water drunk today in ml.
  final int waterDrunk;

  /// The user's daily water goal in ml.
  final int waterBase;

  /// Extra water for the activity done today in ml.
  final int waterActivityBonus;

  /// Hours of the drinking day (7:00 to 22:00) still left, 0 when over.
  final double hoursLeft;

  /// How much water should have been drunk by now to be on schedule.
  final int expectedWaterByNow;

  /// False when nothing has been logged for today yet.
  final bool hasRecord;

  // ---- Drinking day -------------------------------------------------------

  /// The drinking day starts at this hour...
  static const int dayStartHour = 7;

  /// ...and ends at this hour.
  static const int dayEndHour = 22;

  /// One glass in ml, used to say "about N glasses".
  static const int glassMl = 250;

  /// Extra water per calorie burned (ml), capped by [maxActivityBonusMl].
  static const double waterPerCalorie = 0.5;
  static const int maxActivityBonusMl = 1000;

  // ---- Steps ---------------------------------------------------------------

  int get stepsRemaining => math.max(0, stepGoal - steps);
  double get stepProgress => UserGoals.progress(steps, stepGoal);
  HealthLevel get stepLevel => HealthLevel.of(steps, stepGoal);

  /// Calories still to burn to reach the calorie goal.
  int get caloriesRemaining => math.max(0, calorieGoal - calories);
  double get calorieProgress => UserGoals.progress(calories, calorieGoal);
  HealthLevel get calorieLevel => HealthLevel.of(calories, calorieGoal);

  // ---- Water ---------------------------------------------------------------

  /// Today's personal water target: the goal plus the activity bonus.
  int get waterTarget => waterBase + waterActivityBonus;

  int get waterRemaining => math.max(0, waterTarget - waterDrunk);
  double get waterProgress => UserGoals.progress(waterDrunk, waterTarget);
  HealthLevel get waterLevel => HealthLevel.of(waterDrunk, waterTarget);

  /// Whole glasses (250 ml) still to drink, rounded up.
  int get glassesRemaining => (waterRemaining / glassMl).ceil();

  /// ml per hour to drink for the rest of the day to reach the target, or null
  /// when the target is reached or less than an hour is left.
  int? get waterPerHourLeft {
    if (waterRemaining == 0 || hoursLeft < 1) return null;
    return ((waterRemaining / hoursLeft) / 10).ceil() * 10;
  }

  HydrationStatus get hydrationStatus {
    if (waterRemaining == 0) return HydrationStatus.done;
    final diff = waterDrunk - expectedWaterByNow;
    if (diff >= glassMl) return HydrationStatus.ahead;
    if (diff > -glassMl) return HydrationStatus.onTrack;
    return HydrationStatus.behind;
  }

  /// ml short of the schedule (0 when on schedule or ahead).
  int get waterBehindBy => math.max(0, expectedWaterByNow - waterDrunk);

  // ---- Build ---------------------------------------------------------------

  /// Strides are about 0.415 x height; used when the profile has no height.
  static const double defaultHeightCm = 170;

  factory DailySummary.compute({
    required DaySummary today,
    required UserGoals goals,
    required UserProfile profile,
    required DateTime now,
  }) {
    final heightCm = profile.heightCm ?? defaultHeightCm;
    final strideMetres = heightCm * 0.415 / 100;
    final kcalPerStep = profile.kcalPerStep;

    final bonus = ((today.calories * waterPerCalorie) / 50).round() * 50;
    final activityBonus = bonus.clamp(0, maxActivityBonusMl).toInt();
    final target = goals.water + activityBonus;

    final hourNow = now.hour + now.minute / 60.0;
    final dayLength = (dayEndHour - dayStartHour).toDouble();
    final elapsed = ((hourNow - dayStartHour) / dayLength).clamp(0.0, 1.0);
    final hoursLeft = (dayEndHour - math.max(hourNow, dayStartHour.toDouble()))
        .clamp(0.0, dayLength)
        .toDouble();

    return DailySummary(
      steps: today.steps,
      stepGoal: goals.steps,
      distanceKm: today.steps * strideMetres / 1000,
      remainingDistanceKm:
          math.max(0, goals.steps - today.steps) * strideMetres / 1000,
      caloriesFromSteps: (today.steps * kcalPerStep).round(),
      calories: today.calories,
      calorieGoal: goals.calories,
      waterDrunk: today.water,
      waterBase: goals.water,
      waterActivityBonus: activityBonus,
      hoursLeft: hoursLeft,
      expectedWaterByNow: (target * elapsed.toDouble()).round(),
      hasRecord: today.hasRecord,
    );
  }
}

/// Averages over the days of the week that have a record.
class WeekAverages {
  const WeekAverages({
    required this.steps,
    required this.calories,
    required this.water,
    required this.daysLogged,
  });

  final double steps;
  final double calories;
  final double water;
  final int daysLogged;

  bool get hasData => daysLogged > 0;

  /// Averages over the days in [week] that have a record (days without a
  /// record are skipped, not counted as zero).
  factory WeekAverages.from(List<DaySummary> week) {
    final logged = week.where((d) => d.hasRecord).toList();
    if (logged.isEmpty) {
      return const WeekAverages(steps: 0, calories: 0, water: 0, daysLogged: 0);
    }
    double avg(int Function(DaySummary d) pick) =>
        logged.fold<int>(0, (sum, d) => sum + pick(d)) / logged.length;
    return WeekAverages(
      steps: avg((d) => d.steps),
      calories: avg((d) => d.calories),
      water: avg((d) => d.water),
      daysLogged: logged.length,
    );
  }
}
