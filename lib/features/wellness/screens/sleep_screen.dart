import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/snack.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../models/sleep_entry.dart';
import '../providers/wellness_provider.dart';
import '../widgets/day_bar_chart.dart';
import '../widgets/log_tile.dart';
import '../widgets/wellness_dialogs.dart';

/// Sleep log: last 7 nights chart, averages and history.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  Future<void> _log(BuildContext context) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = await showSleepDialog(context, initial: wellness.sleepToday);
    if (entry == null) return;
    final error = await wellness.saveSleep(entry);
    showSnack(messenger, error ?? 'Sleep saved');
  }

  Future<void> _delete(BuildContext context, SleepEntry entry) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Delete this entry?',
      message:
          'The sleep logged on ${DateHelper.display(entry.dateTime)} will be removed.',
    );
    if (!ok || entry.id == null) return;
    final error = await wellness.deleteSleep(entry.id!);
    showSnack(messenger, error ?? 'Entry deleted');
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final days = wellness.lastDays(7);
    final values = [for (final d in days) wellness.sleepOn(d)?.hours ?? 0.0];
    final average = wellness.averageSleepLast7;
    final today = wellness.sleepToday;
    final entries = wellness.sleep;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('log_sleep_fab'),
        onPressed: () => _log(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log sleep'),
      ),
      body: wellness.isLoading && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? EmptyState(
                  icon: Icons.bedtime_outlined,
                  title: 'No sleep logged yet',
                  message: 'Log how long you slept to see your pattern.',
                  actionLabel: 'Log sleep',
                  onAction: () => _log(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    StatsCard(items: [
                      StatItem(
                        'Average (7 days)',
                        average == null
                            ? '—'
                            : '${average.toStringAsFixed(1)} h',
                      ),
                      StatItem(
                        'Last night',
                        today == null
                            ? '—'
                            : '${today.hours.toStringAsFixed(1)} h',
                      ),
                      StatItem('Goal',
                          '${AppConstants.sleepGoalHours.toStringAsFixed(0)} h'),
                    ]),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Last 7 nights'),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                      child: DayBarChart(
                        days: days,
                        values: values,
                        color: AppColors.sleep,
                        goal: AppConstants.sleepGoalHours,
                        valueText: (v) => '${v.toStringAsFixed(1)} h',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'History'),
                    for (final entry in entries) ...[
                      LogTile(
                        leading: const Icon(Icons.bedtime_rounded,
                            color: AppColors.sleep),
                        color: AppColors.sleep,
                        title: DateHelper.display(entry.dateTime),
                        subtitle: 'Quality: ${entry.qualityLabel}',
                        trailing: '${entry.hours.toStringAsFixed(1)} h',
                        onDelete: () => _delete(context, entry),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    );
  }
}
