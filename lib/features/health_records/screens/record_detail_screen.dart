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
import '../../settings/models/user_goals.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/health_records_provider.dart';
import '../widgets/delete_record_dialog.dart';
import 'record_form_screen.dart';

/// Read-only view of one record with edit and delete actions.
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthRecordsProvider>();
    final goals = context.watch<SettingsProvider>().goals;
    final record = provider.findById(recordId);
    final theme = Theme.of(context);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record details')),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Record not found',
          message: 'This record no longer exists.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record details'),
        actions: [
          IconButton(
            tooltip: 'Edit record',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
              builder: (_) => RecordFormScreen(recordId: recordId),
            )),
          ),
          IconButton(
            tooltip: 'Delete record',
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final deleted = await confirmAndDeleteRecord(context, record);
              if (deleted) navigator.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateHelper.displayLong(record.dateTime),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (provider.isSample(record))
                Chip(
                  label: const Text('Sample'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      theme.colorScheme.secondary.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Progress compared with your daily goals',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _DetailCard(
            icon: Icons.directions_walk_rounded,
            color: AppColors.steps,
            label: 'Steps',
            value: Formatters.steps(record.steps),
            goalText: 'Goal ${Formatters.steps(goals.steps)}',
            progress: UserGoals.progress(record.steps, goals.steps),
            level: HealthLevel.of(record.steps, goals.steps),
          ),
          const SizedBox(height: 14),
          _DetailCard(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.calories,
            label: 'Calories burned',
            value: Formatters.calories(record.calories),
            goalText: 'Goal ${Formatters.calories(goals.calories)}',
            progress: UserGoals.progress(record.calories, goals.calories),
            level: HealthLevel.of(record.calories, goals.calories),
          ),
          const SizedBox(height: 14),
          _DetailCard(
            icon: Icons.water_drop_rounded,
            color: AppColors.water,
            label: 'Water intake',
            value: Formatters.water(record.water),
            goalText: 'Goal ${Formatters.water(goals.water)}',
            progress: UserGoals.progress(record.water, goals.water),
            level: HealthLevel.of(record.water, goals.water),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.goalText,
    required this.progress,
    required this.level,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String goalText;
  final double progress;
  final HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            color: color,
            size: 72,
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${Formatters.percent(progress)} of goal · $goalText',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                LevelChip(level: level),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
