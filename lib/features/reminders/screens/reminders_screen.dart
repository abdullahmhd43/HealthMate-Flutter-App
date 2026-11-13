import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snack.dart';
import '../../../core/widgets/app_card.dart';
import '../models/reminder_settings.dart';
import '../providers/reminder_provider.dart';

/// Switches and time for the daily check-in and water reminders.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _pickTime(BuildContext context) async {
    final reminders = context.read<ReminderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final settings = reminders.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: settings.dailyHour, minute: settings.dailyMinute),
    );
    if (picked == null) return;
    final error = await reminders.setDailyTime(picked.hour, picked.minute);
    if (error != null) showSnack(messenger, error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = context.watch<ReminderProvider>();
    final settings = reminders.settings;

    Future<void> run(Future<String?> action) async {
      final messenger = ScaffoldMessenger.of(context);
      final error = await action;
      if (error != null) showSnack(messenger, error);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('daily_reminder_switch'),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Daily check-in'),
                  subtitle: Text(settings.dailyEnabled
                      ? 'Every day at ${settings.dailyTimeLabel}'
                      : 'A nudge to log your day'),
                  value: settings.dailyEnabled,
                  onChanged: (v) => run(reminders.setDailyEnabled(v)),
                ),
                if (settings.dailyEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('daily_reminder_time'),
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Time'),
                    trailing: Text(settings.dailyTimeLabel,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    onTap: () => _pickTime(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SwitchListTile(
              key: const Key('water_reminder_switch'),
              secondary: const Icon(Icons.water_drop_outlined),
              title: const Text('Water reminders'),
              subtitle: Text(
                  'Every 2 hours, ${ReminderSettings.waterHours.first} AM to '
                  '${ReminderSettings.waterHours.last - 12} PM'),
              value: settings.waterEnabled,
              onChanged: (v) => run(reminders.setWaterEnabled(v)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reminders use your phone\'s notifications. If they do not appear, '
            'allow notifications for HealthMate in your phone settings.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
