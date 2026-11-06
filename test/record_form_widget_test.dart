import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/health_records/providers/health_records_provider.dart';
import 'package:healthmate/features/health_records/screens/record_form_screen.dart';
import 'package:healthmate/features/health_records/services/sample_data_service.dart';
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
    final repo = newRepository(newInMemoryHelper());
    final provider =
        HealthRecordsProvider(repo, SampleDataService(repo, prefs));

    await tester.pumpWidget(
      ChangeNotifierProvider<HealthRecordsProvider>.value(
        value: provider,
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
    final repo = newRepository(newInMemoryHelper());
    final provider =
        HealthRecordsProvider(repo, SampleDataService(repo, prefs));

    await tester.pumpWidget(
      ChangeNotifierProvider<HealthRecordsProvider>.value(
        value: provider,
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
}
