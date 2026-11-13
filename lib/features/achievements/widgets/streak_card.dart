import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/streaks.dart';
import '../../../core/widgets/app_card.dart';
import '../../health_records/providers/health_records_provider.dart';
import '../screens/achievements_screen.dart';

/// Logging streak with the last 7 days as dots. Tap to open the badges.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HealthRecordsProvider>();
    // Demo (sample) records never count towards the streak.
    final dates = provider.allRecords
        .where((r) => !provider.isSample(r))
        .map((r) => r.date)
        .toSet();
    final now = DateTime.now();
    final current = Streaks.current(dates, today: now);
    final best = Streaks.best(dates);
    final today = DateHelper.dateOnly(now);
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];

    return AppCard(
      key: const Key('streak_card'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current == 0 ? 'Start your streak today' : '$current-day streak',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Best: $best ${best == 1 ? 'day' : 'days'} · tap for badges',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateHelper.weekday(day),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        dates.contains(DateHelper.toIso(day))
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 22,
                        color: dates.contains(DateHelper.toIso(day))
                            ? AppColors.steps
                            : theme.colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
