import '../../../core/utils/date_helper.dart';
import '../../health_records/models/health_record.dart';

/// Totals for one calendar day (zeros when no record exists).
class DaySummary {
  const DaySummary({
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
    required this.hasRecord,
  });

  final DateTime date;
  final int steps;
  final int calories;
  final int water;
  final bool hasRecord;
}

/// Totals for a span of days, such as a month.
class PeriodTotals {
  const PeriodTotals({
    required this.steps,
    required this.calories,
    required this.water,
    required this.daysRecorded,
  });

  final int steps;
  final int calories;
  final int water;
  final int daysRecorded;
}

/// Everything the dashboard and analytics screens show, derived purely from
/// the list of records so it is easy to test. Nothing here is hardcoded.
class DashboardStats {
  const DashboardStats({
    required this.today,
    required this.weekly,
    required this.month,
    required this.recent,
    required this.totalRecords,
    required this.averageSteps,
    required this.averageWater,
    required this.totalCalories,
    required this.bestDay,
  });

  /// Summary for today (zeros if today has no record).
  final DaySummary today;

  /// The last seven days ending today, oldest first.
  final List<DaySummary> weekly;

  /// Totals for the current month.
  final PeriodTotals month;

  /// The most recent records, newest first.
  final List<HealthRecord> recent;

  final int totalRecords;

  /// Average per day that has that value (0 when there is none).
  final double averageSteps;
  final double averageWater;
  final int totalCalories;

  /// The record with the most steps, or null when there are no records.
  final HealthRecord? bestDay;

  bool get hasRecords => totalRecords > 0;

  factory DashboardStats.compute(
    List<HealthRecord> records, {
    required DateTime now,
    int recentCount = 5,
  }) {
    final today = DateHelper.dateOnly(now);
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));

    final weekly = [
      for (var i = 6; i >= 0; i--)
        daySummary(records, DateTime(today.year, today.month, today.day - i)),
    ];

    var totalSteps = 0;
    var totalWater = 0;
    var totalCalories = 0;
    var stepDays = 0;
    var waterDays = 0;
    HealthRecord? best;
    for (final r in records) {
      totalSteps += r.steps;
      totalWater += r.water;
      totalCalories += r.calories;
      // A water-only (or steps-only) record, such as one created by the water
      // quick-add buttons, must not drag the other average down with a zero.
      if (r.steps > 0) stepDays++;
      if (r.water > 0) waterDays++;
      if (best == null || r.steps > best.steps) best = r;
    }
    final n = records.length;

    return DashboardStats(
      today: daySummary(records, today),
      weekly: weekly,
      month: totalsForMonth(records, today),
      recent: sorted.take(recentCount).toList(),
      totalRecords: n,
      averageSteps: stepDays == 0 ? 0 : totalSteps / stepDays,
      averageWater: waterDays == 0 ? 0 : totalWater / waterDays,
      totalCalories: totalCalories,
      bestDay: best,
    );
  }

  /// The summary for [day], with zeros when there is no record.
  static DaySummary daySummary(List<HealthRecord> records, DateTime day) {
    final iso = DateHelper.toIso(day);
    for (final r in records) {
      if (r.date == iso) {
        return DaySummary(
          date: DateHelper.dateOnly(day),
          steps: r.steps,
          calories: r.calories,
          water: r.water,
          hasRecord: true,
        );
      }
    }
    return DaySummary(
      date: DateHelper.dateOnly(day),
      steps: 0,
      calories: 0,
      water: 0,
      hasRecord: false,
    );
  }

  /// Totals for the calendar month containing [month].
  static PeriodTotals totalsForMonth(
      List<HealthRecord> records, DateTime month) {
    var steps = 0, calories = 0, water = 0, days = 0;
    for (final r in records) {
      final d = r.dateTime;
      if (d.year == month.year && d.month == month.month) {
        steps += r.steps;
        calories += r.calories;
        water += r.water;
        days++;
      }
    }
    return PeriodTotals(
        steps: steps, calories: calories, water: water, daysRecorded: days);
  }
}
