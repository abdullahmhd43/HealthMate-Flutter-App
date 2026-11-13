import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/dashboard/providers/dashboard_provider.dart';
import 'package:healthmate/features/health_records/providers/health_records_provider.dart';
import 'package:healthmate/features/health_records/services/sample_data_service.dart';
import 'package:healthmate/features/profile/providers/profile_provider.dart';
import 'package:healthmate/features/settings/providers/settings_provider.dart';
import 'package:healthmate/features/summary/screens/daily_summary_screen.dart';
import 'package:healthmate/features/summary/widgets/today_summary_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Saturday 14 Nov 2026, 15:00: 8 of the 15 drinking hours have passed.
final DateTime _now = DateTime(2026, 11, 14, 15);

class _Harness {
  _Harness(this.records, this.dashboard, this.prefs);
  final HealthRecordsProvider records;
  final DashboardProvider dashboard;
  final SharedPreferences prefs;

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<HealthRecordsProvider>.value(value: records),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
          ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(prefs)),
        ],
        child: MaterialApp(home: child),
      );
}

Future<_Harness> _setUp(
  WidgetTester tester, {
  bool withToday = true,
}) async {
  SharedPreferences.setMockInitialValues({'sample_data_seeded': true});
  final prefs = await SharedPreferences.getInstance();
  final repo = newRepository(newIsolatedHelper());
  final records = HealthRecordsProvider(repo, SampleDataService(repo, prefs));
  await tester.runAsync(() async {
    await records.init();
    if (withToday) {
      await records.addRecord(
          record('2026-11-14', steps: 7000, calories: 280, water: 1000));
    }
  });
  final dashboard =
      DashboardProvider(records, SettingsProvider(prefs), clock: () => _now);
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return _Harness(records, dashboard, prefs);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data ?? '';

/// Waits for a real database write to finish, then rebuilds.
Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(initTestDatabaseFactory);

  group('DailySummaryScreen', () {
    testWidgets('shows steps, calories and the water plan from the data',
        (tester) async {
      final h = await _setUp(tester);
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text("Today's summary"), findsOneWidget);
      expect(_text(tester, 'steps_value'), '7,000');
      expect(_text(tester, 'distance_value'), '4.94 km');
      expect(_text(tester, 'steps_remaining_value'), '3,000 steps (2.1 km)');
      expect(_text(tester, 'calories_value'), contains('280'));

      expect(_text(tester, 'water_drunk_value'), '1,000 ml');
      expect(_text(tester, 'water_target_value'), '2,650 ml');
      expect(_text(tester, 'water_remaining_value'), '1,650 ml');
      expect(_text(tester, 'water_glasses_text'),
          'about 7 glasses (250 ml)');
      expect(find.text('Behind schedule'), findsOneWidget);
      expect(_text(tester, 'water_advice'), contains('413 ml behind'));
      expect(_text(tester, 'water_advice'), contains('240 ml every hour'));
      expect(_text(tester, 'water_breakdown'), contains('150 ml'));
    });

    testWidgets('adding water updates the numbers and the database',
        (tester) async {
      final h = await _setUp(tester);
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.byKey(const Key('summary_add_water_250')));
      await tester.tap(find.byKey(const Key('summary_add_water_250')));
      await _waitFor(
          tester, () => _text(tester, 'water_drunk_value') == '1,250 ml');
      await tester.pump(const Duration(seconds: 1));

      expect(_text(tester, 'water_drunk_value'), '1,250 ml');
      expect(_text(tester, 'water_remaining_value'), '1,400 ml');
      expect(_text(tester, 'water_glasses_text'),
          'about 6 glasses (250 ml)');
      // 1,250 is within a glass of the 1,413 ml schedule.
      expect(find.text('On track'), findsOneWidget);
      expect(h.records.findByDate('2026-11-14')!.water, 1250);
      expect(find.text('Added 250 ml of water'), findsOneWidget);
    });

    testWidgets('reaching the target shows the done state', (tester) async {
      final h = await _setUp(tester);
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      for (var i = 0; i < 4; i++) {
        final before = h.records.findByDate('2026-11-14')!.water;
        await tester.ensureVisible(
            find.byKey(const Key('summary_add_water_500')));
        await tester.tap(find.byKey(const Key('summary_add_water_500')));
        await _waitFor(tester,
            () => h.records.findByDate('2026-11-14')!.water == before + 500);
      }
      await tester.pump(const Duration(seconds: 1));

      expect(_text(tester, 'water_drunk_value'), '3,000 ml');
      expect(_text(tester, 'water_remaining_value'), '0 ml');
      expect(find.text('Target reached'), findsOneWidget);
      expect(find.byKey(const Key('water_glasses_text')), findsNothing);
      expect(_text(tester, 'water_advice'), contains('reached'));
    });

    testWidgets('an empty day still shows a plan, and +500 creates a record',
        (tester) async {
      final h = await _setUp(tester, withToday: false);
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(_text(tester, 'steps_value'), '0');
      expect(_text(tester, 'water_drunk_value'), '0 ml');
      expect(_text(tester, 'water_target_value'), '2,500 ml');
      expect(_text(tester, 'water_remaining_value'), '2,500 ml');
      expect(find.byKey(const Key('week_empty')), findsOneWidget);
      expect(h.records.findByDate('2026-11-14'), isNull);

      await tester.ensureVisible(find.byKey(const Key('summary_add_water_500')));
      await tester.tap(find.byKey(const Key('summary_add_water_500')));
      await _waitFor(
          tester, () => _text(tester, 'water_drunk_value') == '500 ml');
      await tester.pump(const Duration(seconds: 1));

      expect(_text(tester, 'water_drunk_value'), '500 ml');
      expect(h.records.findByDate('2026-11-14')!.water, 500);
      expect(h.records.findByDate('2026-11-14')!.steps, 0);
    });

    testWidgets('the weekly card averages the logged days', (tester) async {
      final h = await _setUp(tester);
      await tester.runAsync(() async {
        await h.records.addRecord(
            record('2026-11-13', steps: 9000, calories: 360, water: 3000));
      });
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('week_empty')), findsNothing);
      expect(_text(tester, 'week_steps_value'), contains('8,000'));
      expect(_text(tester, 'week_water_value'), contains('2,000'));
    });

    testWidgets('the edit button opens the record form', (tester) async {
      final h = await _setUp(tester);
      await tester.pumpWidget(h.wrap(const DailySummaryScreen()));
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.byKey(const Key('summary_edit_record')));
      await tester.tap(find.byKey(const Key('summary_edit_record')));
      await tester.pump(const Duration(seconds: 1));
      // The form loads the record from the real database: wait for it.
      await _waitFor(tester,
          () => find.byKey(const Key('steps_field')).evaluate().isNotEmpty);
      expect(find.byKey(const Key('steps_field')), findsOneWidget);
    });
  });

  group('TodaySummaryCard', () {
    testWidgets('shows today\'s numbers and opens the full screen',
        (tester) async {
      final h = await _setUp(tester);
      await tester.pumpWidget(h.wrap(const Scaffold(
        body: SingleChildScrollView(child: TodaySummaryCard()),
      )));
      await tester.pump();

      expect(_text(tester, 'card_steps'), '7,000');
      expect(_text(tester, 'card_calories'), '280');
      expect(_text(tester, 'card_water_left'), '1,650');

      await tester.tap(find.byKey(const Key('today_summary_card')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DailySummaryScreen), findsOneWidget);
    });
  });
}
