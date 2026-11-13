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
import 'features/profile/providers/profile_provider.dart';
import 'features/reminders/providers/reminder_provider.dart';
import 'features/reminders/services/local_notification_scheduler.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/steps/providers/step_counter_provider.dart';
import 'features/steps/services/step_sensor.dart';
import 'features/wellness/providers/wellness_provider.dart';
import 'features/wellness/repositories/wellness_repository.dart';
import 'features/weight/providers/weight_provider.dart';
import 'features/weight/repositories/weight_repository.dart';

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
        ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) =>
              WeightProvider(WeightRepository(DatabaseHelper.instance)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              WellnessProvider(WellnessRepository(DatabaseHelper.instance)),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthRecordsProvider(repository, sampleData),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            context.read<HealthRecordsProvider>(),
            context.read<SettingsProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider(prefs, LocalNotificationScheduler()),
        ),
        ChangeNotifierProvider(
          create: (context) => StepCounterProvider(
            prefs: prefs,
            sensor: PedometerSensor(),
            records: context.read<HealthRecordsProvider>(),
            profile: context.read<ProfileProvider>(),
          ),
        ),
      ],
      child: const HealthMateApp(),
    ),
  );
}
