import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/shell_controller.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../health_records/screens/history_screen.dart';
import '../../health_records/screens/record_form_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'dashboard_screen.dart';

/// Hosts the four tabs. [IndexedStack] keeps each tab's state (scroll
/// position, search text) alive while switching.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();

    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: shell.index,
        children: const [
          DashboardScreen(),
          HistoryScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: shell.index == 3
          ? null
          : FloatingActionButton.extended(
              key: const Key('add_record_fab'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => const RecordFormScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add record'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.index,
        onDestinationSelected: shell.goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
