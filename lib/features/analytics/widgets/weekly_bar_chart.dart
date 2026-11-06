import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/models/dashboard_stats.dart';

/// Seven-day bar chart for any metric. Values come from [days], which are
/// derived from SQLite records.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.days,
    required this.valueOf,
    required this.color,
    required this.unit,
    this.goal,
    this.height = 200,
  });

  final List<DaySummary> days;
  final int Function(DaySummary day) valueOf;
  final Color color;
  final String unit;
  final int? goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = days.map(valueOf).toList();
    final peak = values.fold<int>(0, math.max);
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
                    y: goal!.toDouble(),
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
                      DateHelper.weekday(days[index].date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = days[group.x];
                return BarTooltipItem(
                  '${DateHelper.shortDay(day.date)}\n'
                  '${Formatters.integer(valueOf(day))} $unit',
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
                    toY: valueOf(days[i]).toDouble(),
                    width: 16,
                    color: days[i].hasRecord
                        ? color
                        : color.withValues(alpha: 0.25),
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
