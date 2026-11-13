import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';

/// One-tap buttons that add water to today's total.
class QuickWaterCard extends StatelessWidget {
  const QuickWaterCard({super.key, required this.onAdd});

  final void Function(int ml) onAdd;

  static const List<int> amounts = [150, 250, 500];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.water),
              const SizedBox(width: 8),
              Text('Quick add water',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final ml in amounts) ...[
                Expanded(
                  child: OutlinedButton(
                    key: Key('add_water_$ml'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => onAdd(ml),
                    child: Text('+$ml ml'),
                  ),
                ),
                if (ml != amounts.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
