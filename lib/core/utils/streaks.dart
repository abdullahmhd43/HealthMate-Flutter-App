import 'date_helper.dart';

/// Streak maths on ISO `yyyy-MM-dd` date strings. Pure functions, easy to test.
class Streaks {
  Streaks._();

  /// Consecutive days with an entry, counting back from [today]. If today has
  /// no entry yet, a streak that ended yesterday is still alive (the user has
  /// until the end of today to keep it going).
  static int current(Iterable<String> isoDates, {required DateTime today}) {
    final days = isoDates.toSet();
    var cursor = DateHelper.dateOnly(today);
    if (!days.contains(DateHelper.toIso(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (days.contains(DateHelper.toIso(cursor))) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// The longest run of consecutive days anywhere in [isoDates].
  static int best(Iterable<String> isoDates) {
    final parsed = <DateTime>[];
    for (final iso in isoDates.toSet()) {
      final date = DateHelper.tryParseIso(iso);
      if (date != null) parsed.add(date);
    }
    parsed.sort();

    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final date in parsed) {
      final isNextDay = previous != null &&
          DateTime(previous.year, previous.month, previous.day + 1) == date;
      run = isNextDay ? run + 1 : 1;
      if (run > best) best = run;
      previous = date;
    }
    return best;
  }
}
