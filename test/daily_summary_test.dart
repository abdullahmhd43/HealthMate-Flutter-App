import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/health_level.dart';
import 'package:healthmate/features/dashboard/models/dashboard_stats.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/settings/models/user_goals.dart';
import 'package:healthmate/features/summary/models/daily_summary.dart';

DaySummary day({
  int steps = 0,
  int calories = 0,
  int water = 0,
  bool hasRecord = true,
  DateTime? date,
}) =>
    DaySummary(
      date: date ?? DateTime(2026, 11, 14),
      steps: steps,
      calories: calories,
      water: water,
      hasRecord: hasRecord,
    );

void main() {
  const goals = UserGoals(steps: 10000, water: 2500, calories: 500);
  const noProfile = UserProfile();

  // 15:00 -> 8 of the 15 drinking hours (07:00-22:00) have passed.
  final threePm = DateTime(2026, 11, 14, 15);

  DailySummary summary(
    DaySummary today, {
    UserProfile profile = noProfile,
    DateTime? now,
    UserGoals g = goals,
  }) =>
      DailySummary.compute(
        today: today,
        goals: g,
        profile: profile,
        now: now ?? threePm,
      );

  group('steps', () {
    test('progress, remaining and level', () {
      final s = summary(day(steps: 7000));
      expect(s.steps, 7000);
      expect(s.stepGoal, 10000);
      expect(s.stepsRemaining, 3000);
      expect(s.stepProgress, closeTo(0.7, 1e-9));
      expect(s.stepLevel, HealthLevel.moderate);
    });

    test('goal reached means nothing remaining and Excellent', () {
      final s = summary(day(steps: 12000));
      expect(s.stepsRemaining, 0);
      expect(s.stepLevel, HealthLevel.excellent);
    });

    test('distance uses a default height without a profile', () {
      final s = summary(day(steps: 7000));
      // stride = 170 cm x 0.415 = 0.7055 m
      expect(s.distanceKm, closeTo(7000 * 0.7055 / 1000, 1e-9));
      expect(s.remainingDistanceKm, closeTo(3000 * 0.7055 / 1000, 1e-9));
    });

    test('distance grows with the profile height', () {
      const tall = UserProfile(heightCm: 190, weightKg: 80);
      final s = summary(day(steps: 10000), profile: tall);
      expect(s.distanceKm, closeTo(10000 * (190 * 0.415 / 100) / 1000, 1e-9));
      expect(s.distanceKm, greaterThan(summary(day(steps: 10000)).distanceKm));
    });

    test('no steps means zero distance', () {
      final s = summary(day());
      expect(s.distanceKm, 0);
      expect(s.stepLevel, HealthLevel.low);
    });
  });

  group('calories', () {
    test('remaining and level against the goal', () {
      final s = summary(day(calories: 280));
      expect(s.calories, 280);
      expect(s.caloriesRemaining, 220);
      expect(s.calorieProgress, closeTo(0.56, 1e-9));
      expect(s.calorieLevel, HealthLevel.moderate);
    });

    test('goal reached', () {
      final s = summary(day(calories: 650));
      expect(s.caloriesRemaining, 0);
      expect(s.calorieLevel, HealthLevel.excellent);
    });

    test('calories from steps use the default rate without a profile', () {
      expect(summary(day(steps: 7000)).caloriesFromSteps, 280);
    });

    test('calories from steps use weight and height from the profile', () {
      const profile = UserProfile(heightCm: 180, weightKg: 80);
      // 0.75 x 80 x (180 x 0.415 / 100) / 1000 = 0.04482 kcal per step
      expect(summary(day(steps: 10000), profile: profile).caloriesFromSteps,
          448);
    });
  });

  group('water target', () {
    test('is the goal when nothing was burned', () {
      final s = summary(day(water: 500));
      expect(s.waterBase, 2500);
      expect(s.waterActivityBonus, 0);
      expect(s.waterTarget, 2500);
    });

    test('adds 0.5 ml per calorie burned, rounded to 50 ml', () {
      // 280 kcal x 0.5 = 140 ml -> 150 ml
      final s = summary(day(calories: 280));
      expect(s.waterActivityBonus, 150);
      expect(s.waterTarget, 2650);
    });

    test('the activity bonus is capped at 1,000 ml', () {
      final s = summary(day(calories: 5000));
      expect(s.waterActivityBonus, 1000);
      expect(s.waterTarget, 3500);
    });

    test('remaining, glasses and progress', () {
      final s = summary(day(calories: 280, water: 1000));
      expect(s.waterDrunk, 1000);
      expect(s.waterRemaining, 1650);
      expect(s.glassesRemaining, 7); // 1650 / 250 = 6.6 -> 7
      expect(s.waterProgress, closeTo(1000 / 2650, 1e-9));
      expect(s.waterLevel, HealthLevel.low);
    });

    test('nothing remaining once the target is beaten', () {
      final s = summary(day(water: 3200));
      expect(s.waterRemaining, 0);
      expect(s.glassesRemaining, 0);
      expect(s.waterLevel, HealthLevel.excellent);
    });

    test('uses the user\'s own water goal', () {
      final s = summary(day(),
          g: const UserGoals(steps: 8000, water: 3000, calories: 400));
      expect(s.waterTarget, 3000);
      expect(s.stepGoal, 8000);
      expect(s.calorieGoal, 400);
    });
  });

  group('hydration schedule', () {
    test('behind: below the schedule by a glass or more', () {
      // target 2650, expected by 15:00 = 2650 x 8/15 = 1413, drunk 1000
      final s = summary(day(calories: 280, water: 1000));
      expect(s.expectedWaterByNow, 1413);
      expect(s.hydrationStatus, HydrationStatus.behind);
      expect(s.waterBehindBy, 413);
    });

    test('on track: within a glass of the schedule', () {
      // expected 1333 for a 2500 ml target
      final s = summary(day(water: 1200));
      expect(s.expectedWaterByNow, 1333);
      expect(s.hydrationStatus, HydrationStatus.onTrack);
    });

    test('ahead: a glass or more in front of the schedule', () {
      final s = summary(day(water: 2000));
      expect(s.hydrationStatus, HydrationStatus.ahead);
      expect(s.waterBehindBy, 0);
    });

    test('boundaries are exactly one glass (250 ml)', () {
      expect(summary(day(water: 1083)).hydrationStatus,
          HydrationStatus.behind); // -250
      expect(summary(day(water: 1084)).hydrationStatus,
          HydrationStatus.onTrack); // -249
      expect(summary(day(water: 1583)).hydrationStatus,
          HydrationStatus.ahead); // +250
    });

    test('done once the target is reached', () {
      final s = summary(day(water: 2500));
      expect(s.hydrationStatus, HydrationStatus.done);
      expect(s.waterPerHourLeft, isNull);
    });

    test('per-hour advice spreads the rest over the hours left', () {
      // 1650 ml over 7 hours (15:00 -> 22:00) = 235.7 -> 240 ml per hour
      final s = summary(day(calories: 280, water: 1000));
      expect(s.hoursLeft, closeTo(7, 1e-9));
      expect(s.waterPerHourLeft, 240);
    });

    test('before the drinking day starts', () {
      final s = summary(day(), now: DateTime(2026, 11, 14, 6));
      expect(s.expectedWaterByNow, 0);
      expect(s.hoursLeft, closeTo(15, 1e-9));
      expect(s.hydrationStatus, HydrationStatus.onTrack);
      expect(s.waterPerHourLeft, 170); // 2500 / 15 = 166.7 -> 170
    });

    test('with less than an hour left there is no per-hour figure', () {
      final s = summary(day(water: 1000), now: DateTime(2026, 11, 14, 21, 30));
      expect(s.hoursLeft, closeTo(0.5, 1e-9));
      expect(s.waterPerHourLeft, isNull);
      expect(s.waterRemaining, 1500);
    });

    test('after the drinking day ends the whole target was due', () {
      final s = summary(day(water: 1000), now: DateTime(2026, 11, 14, 22, 30));
      expect(s.hoursLeft, 0);
      expect(s.expectedWaterByNow, 2500);
      expect(s.hydrationStatus, HydrationStatus.behind);
      expect(s.waterBehindBy, 1500);
    });
  });

  group('empty day', () {
    test('has zeros and still gives a water plan', () {
      final s = summary(day(hasRecord: false));
      expect(s.hasRecord, isFalse);
      expect(s.steps, 0);
      expect(s.calories, 0);
      expect(s.waterDrunk, 0);
      expect(s.waterTarget, 2500);
      expect(s.waterRemaining, 2500);
      expect(s.glassesRemaining, 10);
    });
  });

  group('WeekAverages', () {
    test('averages only the days that have a record', () {
      final week = [
        day(steps: 6000, calories: 240, water: 2000),
        day(hasRecord: false),
        day(steps: 10000, calories: 400, water: 3000),
        day(hasRecord: false),
        day(hasRecord: false),
        day(hasRecord: false),
        day(hasRecord: false),
      ];
      final avg = WeekAverages.from(week);
      expect(avg.daysLogged, 2);
      expect(avg.steps, 8000);
      expect(avg.calories, 320);
      expect(avg.water, 2500);
      expect(avg.hasData, isTrue);
    });

    test('a week with no records has no data', () {
      final avg = WeekAverages.from([day(hasRecord: false), day(hasRecord: false)]);
      expect(avg.hasData, isFalse);
      expect(avg.daysLogged, 0);
      expect(avg.steps, 0);
    });

    test('an empty list is handled', () {
      expect(WeekAverages.from(const []).hasData, isFalse);
    });
  });
}
