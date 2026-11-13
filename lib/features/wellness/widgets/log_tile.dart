import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

/// One row in a history list: coloured icon (or emoji), title, subtitle and an
/// optional delete button.
class LogTile extends StatelessWidget {
  const LogTile({
    super.key,
    required this.leading,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onDelete,
  });

  final Widget leading;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: leading,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: color)),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete entry',
              icon: Icon(Icons.delete_outline,
                  size: 20, color: theme.colorScheme.error),
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// One label/value pair for [StatsCard].
class StatItem {
  const StatItem(this.label, this.value);

  final String label;
  final String value;
}

/// A card with 2-3 headline numbers side by side.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(item.value,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
