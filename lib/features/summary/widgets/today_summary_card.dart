import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/daily_summary.dart';
import '../screens/daily_summary_screen.dart';

/// Home-screen card with today's steps, calories and water left to drink.
/// Tapping it opens the full [DailySummaryScreen].
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboard = context.watch<DashboardProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final summary = DailySummary.compute(
      today: dashboard.stats.today,
      goals: dashboard.goals,
      profile: profile,
      now: dashboard.now,
    );

    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const DailySummaryScreen(),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Today's summary",
                    key: const Key('today_summary_card'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Text('Details',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Mini(
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.steps,
                  value: Formatters.steps(summary.steps),
                  label: 'steps walked',
                  valueKey: const Key('card_steps'),
                ),
              ),
              Expanded(
                child: _Mini(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.calories,
                  value: Formatters.integer(summary.calories),
                  label: 'kcal burned',
                  valueKey: const Key('card_calories'),
                ),
              ),
              Expanded(
                child: _Mini(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.water,
                  value: Formatters.integer(summary.waterRemaining),
                  label: 'ml left to drink',
                  valueKey: const Key('card_water_left'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.valueKey,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
