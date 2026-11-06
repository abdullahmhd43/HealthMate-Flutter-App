import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_helper.dart';
import 'package:healthmate/core/utils/validators.dart';

import 'test_helpers.dart';

void main() {
  group('number validation', () {
    test('required', () {
      expect(Validators.steps(null), 'Steps is required');
      expect(Validators.steps('   '), 'Steps is required');
      expect(Validators.calories(''), 'Calories is required');
      expect(Validators.water(''), 'Water intake is required');
    });

    test('must be a whole number', () {
      expect(Validators.steps('abc'), contains('whole number'));
      expect(Validators.steps('12.5'), contains('whole number'));
      expect(Validators.water('1,5'), contains('whole number'));
    });

    test('cannot be negative', () {
      expect(Validators.steps('-1'), 'Steps cannot be negative');
      expect(Validators.calories('-300'), 'Calories cannot be negative');
    });

    test('has an upper sanity limit', () {
      expect(Validators.steps('200001'), contains('too high'));
      expect(Validators.calories('20001'), contains('too high'));
      expect(Validators.water('20001'), contains('too high'));
    });

    test('accepts valid values including zero', () {
      expect(Validators.steps('0'), isNull);
      expect(Validators.steps('7850'), isNull);
      expect(Validators.calories(' 420 '), isNull);
      expect(Validators.water('2000'), isNull);
    });

    test('goals must be greater than zero', () {
      expect(Validators.goal('0', label: 'Steps', max: 1000), contains('greater than 0'));
      expect(Validators.goal('500', label: 'Steps', max: 1000), isNull);
    });
  });

  group('date validation', () {
    final now = DateTime(2026, 11, 6, 12);

    test('required', () {
      expect(Validators.date(null, now: now), 'Please select a date');
    });

    test('future dates are rejected', () {
      expect(Validators.date(DateTime(2026, 11, 7), now: now),
          'Date cannot be in the future');
    });

    test('today and past dates are accepted', () {
      expect(Validators.date(DateTime(2026, 11, 6), now: now), isNull);
      expect(Validators.date(DateTime(2026, 1, 1), now: now), isNull);
    });

    test('dates before 2000 are rejected', () {
      expect(Validators.date(DateTime(1999, 12, 31), now: now),
          'Date is too far in the past');
    });

    test('ISO parsing is strict', () {
      expect(DateHelper.tryParseIso('2026-11-06'), isNotNull);
      expect(DateHelper.tryParseIso('2026-13-01'), isNull);
      expect(DateHelper.tryParseIso('2026-11-31'), isNull);
      expect(DateHelper.tryParseIso('06/11/2026'), isNull);
      expect(DateHelper.tryParseIso(null), isNull);
    });
  });

  group('duplicate date validation', () {
    final existing = [
      record('2026-11-01', id: 1),
      record('2026-11-02', id: 2),
    ];

    test('flags a date that is already used', () {
      expect(Validators.duplicateDate('2026-11-01', existing),
          contains('already exists'));
    });

    test('allows a new date', () {
      expect(Validators.duplicateDate('2026-11-03', existing), isNull);
    });

    test('a record may keep its own date when editing', () {
      expect(Validators.duplicateDate('2026-11-01', existing, excludeId: 1),
          isNull);
    });

    test('editing cannot take another record\'s date', () {
      expect(Validators.duplicateDate('2026-11-02', existing, excludeId: 1),
          contains('already exists'));
    });
  });
}
