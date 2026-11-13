import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/shell_controller.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../providers/dashboard_provider.dart';
import '../../health_records/screens/history_screen.dart';
import '../../health_records/screens/record_form_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../wellness/screens/wellness_screen.dart';
import 'dashboard_screen.dart';

/// Hosts the five tabs. [IndexedStack] keeps each tab's state (scroll
/// position, search text) alive while switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // After the app was in the background (maybe past midnight), refresh the
    // dashboard so "Today" shows the real current day.
    if (state == AppLifecycleState.resumed) {
      context.read<DashboardProvider>().refresh();
    }
  }

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
          WellnessScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: shell.index >= 3
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
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Wellness',
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
