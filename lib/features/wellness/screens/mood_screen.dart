import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snack.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../models/mood_entry.dart';
import '../providers/wellness_provider.dart';
import '../widgets/log_tile.dart';
import '../widgets/wellness_dialogs.dart';

/// Mood log: a 7-day emoji strip, average and history.
class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  Future<void> _log(BuildContext context) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = await showMoodDialog(context, initial: wellness.moodToday);
    if (entry == null) return;
    final error = await wellness.saveMood(entry);
    showSnack(messenger, error ?? 'Mood saved');
  }

  Future<void> _delete(BuildContext context, MoodEntry entry) async {
    final wellness = context.read<WellnessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Delete this entry?',
      message:
          'The mood logged on ${DateHelper.display(entry.dateTime)} will be removed.',
    );
    if (!ok || entry.id == null) return;
    final error = await wellness.deleteMood(entry.id!);
    showSnack(messenger, error ?? 'Entry deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wellness = context.watch<WellnessProvider>();
    final moods = wellness.moods;
    final average = wellness.averageMoodLast7;
    final today = wellness.moodToday;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('log_mood_fab'),
        onPressed: () => _log(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log mood'),
      ),
      body: wellness.isLoading && moods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : moods.isEmpty
              ? EmptyState(
                  icon: Icons.mood_rounded,
                  title: 'No mood logged yet',
                  message: 'Log how you feel each day to spot patterns.',
                  actionLabel: 'Log mood',
                  onAction: () => _log(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    StatsCard(items: [
                      StatItem(
                        'Average (7 days)',
                        average == null
                            ? '—'
                            : '${average.toStringAsFixed(1)} '
                                '${MoodScale.emoji(average.round())}',
                      ),
                      StatItem('Today',
                          today == null ? '—' : MoodScale.emoji(today.mood)),
                      StatItem('Logged', Formatters.integer(moods.length)),
                    ]),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Last 7 days'),
                    AppCard(
                      child: Row(
                        children: [
                          for (final day in wellness.lastDays(7))
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    DateHelper.weekday(day),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    wellness.moodOn(day) == null
                                        ? '·'
                                        : MoodScale.emoji(
                                            wellness.moodOn(day)!.mood),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'History'),
                    for (final entry in moods) ...[
                      LogTile(
                        leading: Text(MoodScale.emoji(entry.mood),
                            style: const TextStyle(fontSize: 22)),
                        color: AppColors.mood,
                        title: MoodScale.label(entry.mood),
                        subtitle: entry.note.isEmpty
                            ? DateHelper.display(entry.dateTime)
                            : '${DateHelper.display(entry.dateTime)} · ${entry.note}',
                        onDelete: () => _delete(context, entry),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
    );
  }
}
