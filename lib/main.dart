import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/utils/shell_controller.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/health_records/providers/health_records_provider.dart';
import 'features/health_records/repositories/health_record_repository.dart';
import 'features/health_records/services/sample_data_service.dart';
import 'features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final repository = HealthRecordRepository(DatabaseHelper.instance);
  final sampleData = SampleDataService(repository, prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShellController()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => HealthRecordsProvider(repository, sampleData),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            context.read<HealthRecordsProvider>(),
            context.read<SettingsProvider>(),
          ),
        ),
      ],
      child: const HealthMateApp(),
    ),
  );
}
