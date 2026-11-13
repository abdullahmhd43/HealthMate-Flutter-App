import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snack.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../../health_records/screens/record_form_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/daily_summary.dart';
import '../widgets/water_glass.dart';

/// Today's steps walked, calories burned and a water plan that says how much
/// to drink. Every number comes from SQLite via the providers.
class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({super.key});

  static const List<int> waterAmounts = [150, 250, 500];

  Future<void> _addWater(BuildContext context, int ml) async {
    final records = context.read<HealthRecordsProvider>();
    final now = context.read<DashboardProvider>().now;
    final messenger = ScaffoldMessenger.of(context);
    final error = await records.addWater(ml, now: now);
    showSnack(messenger, error ?? 'Added $ml ml of water');
  }

  void _openRecord(BuildContext context, int? recordId) {
    Navigator.of(context).push(MaterialPageRoute<bool>(
      builder: (_) => RecordFormScreen(recordId: recordId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final records = context.watch<HealthRecordsProvider>();
    final theme = Theme.of(context);
    final now = dashboard.now;

    final summary = DailySummary.compute(
      today: dashboard.stats.today,
      goals: dashboard.goals,
      profile: profile,
      now: now,
    );
    final week = WeekAverages.from(dashboard.stats.weekly);
    final todayRecord = records.findByDate(DateHelper.toIso(now));

    return Scaffold(
      appBar: AppBar(title: const Text("Today's summary")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateHelper.displayLong(now),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              summary.hasRecord
                  ? 'Here is how your day is going.'
                  : 'Nothing is logged for today yet. Add steps or water to '
                      'start.',
              key: const Key('summary_subtitle'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _StepsCard(summary: summary),
            const SizedBox(height: 14),
            _CaloriesCard(summary: summary),
            const SizedBox(height: 14),
            _WaterCard(
              summary: summary,
              onAdd: (ml) => _addWater(context, ml),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'This week'),
            _WeekCard(week: week),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const Key('summary_edit_record'),
              onPressed: () => _openRecord(context, todayRecord?.id),
              icon: Icon(todayRecord == null
                  ? Icons.add_rounded
                  : Icons.edit_outlined),
              label: Text(todayRecord == null
                  ? "Add today's record"
                  : "Edit today's record"),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Steps
// -----------------------------------------------------------------------------

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = summary.stepsRemaining;
    final remainingKm = summary.remainingDistanceKm;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: summary.stepProgress,
                color: AppColors.steps,
                size: 92,
                strokeWidth: 10,
                child: const Icon(Icons.directions_walk_rounded,
                    size: 30, color: AppColors.steps),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Steps walked',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      Formatters.steps(summary.steps),
                      key: const Key('steps_value'),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${Formatters.percent(summary.stepProgress)} of '
                      '${Formatters.steps(summary.stepGoal)} goal',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    LevelChip(level: summary.stepLevel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.route_rounded,
                  label: 'Distance walked',
                  value: '${summary.distanceKm.toStringAsFixed(2)} km',
                  valueKey: const Key('distance_value'),
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.flag_rounded,
                  label: remaining == 0 ? 'Goal' : 'To reach goal',
                  value: remaining == 0
                      ? 'Reached 🎉'
                      : '${Formatters.steps(remaining)} steps '
                          '(${remainingKm.toStringAsFixed(1)} km)',
                  valueKey: const Key('steps_remaining_value'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Calories
// -----------------------------------------------------------------------------

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = summary.calorieProgress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.calories.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.calories),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories burned',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      Formatters.calories(summary.calories),
                      key: const Key('calories_value'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              LevelChip(level: summary.calorieLevel),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
              color: AppColors.calories,
              backgroundColor: AppColors.calories.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.caloriesRemaining == 0
                ? 'You have reached your '
                    '${Formatters.calories(summary.calorieGoal)} goal.'
                : '${Formatters.calories(summary.caloriesRemaining)} to go '
                    'to reach your ${Formatters.calories(summary.calorieGoal)} '
                    'goal.',
            key: const Key('calories_remaining_text'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Your steps alone are worth about '
            '${Formatters.calories(summary.caloriesFromSteps)} '
            '(an estimate from your weight and height).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Water
// -----------------------------------------------------------------------------

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.summary, required this.onAdd});

  final DailySummary summary;
  final void Function(int ml) onAdd;

  Color _statusColor(HydrationStatus status) => switch (status) {
        HydrationStatus.done => const Color(0xFF00897B),
        HydrationStatus.ahead => const Color(0xFF43A047),
        HydrationStatus.onTrack => AppColors.water,
        HydrationStatus.behind => const Color(0xFFF59E0B),
      };

  String _advice() {
    final remaining = summary.waterRemaining;
    switch (summary.hydrationStatus) {
      case HydrationStatus.done:
        return 'Great job! You have reached today\'s water target. Keep '
            'sipping if you are active or it is hot.';
      case HydrationStatus.ahead:
      case HydrationStatus.onTrack:
      case HydrationStatus.behind:
        final perHour = summary.waterPerHourLeft;
        final behind = summary.waterBehindBy;
        final pace = perHour == null
            ? 'Try to finish the ${Formatters.water(remaining)} before bed.'
            : 'Drink about ${Formatters.water(perHour)} every hour until '
                '${DailySummary.dayEndHour}:00 to reach your target.';
        if (summary.hydrationStatus == HydrationStatus.behind) {
          return 'You are ${Formatters.water(behind)} behind where you '
              'should be by now. $pace';
        }
        return pace;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = summary.hydrationStatus;
    final color = _statusColor(status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.water),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Water plan',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Container(
                key: const Key('water_status_chip'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaterGlass(progress: summary.waterProgress),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WaterLine(
                      label: 'Drunk so far',
                      value: Formatters.water(summary.waterDrunk),
                      valueKey: const Key('water_drunk_value'),
                    ),
                    const SizedBox(height: 10),
                    _WaterLine(
                      label: "Today's target",
                      value: Formatters.water(summary.waterTarget),
                      valueKey: const Key('water_target_value'),
                    ),
                    const SizedBox(height: 10),
                    _WaterLine(
                      label: 'Still to drink',
                      value: Formatters.water(summary.waterRemaining),
                      valueKey: const Key('water_remaining_value'),
                      emphasised: true,
                    ),
                    if (summary.waterRemaining > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'about ${summary.glassesRemaining} '
                        '${summary.glassesRemaining == 1 ? 'glass' : 'glasses'} '
                        '(${DailySummary.glassMl} ml)',
                        key: const Key('water_glasses_text'),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _advice(),
              key: const Key('water_advice'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary.waterActivityBonus > 0
                ? 'Target = your goal ${Formatters.water(summary.waterBase)} '
                    '+ ${Formatters.water(summary.waterActivityBonus)} for '
                    'today\'s activity.'
                : 'Target = your daily goal. It goes up when you burn more '
                    'calories.',
            key: const Key('water_breakdown'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final ml in DailySummaryScreen.waterAmounts) ...[
                Expanded(
                  child: FilledButton.tonal(
                    key: Key('summary_add_water_$ml'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => onAdd(ml),
                    child: Text('+$ml ml'),
                  ),
                ),
                if (ml != DailySummaryScreen.waterAmounts.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterLine extends StatelessWidget {
  const _WaterLine({
    required this.label,
    required this.value,
    required this.valueKey,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
          value,
          key: valueKey,
          style: (emphasised
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasised ? AppColors.water : null,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Week
// -----------------------------------------------------------------------------

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final WeekAverages week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!week.hasData) {
      return AppCard(
        child: Text(
          'No records in the last 7 days yet. Your weekly averages will '
          'appear here.',
          key: const Key('week_empty'),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily average over ${week.daysLogged} logged '
            '${week.daysLogged == 1 ? 'day' : 'days'}',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.directions_walk_rounded,
                  iconColor: AppColors.steps,
                  label: 'Steps',
                  value: Formatters.steps(week.steps),
                  valueKey: const Key('week_steps_value'),
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.calories,
                  label: 'Calories',
                  value: Formatters.calories(week.calories),
                  valueKey: const Key('week_calories_value'),
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.water,
                  label: 'Water',
                  value: Formatters.water(week.water),
                  valueKey: const Key('week_water_value'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueKey,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
          value,
          key: valueKey,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
