import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/dashboard/models/dashboard_stats.dart';
import 'package:healthmate/features/settings/models/user_goals.dart';

import 'test_helpers.dart';

void main() {
  final now = DateTime(2026, 11, 6, 9);

  group('empty database', () {
    final stats = DashboardStats.compute(const [], now: now);

    test('has zero totals and no best day', () {
      expect(stats.hasRecords, isFalse);
      expect(stats.today.hasRecord, isFalse);
      expect(stats.today.steps, 0);
      expect(stats.averageSteps, 0);
      expect(stats.averageWater, 0);
      expect(stats.totalCalories, 0);
      expect(stats.bestDay, isNull);
      expect(stats.recent, isEmpty);
      expect(stats.month.daysRecorded, 0);
    });

    test('weekly chart still has seven empty days', () {
      expect(stats.weekly, hasLength(7));
      expect(stats.weekly.every((d) => !d.hasRecord && d.steps == 0), isTrue);
    });
  });

  group('with records', () {
    final records = [
      record('2026-11-06', steps: 8000, calories: 400, water: 2000),
      record('2026-11-05', steps: 12000, calories: 600, water: 3000),
      record('2026-11-02', steps: 4000, calories: 200, water: 1000),
      record('2026-10-31', steps: 6000, calories: 300, water: 1500),
      record('2026-10-01', steps: 2000, calories: 100, water: 500),
    ];
    final stats = DashboardStats.compute(records, now: now);

    test('today comes from the record for today', () {
      expect(stats.today.hasRecord, isTrue);
      expect(stats.today.steps, 8000);
      expect(stats.today.calories, 400);
      expect(stats.today.water, 2000);
    });

    test('today is zero when there is no record for today', () {
      final s = DashboardStats.compute(records, now: DateTime(2026, 11, 7));
      expect(s.today.hasRecord, isFalse);
      expect(s.today.steps, 0);
    });

    test('weekly covers the last 7 days oldest first', () {
      expect(stats.weekly.first.date, DateTime(2026, 10, 31));
      expect(stats.weekly.last.date, DateTime(2026, 11, 6));
      expect(stats.weekly.map((d) => d.steps).toList(),
          [6000, 0, 4000, 0, 0, 12000, 8000]);
    });

    test('monthly totals only include the current month', () {
      expect(stats.month.steps, 24000);
      expect(stats.month.calories, 1200);
      expect(stats.month.water, 6000);
      expect(stats.month.daysRecorded, 3);
    });

    test('totalsForMonth works for another month', () {
      final october =
          DashboardStats.totalsForMonth(records, DateTime(2026, 10));
      expect(october.steps, 8000);
      expect(october.daysRecorded, 2);
    });

    test('averages are per recorded day', () {
      expect(stats.averageSteps, 32000 / 5);
      expect(stats.averageWater, 8000 / 5);
    });

    test('total calories sums every record', () {
      expect(stats.totalCalories, 1600);
    });

    test('best activity day is the record with most steps', () {
      expect(stats.bestDay!.date, '2026-11-05');
      expect(stats.bestDay!.steps, 12000);
    });

    test('recent records are newest first and limited', () {
      final limited =
          DashboardStats.compute(records, now: now, recentCount: 2);
      expect(limited.recent.map((r) => r.date), ['2026-11-06', '2026-11-05']);
    });
  });

  group('goal progress', () {
    test('is value divided by goal and can exceed 100%', () {
      expect(UserGoals.progress(5000, 10000), 0.5);
      expect(UserGoals.progress(15000, 10000), 1.5);
    });

    test('is zero for a missing goal', () {
      expect(UserGoals.progress(100, 0), 0);
    });
  });
}
