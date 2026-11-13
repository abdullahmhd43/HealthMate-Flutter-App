import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../../reminders/screens/reminders_screen.dart';
import '../../steps/providers/step_counter_provider.dart';

/// Settings card: reminders and automatic step counting.
class AutomationCard extends StatelessWidget {
  const AutomationCard({super.key});

  String _reminderSummary(ReminderProvider reminders) {
    final s = reminders.settings;
    if (!s.anyEnabled) return 'Off';
    final parts = <String>[
      if (s.dailyEnabled) 'Daily at ${s.dailyTimeLabel}',
      if (s.waterEnabled) 'Water',
    ];
    return parts.join(' · ');
  }

  String _stepSubtitle(StepCounterProvider steps) {
    switch (steps.status) {
      case StepStatus.off:
        return 'Count your steps with the phone sensor';
      case StepStatus.starting:
        return 'Starting...';
      case StepStatus.active:
        return 'On · ${Formatters.integer(steps.todaySteps)} steps counted today';
      case StepStatus.permissionDenied:
        return 'Allow "Physical activity" for HealthMate in phone settings';
      case StepStatus.unavailable:
        return 'No step sensor available on this device';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final steps = context.watch<StepCounterProvider>();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            key: const Key('reminders_tile'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Reminders'),
            subtitle: Text(_reminderSummary(reminders)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RemindersScreen()),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            key: const Key('auto_steps_switch'),
            secondary: const Icon(Icons.directions_walk_rounded),
            title: const Text('Automatic step counting'),
            subtitle: Text(_stepSubtitle(steps)),
            value: steps.enabled,
            onChanged: (value) => steps.setEnabled(value),
          ),
        ],
      ),
    );
  }
}
