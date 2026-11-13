import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/shell_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../models/mood_entry.dart';
import '../providers/wellness_provider.dart';
import '../screens/mood_screen.dart';
import '../screens/sleep_screen.dart';
import '../screens/workouts_screen.dart';

/// Today's sleep, workout and mood at a glance (shown on the dashboard).
class WellnessSummaryCard extends StatelessWidget {
  const WellnessSummaryCard({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wellness = context.watch<WellnessProvider>();
    final sleep = wellness.sleepToday;
    final minutes = wellness.workoutMinutesToday;
    final mood = wellness.moodToday;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Wellness today',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () => context.read<ShellController>().goTo(3),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _MiniTile(
                  tileKey: const Key('wellness_sleep_tile'),
                  icon: Icons.bedtime_rounded,
                  color: AppColors.sleep,
                  value: sleep == null ? 'Log' : '${sleep.hours.toStringAsFixed(1)} h',
                  label: 'Sleep',
                  onTap: () => _open(context, const SleepScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniTile(
                  tileKey: const Key('wellness_workout_tile'),
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.workout,
                  value: minutes == 0 ? 'Log' : '$minutes min',
                  label: 'Workout',
                  onTap: () => _open(context, const WorkoutsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniTile(
                  tileKey: const Key('wellness_mood_tile'),
                  icon: Icons.mood_rounded,
                  color: AppColors.mood,
                  value: mood == null ? 'Log' : MoodScale.emoji(mood.mood),
                  label: 'Mood',
                  onTap: () => _open(context, const MoodScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.tileKey,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: tileKey,
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
