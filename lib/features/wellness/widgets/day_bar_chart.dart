import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/date_helper.dart';

/// Bar chart for a list of days (oldest first) and one value per day.
class DayBarChart extends StatelessWidget {
  const DayBarChart({
    super.key,
    required this.days,
    required this.values,
    required this.color,
    required this.valueText,
    this.goal,
    this.height = 180,
  });

  final List<DateTime> days;
  final List<double> values;
  final Color color;

  /// Formats a value for the tooltip, for example `7.5 h`.
  final String Function(double value) valueText;
  final double? goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peak = values.fold<double>(0, math.max);
    final top = math.max(peak, goal ?? 0);
    final maxY = top == 0 ? 10.0 : top * 1.2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: goal == null
              ? null
              : ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: goal!,
                    color: color.withValues(alpha: 0.7),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ]),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateHelper.weekday(days[index]),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${DateHelper.shortDay(days[group.x])}\n'
                  '${valueText(values[group.x])}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 16,
                    color: values[i] > 0 ? color : color.withValues(alpha: 0.25),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
