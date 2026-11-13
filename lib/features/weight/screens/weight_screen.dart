import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/weight_entry.dart';
import '../providers/weight_provider.dart';
import '../widgets/weight_dialog.dart';

/// Weight history with a trend chart. Newest entry also updates the profile
/// weight, so BMI and goals stay current.
class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final weights = context.read<WeightProvider>();
    final profiles = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final entry =
        await showWeightDialog(context, initialKg: weights.latest?.weightKg);
    if (entry == null) return;

    final error = await weights.add(entry);
    if (error == null && weights.latest?.date == entry.date) {
      await profiles.updateWeight(entry.weightKg);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Weight saved')));
  }

  Future<void> _delete(BuildContext context, WeightEntry entry) async {
    final weights = context.read<WeightProvider>();
    final profiles = context.read<ProfileProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(
            'The weight logged on ${DateHelper.display(entry.dateTime)} will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || entry.id == null) return;
    final wasLatest = weights.latest?.id == entry.id;
    final error = await weights.delete(entry.id!);
    // The profile (BMI, goals) follows the newest remaining weight.
    final newest = weights.latest;
    if (error == null && wasLatest && newest != null) {
      await profiles.updateWeight(newest.weightKg);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Entry deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final weights = context.watch<WeightProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final theme = Theme.of(context);
    final entries = weights.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('Weight tracker')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_weight_fab'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log weight'),
      ),
      body: weights.isLoading && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? EmptyState(
                  icon: Icons.monitor_weight_outlined,
                  title: 'No weight logged yet',
                  message:
                      'Log your weight now and then to see your trend over time.',
                  actionLabel: 'Log weight',
                  onAction: () => _add(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    _SummaryCard(weights: weights, profile: profile),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Trend'),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                      child: _WeightChart(entries: entries),
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'History'),
                    for (final entry in entries) ...[
                      AppCard(
                        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateHelper.display(entry.dateTime),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${entry.weightKg.toStringAsFixed(1)} kg',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              tooltip: 'Delete entry',
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: theme.colorScheme.error),
                              onPressed: () => _delete(context, entry),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.weights, required this.profile});

  final WeightProvider weights;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = weights.latest!;
    final change = weights.changeSinceStart;
    final bmi = profile.heightCm == null
        ? null
        : latest.weightKg /
            math.pow(profile.heightCm! / 100, 2).toDouble();

    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        );

    return AppCard(
      child: Row(
        children: [
          stat('Current', '${latest.weightKg.toStringAsFixed(1)} kg'),
          stat(
            'Change',
            change == null
                ? '—'
                : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
          ),
          stat('BMI', bmi == null ? '—' : bmi.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});

  /// Newest first (as stored); the chart draws oldest to newest.
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = entries.take(30).toList().reversed.toList();
    final values = shown.map((e) => e.weightKg).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = math.max(1.0, (maxV - minV) * 0.2);
    final color = theme.colorScheme.primary;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: (minV - pad).floorToDouble(),
          maxY: (maxV + pad).ceilToDouble(),
          minX: 0,
          maxX: math.max(1, shown.length - 1).toDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  final isEdge = i == 0 || i == shown.length - 1;
                  if (value != i.toDouble() ||
                      i < 0 ||
                      i >= shown.length ||
                      !isEdge) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateHelper.shortDay(shown[i].dateTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${DateHelper.shortDay(shown[s.x.toInt()].dateTime)}\n'
                    '${s.y.toStringAsFixed(1)} kg',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < shown.length; i++)
                  FlSpot(i.toDouble(), shown[i].weightKg),
              ],
              isCurved: shown.length > 2,
              barWidth: 3,
              color: color,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
