import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/health_level.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/progress_ring.dart';

/// Compact summary tile for one metric with a goal progress ring.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.goalText,
    required this.level,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final double progress;
  final String goalText;
  final HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              ProgressRing(
                progress: progress,
                color: color,
                size: 40,
                strokeWidth: 5,
                child: Text(
                  Formatters.percent(progress),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Text(unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(goalText,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          LevelChip(level: level),
        ],
      ),
    );
  }
}
