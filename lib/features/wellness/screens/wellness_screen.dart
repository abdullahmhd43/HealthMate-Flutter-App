import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../achievements/widgets/streak_card.dart';
import '../models/mood_entry.dart';
import '../providers/wellness_provider.dart';
import 'mood_screen.dart';
import 'sleep_screen.dart';
import 'workouts_screen.dart';

/// Wellness tab: entry point for sleep, workouts and mood, plus the streak.
class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final avgSleep = wellness.averageSleepLast7;
    final avgMood = wellness.averageMoodLast7;
    final minutes = wellness.workoutMinutesLast7;

    return Scaffold(
      appBar: AppBar(title: const Text('Wellness')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          const StreakCard(),
          const SectionHeader(title: 'Track'),
          _HubCard(
            key: const Key('hub_sleep'),
            icon: Icons.bedtime_rounded,
            color: AppColors.sleep,
            title: 'Sleep',
            subtitle: avgSleep == null
                ? 'No nights logged yet'
                : 'Average ${avgSleep.toStringAsFixed(1)} h this week',
            onTap: () => _open(context, const SleepScreen()),
          ),
          const SizedBox(height: 12),
          _HubCard(
            key: const Key('hub_workouts'),
            icon: Icons.fitness_center_rounded,
            color: AppColors.workout,
            title: 'Workouts',
            subtitle: minutes == 0
                ? 'No workouts in the last 7 days'
                : '$minutes min in the last 7 days',
            onTap: () => _open(context, const WorkoutsScreen()),
          ),
          const SizedBox(height: 12),
          _HubCard(
            key: const Key('hub_mood'),
            icon: Icons.mood_rounded,
            color: AppColors.mood,
            title: 'Mood',
            subtitle: avgMood == null
                ? 'No mood logged yet'
                : 'Average ${avgMood.toStringAsFixed(1)} '
                    '${MoodScale.emoji(avgMood.round())} this week',
            onTap: () => _open(context, const MoodScreen()),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
