import 'package:flutter/material.dart';

import '../utils/health_level.dart';

/// Small coloured pill showing a [HealthLevel] (Low, Moderate, Good, Excellent).
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level, this.compact = false});

  final HealthLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: compact ? 12 : 14, color: level.color),
          const SizedBox(width: 4),
          Text(
            level.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: level.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
