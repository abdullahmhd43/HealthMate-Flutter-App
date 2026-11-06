import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/shell_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../analytics/widgets/weekly_bar_chart.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../../health_records/screens/record_detail_screen.dart';
import '../../health_records/screens/record_form_screen.dart';
import '../../health_records/widgets/record_tile.dart';
import '../../settings/models/user_goals.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/metric_card.dart';

/// Home tab: today's summary, weekly chart and recent records.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openAdd(BuildContext context, {int? editId}) {
    Navigator.of(context).push(MaterialPageRoute<bool>(
      builder: (_) => RecordFormScreen(recordId: editId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<HealthRecordsProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final theme = Theme.of(context);
    final stats = dashboard.stats;
    final goals = dashboard.goals;
    final now = dashboard.now;

    if (records.isLoading && !records.isInitialised) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.error != null && !stats.hasRecords) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: records.error!,
        actionLabel: 'Try again',
        onAction: records.refresh,
      );
    }

    final todayRecord = records.findByDate(DateHelper.toIso(now));

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: records.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Text(
              '${DateHelper.greeting(now)} 👋',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              DateHelper.displayLong(now),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (!stats.hasRecords)
              SizedBox(
                height: 420,
                child: EmptyState(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Start tracking your health',
                  message:
                      'You have no records yet. Add your steps, calories and '
                      'water to see your daily summary here.',
                  actionLabel: 'Add first record',
                  onAction: () => _openAdd(context),
                ),
              )
            else ...[
              _TodayHeader(
                hasToday: todayRecord != null,
                onAction: () => _openAdd(context, editId: todayRecord?.id),
              ),
              const SizedBox(height: 14),
              MetricCard(
                icon: Icons.directions_walk_rounded,
                color: AppColors.steps,
                label: 'Steps',
                value: Formatters.steps(stats.today.steps),
                unit: 'steps',
                progress: UserGoals.progress(stats.today.steps, goals.steps),
                goalText: 'Goal ${Formatters.steps(goals.steps)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.calories,
                      label: 'Calories burned',
                      value: Formatters.integer(stats.today.calories),
                      unit: 'kcal',
                      progress: UserGoals.progress(
                          stats.today.calories, goals.calories),
                      goalText: 'Goal ${Formatters.integer(goals.calories)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.water_drop_rounded,
                      color: AppColors.water,
                      label: 'Water intake',
                      value: Formatters.integer(stats.today.water),
                      unit: 'ml',
                      progress:
                          UserGoals.progress(stats.today.water, goals.water),
                      goalText: 'Goal ${Formatters.integer(goals.water)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Weekly activity'),
              AppCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'Steps · last 7 days',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    WeeklyBarChart(
                      days: stats.weekly,
                      valueOf: (d) => d.steps,
                      color: AppColors.steps,
                      unit: 'steps',
                      goal: goals.steps,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Recent records',
                actionLabel: 'See all',
                onAction: () => context.read<ShellController>().goTo(1),
              ),
              for (final record in stats.recent) ...[
                RecordTile(
                  record: record,
                  isSample: records.isSample(record),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecordDetailScreen(recordId: record.id!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.hasToday, required this.onAction});

  final bool hasToday;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S ACTIVITY",
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (!hasToday)
                Text(
                  'Nothing logged for today yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          key: const Key('quick_add_button'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: onAction,
          icon: Icon(hasToday ? Icons.edit_rounded : Icons.add_rounded,
              size: 18),
          label: Text(hasToday ? 'Edit today' : 'Add today'),
        ),
      ],
    );
  }
}
