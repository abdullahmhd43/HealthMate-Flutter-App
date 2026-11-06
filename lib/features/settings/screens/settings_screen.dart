import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../models/user_goals.dart';
import '../providers/settings_provider.dart';
import '../widgets/goal_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editGoal(
    BuildContext context, {
    required String title,
    required String label,
    required String unit,
    required int current,
    required int max,
    required UserGoals Function(UserGoals goals, int value) apply,
  }) async {
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final value = await showGoalDialog(
      context,
      title: title,
      label: label,
      unit: unit,
      current: current,
      max: max,
    );
    if (value == null) return;
    await settings.updateGoals(apply(settings.goals, value));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Goal updated')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final records = context.watch<HealthRecordsProvider>();
    final goals = settings.goals;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          const SectionHeader(title: 'Daily goals'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _GoalTile(
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.steps,
                  title: 'Step goal',
                  value: '${Formatters.steps(goals.steps)} steps',
                  onTap: () => _editGoal(
                    context,
                    title: 'Daily step goal',
                    label: 'Steps',
                    unit: 'steps',
                    current: goals.steps,
                    max: AppConstants.maxSteps,
                    apply: (g, v) => g.copyWith(steps: v),
                  ),
                ),
                _GoalTile(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.water,
                  title: 'Water goal',
                  value: Formatters.water(goals.water),
                  onTap: () => _editGoal(
                    context,
                    title: 'Daily water goal',
                    label: 'Water',
                    unit: 'ml',
                    current: goals.water,
                    max: AppConstants.maxWater,
                    apply: (g, v) => g.copyWith(water: v),
                  ),
                ),
                _GoalTile(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.calories,
                  title: 'Calorie goal',
                  value: Formatters.calories(goals.calories),
                  onTap: () => _editGoal(
                    context,
                    title: 'Daily calorie goal',
                    label: 'Calories',
                    unit: 'kcal',
                    current: goals.calories,
                    max: AppConstants.maxCalories,
                    apply: (g, v) => g.copyWith(calories: v),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Appearance'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Sample data'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  records.sampleCount == 0
                      ? 'No sample records are stored.'
                      : '${records.sampleCount} sample '
                          '${records.sampleCount == 1 ? 'record is' : 'records are'} '
                          'stored. They are labelled "Sample" in your history.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46)),
                        onPressed: records.sampleCount == 0
                            ? null
                            : () => _confirmClear(context),
                        child: const Text('Clear samples'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46)),
                        onPressed: () => _restore(context),
                        child: const Text('Add samples'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'About'),
          const AppCard(
            child: Column(
              children: [
                _InfoRow(label: 'Application', value: AppConstants.appName),
                _InfoRow(label: 'Version', value: AppConstants.version),
                _InfoRow(label: 'Storage', value: 'Local SQLite (offline)'),
                _InfoRow(label: 'Course', value: 'CI6330 Coursework 1'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final records = context.read<HealthRecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear sample records?'),
        content: const Text(
            'Only the sample records will be deleted. Records you added yourself are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await records.clearSampleRecords();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
        SnackBar(content: Text('Removed $removed sample records')));
  }

  Future<void> _restore(BuildContext context) async {
    final records = context.read<HealthRecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final added = await records.restoreSampleRecords();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'No new samples added (those dates already have records)'
          : 'Added $added sample records'),
    ));
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_outlined, size: 20),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
