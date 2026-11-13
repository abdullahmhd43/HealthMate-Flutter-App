import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/streaks.dart';

void main() {
  final today = DateTime(2026, 11, 10);

  group('Streaks.current', () {
    test('is 0 with no entries', () {
      expect(Streaks.current(const [], today: today), 0);
    });

    test('counts consecutive days ending today', () {
      final dates = ['2026-11-10', '2026-11-09', '2026-11-08'];
      expect(Streaks.current(dates, today: today), 3);
    });

    test('stays alive when only today is still missing', () {
      final dates = ['2026-11-09', '2026-11-08'];
      expect(Streaks.current(dates, today: today), 2);
    });

    test('is 0 when the last entry is two or more days old', () {
      expect(Streaks.current(['2026-11-07'], today: today), 0);
    });

    test('stops at the first gap', () {
      final dates = ['2026-11-10', '2026-11-09', '2026-11-07', '2026-11-06'];
      expect(Streaks.current(dates, today: today), 2);
    });

    test('works across a month boundary and ignores duplicates', () {
      final dates = ['2026-11-01', '2026-10-31', '2026-10-31', '2026-10-30'];
      expect(Streaks.current(dates, today: DateTime(2026, 11, 1)), 3);
    });
  });

  group('Streaks.best', () {
    test('is 0 with no entries', () {
      expect(Streaks.best(const []), 0);
    });

    test('finds the longest run anywhere', () {
      final dates = [
        '2026-10-01', '2026-10-02', // run of 2
        '2026-10-10', '2026-10-11', '2026-10-12', '2026-10-13', // run of 4
        '2026-10-20', // run of 1
      ];
      expect(Streaks.best(dates), 4);
    });

    test('ignores invalid dates', () {
      expect(Streaks.best(['bad', '2026-10-01']), 1);
    });
  });
}
