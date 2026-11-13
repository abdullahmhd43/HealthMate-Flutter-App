import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/achievements/models/achievement.dart';
import 'package:healthmate/features/achievements/services/achievement_engine.dart';
import 'package:healthmate/features/health_records/models/health_record.dart';
import 'package:healthmate/features/settings/models/user_goals.dart';
import 'package:healthmate/features/wellness/models/mood_entry.dart';
import 'package:healthmate/features/wellness/models/sleep_entry.dart';
import 'package:healthmate/features/wellness/models/workout_entry.dart';

Achievement byId(AchievementSummary s, String id) =>
    s.badges.firstWhere((b) => b.id == id);

void main() {
  final now = DateTime(2026, 11, 10);
  const goals = UserGoals(steps: 10000, water: 2500, calories: 500);

  test('nothing is unlocked with no data', () {
    final summary = AchievementEngine.evaluate(
      records: const [],
      goals: goals,
      weightCount: 0,
      sleep: const [],
      workouts: const [],
      moods: const [],
      now: now,
    );
    expect(summary.unlockedCount, 0);
    expect(summary.currentStreak, 0);
    expect(summary.bestStreak, 0);
    expect(summary.total, greaterThan(10));
  });

  test('a 7 day streak that beats the goals unlocks the matching badges', () {
    final records = [
      for (var d = 4; d <= 10; d++)
        HealthRecord(
          date: '2026-11-${d.toString().padLeft(2, '0')}',
          steps: 12000,
          calories: 400,
          water: 3000,
        ),
    ];
    final summary = AchievementEngine.evaluate(
      records: records,
      goals: goals,
      weightCount: 3,
      sleep: const [],
      workouts: const [],
      moods: const [],
      now: now,
    );

    expect(summary.currentStreak, 7);
    expect(byId(summary, 'first_record').unlocked, isTrue);
    expect(byId(summary, 'streak_3').unlocked, isTrue);
    expect(byId(summary, 'streak_7').unlocked, isTrue);
    expect(byId(summary, 'streak_30').unlocked, isFalse);
    expect(byId(summary, 'step_master').unlocked, isTrue);
    expect(byId(summary, 'hydration_hero').unlocked, isTrue);
    expect(byId(summary, 'weigh_in').unlocked, isTrue);

    // 7 x 12,000 = 84,000 steps: not yet 100K, so it shows progress.
    final club = byId(summary, 'walker_100k');
    expect(club.unlocked, isFalse);
    expect(club.progress, closeTo(0.84, 0.001));
    expect(club.shownCurrent, 84000);
  });

  test('wellness badges follow sleep, workout and mood logs', () {
    final summary = AchievementEngine.evaluate(
      records: const [],
      goals: goals,
      weightCount: 0,
      sleep: [
        for (var d = 1; d <= 7; d++)
          SleepEntry(
            date: '2026-11-${d.toString().padLeft(2, '0')}',
            hours: d <= 3 ? 8 : 5,
            quality: 3,
          ),
      ],
      workouts: const [
        WorkoutEntry(date: '2026-11-01', type: 'Running', minutes: 30),
      ],
      moods: const [MoodEntry(date: '2026-11-01', mood: 4)],
      now: now,
    );

    expect(byId(summary, 'sleep_7').unlocked, isTrue);
    expect(byId(summary, 'well_rested').unlocked, isTrue); // 3 nights >= 7 h
    expect(byId(summary, 'first_workout').unlocked, isTrue);
    expect(byId(summary, 'workout_10').unlocked, isFalse);
    expect(byId(summary, 'mood_7').unlocked, isFalse);
    expect(byId(summary, 'mood_7').progress, closeTo(1 / 7, 0.001));
  });
}
