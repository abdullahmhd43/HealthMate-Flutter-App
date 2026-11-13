import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/streaks.dart';
import '../../health_records/models/health_record.dart';
import '../../settings/models/user_goals.dart';
import '../../wellness/models/mood_entry.dart';
import '../../wellness/models/sleep_entry.dart';
import '../../wellness/models/workout_entry.dart';
import '../models/achievement.dart';

/// Works out which badges are unlocked from the data stored in SQLite.
/// Pure and deterministic, so it is easy to unit test. Nothing is hardcoded:
/// every badge is a rule over the user's own records.
class AchievementEngine {
  AchievementEngine._();

  static AchievementSummary evaluate({
    required List<HealthRecord> records,
    required UserGoals goals,
    required int weightCount,
    required List<SleepEntry> sleep,
    required List<WorkoutEntry> workouts,
    required List<MoodEntry> moods,
    required DateTime now,
  }) {
    final dates = records.map((r) => r.date).toList();
    final currentStreak = Streaks.current(dates, today: now);
    final bestStreak = Streaks.best(dates);

    final stepGoalDays = records.where((r) => r.steps >= goals.steps).length;
    final waterGoalDays = records.where((r) => r.water >= goals.water).length;
    final totalSteps = records.fold<int>(0, (sum, r) => sum + r.steps);
    final restedNights = sleep.where((s) => s.hours >= 7).length;

    Achievement badge(
      String id,
      String title,
      String description,
      IconData icon,
      Color color,
      int current,
      int target,
    ) =>
        Achievement(
          id: id,
          title: title,
          description: description,
          icon: icon,
          color: color,
          current: current,
          target: target,
        );

    final badges = <Achievement>[
      badge('first_record', 'First step', 'Log your first health record',
          Icons.flag_rounded, AppColors.primary, records.length, 1),
      badge('streak_3', '3-day streak', 'Log your health 3 days in a row',
          Icons.local_fire_department_rounded, AppColors.calories, bestStreak, 3),
      badge('streak_7', 'Week warrior', 'Log your health 7 days in a row',
          Icons.whatshot_rounded, AppColors.calories, bestStreak, 7),
      badge('streak_30', 'Unstoppable', 'Log your health 30 days in a row',
          Icons.military_tech_rounded, AppColors.calories, bestStreak, 30),
      badge('step_goal', 'Goal getter', 'Reach your daily step goal once',
          Icons.directions_walk_rounded, AppColors.steps, stepGoalDays, 1),
      badge('step_master', 'Step master', 'Reach your step goal on 7 days',
          Icons.directions_run_rounded, AppColors.steps, stepGoalDays, 7),
      badge('walker_100k', '100K club', 'Walk 100,000 steps in total',
          Icons.emoji_events_rounded, AppColors.steps, totalSteps, 100000),
      badge('hydrated', 'Hydrated', 'Reach your daily water goal once',
          Icons.water_drop_rounded, AppColors.water, waterGoalDays, 1),
      badge('hydration_hero', 'Hydration hero',
          'Reach your water goal on 5 days', Icons.local_drink_rounded,
          AppColors.water, waterGoalDays, 5),
      badge('weigh_in', 'Weigh-in', 'Log your weight 3 times',
          Icons.monitor_weight_rounded, AppColors.secondary, weightCount, 3),
      badge('sleep_7', 'Sleep tracker', 'Log 7 nights of sleep',
          Icons.bedtime_rounded, AppColors.sleep, sleep.length, 7),
      badge('well_rested', 'Well rested', 'Sleep 7 hours or more on 3 nights',
          Icons.nights_stay_rounded, AppColors.sleep, restedNights, 3),
      badge('first_workout', 'First workout', 'Log your first workout',
          Icons.fitness_center_rounded, AppColors.workout, workouts.length, 1),
      badge('workout_10', 'Workout warrior', 'Log 10 workouts',
          Icons.sports_gymnastics_rounded, AppColors.workout, workouts.length,
          10),
      badge('mood_7', 'Mindful', 'Log your mood 7 times',
          Icons.mood_rounded, AppColors.mood, moods.length, 7),
    ];

    return AchievementSummary(
      badges: badges,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}
