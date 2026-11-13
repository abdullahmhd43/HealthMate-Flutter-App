import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../wellness/providers/wellness_provider.dart';
import '../../weight/providers/weight_provider.dart';
import '../models/achievement.dart';
import '../services/achievement_engine.dart';

/// Streak summary and every badge, locked or unlocked.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<HealthRecordsProvider>();
    // Demo (sample) records never count towards badges or streaks.
    final records =
        recordsProvider.allRecords.where((r) => !recordsProvider.isSample(r)).toList();
    final goals = context.watch<SettingsProvider>().goals;
    final weights = context.watch<WeightProvider>().entries;
    final wellness = context.watch<WellnessProvider>();
    final theme = Theme.of(context);

    final summary = AchievementEngine.evaluate(
      records: records,
      goals: goals,
      weightCount: weights.length,
      sleep: wellness.sleep,
      workouts: wellness.workouts,
      moods: wellness.moods,
      now: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          AppCard(
            child: Row(
              children: [
                _Stat(
                    label: 'Unlocked',
                    value: '${summary.unlockedCount}/${summary.total}'),
                _Stat(
                    label: 'Current streak',
                    value: '${summary.currentStreak} d'),
                _Stat(label: 'Best streak', value: '${summary.bestStreak} d'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.66,
            children: [
              for (final badge in summary.badges) _BadgeCard(badge: badge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Badges unlock from your own records. Nothing is pre-filled.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = !badge.unlocked;
    final accent =
        locked ? theme.colorScheme.outline : badge.color;

    return AppCard(
      key: Key('badge_${badge.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(locked ? Icons.lock_outline_rounded : badge.icon,
                color: accent, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          if (locked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 6,
                color: badge.color,
                backgroundColor: badge.color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${Formatters.integer(badge.shownCurrent)} / ${Formatters.integer(badge.target)}',
              style: theme.textTheme.labelSmall,
            ),
          ] else
            Text('Unlocked ✓',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: badge.color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
