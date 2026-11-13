import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snack.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../models/workout_entry.dart';
import '../providers/wellness_provider.dart';
import '../widgets/day_bar_chart.dart';
import '../widgets/log_tile.dart';
import '../widgets/wellness_dialogs.dart';

/// Workout log: minutes per day chart, totals and history.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  Future<void> _log(BuildContext context) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = await showWorkoutDialog(context);
    if (entry == null) return;
    final error = await wellness.addWorkout(entry);
    showSnack(messenger, error ?? 'Workout saved');
  }

  Future<void> _delete(BuildContext context, WorkoutEntry entry) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Delete this workout?',
      message:
          'The ${entry.type.toLowerCase()} session on ${DateHelper.display(entry.dateTime)} will be removed.',
    );
    if (!ok || entry.id == null) return;
    final error = await wellness.deleteWorkout(entry.id!);
    showSnack(messenger, error ?? 'Workout deleted');
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final days = wellness.lastDays(7);
    final values = [
      for (final d in days) wellness.workoutMinutesOn(d).toDouble(),
    ];
    final workouts = wellness.workouts;

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('log_workout_fab'),
        onPressed: () => _log(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log workout'),
      ),
      body: wellness.isLoading && workouts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : workouts.isEmpty
              ? EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'No workouts yet',
                  message: 'Log a walk, run, gym session or anything else.',
                  actionLabel: 'Log workout',
                  onAction: () => _log(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    StatsCard(items: [
                      StatItem('Today', '${wellness.workoutMinutesToday} min'),
                      StatItem(
                          'Last 7 days', '${wellness.workoutMinutesLast7} min'),
                      StatItem('Sessions', Formatters.integer(workouts.length)),
                    ]),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Minutes per day'),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                      child: DayBarChart(
                        days: days,
                        values: values,
                        color: AppColors.workout,
                        goal: AppConstants.workoutGoalMinutes.toDouble(),
                        valueText: (v) => '${v.round()} min',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'History'),
                    for (final entry in workouts) ...[
                      LogTile(
                        leading: Icon(WorkoutTypes.iconFor(entry.type),
                            color: AppColors.workout),
                        color: AppColors.workout,
                        title: '${entry.type} · ${entry.minutes} min',
                        subtitle: _subtitle(entry),
                        onDelete: () => _delete(context, entry),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    );
  }

  String _subtitle(WorkoutEntry entry) {
    final parts = <String>[
      DateHelper.display(entry.dateTime),
      if (entry.calories > 0) '${entry.calories} kcal',
      if (entry.note.isNotEmpty) entry.note,
    ];
    return parts.join(' · ');
  }
}
