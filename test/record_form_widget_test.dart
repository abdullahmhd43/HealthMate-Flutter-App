import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/health_records/providers/health_records_provider.dart';
import 'package:healthmate/features/health_records/screens/record_form_screen.dart';
import 'package:healthmate/features/health_records/services/sample_data_service.dart';
import 'package:healthmate/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('form shows validation messages and does not save bad input',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // The database is opened lazily, and validation fails before any query,
    // so no database is touched in this test.
    final repo = newRepository(newIsolatedHelper());
    final provider =
        HealthRecordsProvider(repo, SampleDataService(repo, prefs));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HealthRecordsProvider>.value(value: provider),
          ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(prefs)),
        ],
        child: const MaterialApp(home: RecordFormScreen()),
      ),
    );

    // Empty form
    await tester.ensureVisible(find.byKey(const Key('save_button')));
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pump();
    expect(find.text('Steps is required'), findsOneWidget);
    expect(find.text('Calories is required'), findsOneWidget);
    expect(find.text('Water intake is required'), findsOneWidget);

    // Negative value
    await tester.enterText(find.byKey(const Key('steps_field')), '-10');
    await tester.enterText(find.byKey(const Key('calories_field')), '300');
    await tester.enterText(find.byKey(const Key('water_field')), '2000');
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pump();
    expect(find.text('Steps cannot be negative'), findsOneWidget);
    expect(find.text('Calories is required'), findsNothing);

    // Decimal value
    await tester.enterText(find.byKey(const Key('steps_field')), '12.5');
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pump();
    expect(find.text('Steps must be a whole number'), findsOneWidget);

    expect(provider.allRecords, isEmpty);
  });

  testWidgets('cancel button closes the form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = newRepository(newIsolatedHelper());
    final provider =
        HealthRecordsProvider(repo, SampleDataService(repo, prefs));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HealthRecordsProvider>.value(value: provider),
          ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(prefs)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                        builder: (_) => const RecordFormScreen()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add record'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('cancel_button')));
    await tester.tap(find.byKey(const Key('cancel_button')));
    await tester.pumpAndSettle();
    expect(find.byType(RecordFormScreen), findsNothing);
  });

  testWidgets('calories are estimated from steps until the user edits them',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = newRepository(newIsolatedHelper());
    final provider =
        HealthRecordsProvider(repo, SampleDataService(repo, prefs));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HealthRecordsProvider>.value(value: provider),
          ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(prefs)),
        ],
        child: const MaterialApp(home: RecordFormScreen()),
      ),
    );

    String calories() => tester
        .widget<TextFormField>(find.byKey(const Key('calories_field')))
        .controller!
        .text;

    await tester.enterText(find.byKey(const Key('steps_field')), '10000');
    await tester.pump();
    expect(calories(), '400'); // default 0.04 kcal per step

    await tester.enterText(find.byKey(const Key('calories_field')), '123');
    await tester.enterText(find.byKey(const Key('steps_field')), '5000');
    await tester.pump();
    expect(calories(), '123'); // user's own value is kept

    await tester.ensureVisible(find.byKey(const Key('estimate_button')));
    await tester.tap(find.byKey(const Key('estimate_button')));
    await tester.pump();
    expect(calories(), '200'); // estimate button recalculates
  });
}
