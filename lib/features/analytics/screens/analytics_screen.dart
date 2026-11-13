import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/health_level.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/models/dashboard_stats.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../../health_records/screens/record_form_screen.dart';
import '../../settings/models/user_goals.dart';
import '../widgets/weekly_bar_chart.dart';

enum _Metric { steps, water, calories }

/// Analytics tab: daily, weekly and monthly summaries plus overall statistics.
/// Every number is derived from the records stored in SQLite.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Metric _metric = _Metric.steps;
  DateTime? _selectedDay;
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<HealthRecordsProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final stats = dashboard.stats;
    final goals = dashboard.goals;
    final today = DateHelper.dateOnly(dashboard.now);
    final day = _selectedDay ?? today;
    final month = _selectedMonth ?? DateTime(today.year, today.month);

    if (!stats.hasRecords) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: EmptyState(
          icon: Icons.insights_rounded,
          title: 'No data to analyse',
          message: 'Add a few daily records and your trends will appear here.',
          actionLabel: 'Add record',
          onAction: () => Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (_) => const RecordFormScreen(),
          )),
        ),
      );
    }

    final daySummary = DashboardStats.daySummary(records.allRecords, day);
    final monthTotals =
        DashboardStats.totalsForMonth(records.allRecords, month);
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          // ---- Daily summary ----
          const SectionHeader(title: 'Daily summary'),
          AppCard(
            child: Column(
              children: [
                _Navigator(
                  label: DateHelper.isSameDay(day, today)
                      ? 'Today'
                      : DateHelper.display(day),
                  onPrevious: day.isAfter(AppConstants.earliestDate)
                      ? () => setState(() => _selectedDay =
                          DateTime(day.year, day.month, day.day - 1))
                      : null,
                  onNext: day.isBefore(today)
                      ? () => setState(() => _selectedDay =
                          DateTime(day.year, day.month, day.day + 1))
                      : null,
                ),
                const SizedBox(height: 12),
                if (!daySummary.hasRecord)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No record for this day.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  Row(
                    children: [
                      _GoalRing(
                        color: AppColors.steps,
                        icon: Icons.directions_walk_rounded,
                        value: Formatters.steps(daySummary.steps),
                        label: 'Steps',
                        progress:
                            UserGoals.progress(daySummary.steps, goals.steps),
                        level: HealthLevel.of(daySummary.steps, goals.steps),
                      ),
                      _GoalRing(
                        color: AppColors.calories,
                        icon: Icons.local_fire_department_rounded,
                        value: Formatters.integer(daySummary.calories),
                        label: 'kcal',
                        progress: UserGoals.progress(
                            daySummary.calories, goals.calories),
                        level: HealthLevel.of(
                            daySummary.calories, goals.calories),
                      ),
                      _GoalRing(
                        color: AppColors.water,
                        icon: Icons.water_drop_rounded,
                        value: Formatters.integer(daySummary.water),
                        label: 'ml water',
                        progress:
                            UserGoals.progress(daySummary.water, goals.water),
                        level: HealthLevel.of(daySummary.water, goals.water),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Weekly summary ----
          const SectionHeader(title: 'Weekly summary'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SegmentedButton<_Metric>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: _Metric.steps,
                          label: Text('Steps'),
                          icon: Icon(Icons.directions_walk_rounded)),
                      ButtonSegment(
                          value: _Metric.water,
                          label: Text('Water'),
                          icon: Icon(Icons.water_drop_rounded)),
                      ButtonSegment(
                          value: _Metric.calories,
                          label: Text('Calories'),
                          icon: Icon(Icons.local_fire_department_rounded)),
                    ],
                    selected: {_metric},
                    onSelectionChanged: (s) =>
                        setState(() => _metric = s.first),
                  ),
                ),
                const SizedBox(height: 20),
                WeeklyBarChart(
                  days: stats.weekly,
                  valueOf: _valueOf,
                  color: _colorOf,
                  unit: _unitOf,
                  goal: _goalOf(goals),
                  height: 210,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Dashed line = your daily goal. '
                    'Week total: ${Formatters.integer(stats.weekly.fold<int>(0, (s, d) => s + _valueOf(d)))} $_unitOf',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Monthly summary ----
          const SectionHeader(title: 'Monthly summary'),
          AppCard(
            child: Column(
              children: [
                _Navigator(
                  label: DateHelper.monthYear(month),
                  onPrevious: () => setState(
                      () => _selectedMonth = DateTime(month.year, month.month - 1)),
                  onNext: isCurrentMonth
                      ? null
                      : () => setState(() => _selectedMonth =
                          DateTime(month.year, month.month + 1)),
                ),
                const SizedBox(height: 12),
                _TotalRow(
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.steps,
                  label: 'Total steps',
                  value: Formatters.steps(monthTotals.steps),
                ),
                _TotalRow(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.calories,
                  label: 'Total calories',
                  value: Formatters.calories(monthTotals.calories),
                ),
                _TotalRow(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.water,
                  label: 'Total water',
                  value: Formatters.water(monthTotals.water),
                ),
                _TotalRow(
                  icon: Icons.event_available_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Days recorded',
                  value: '${monthTotals.daysRecorded}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Health statistics ----
          const SectionHeader(title: 'Health statistics'),
          AppCard(
            child: Column(
              children: [
                _TotalRow(
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.steps,
                  label: 'Average daily steps',
                  value: Formatters.steps(stats.averageSteps),
                ),
                _TotalRow(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.water,
                  label: 'Average water intake',
                  value: Formatters.water(stats.averageWater),
                ),
                _TotalRow(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.calories,
                  label: 'Total calories burned',
                  value: Formatters.calories(stats.totalCalories),
                ),
                _TotalRow(
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber.shade700,
                  label: 'Best activity day',
                  value: stats.bestDay == null
                      ? '—'
                      : '${DateHelper.shortDay(stats.bestDay!.dateTime)} · '
                          '${Formatters.steps(stats.bestDay!.steps)} steps',
                ),
                _TotalRow(
                  icon: Icons.list_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Records stored',
                  value: '${stats.totalRecords}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _valueOf(DaySummary d) => switch (_metric) {
        _Metric.steps => d.steps,
        _Metric.water => d.water,
        _Metric.calories => d.calories,
      };

  Color get _colorOf => switch (_metric) {
        _Metric.steps => AppColors.steps,
        _Metric.water => AppColors.water,
        _Metric.calories => AppColors.calories,
      };

  String get _unitOf => switch (_metric) {
        _Metric.steps => 'steps',
        _Metric.water => 'ml',
        _Metric.calories => 'kcal',
      };

  int _goalOf(UserGoals goals) => switch (_metric) {
        _Metric.steps => goals.steps,
        _Metric.water => goals.water,
        _Metric.calories => goals.calories,
      };
}

class _Navigator extends StatelessWidget {
  const _Navigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Next',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
    required this.progress,
    required this.level,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;
  final double progress;
  final HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          ProgressRing(
            progress: progress,
            color: color,
            size: 76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                Text(
                  Formatters.percent(progress),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          LevelChip(level: level, compact: true),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
