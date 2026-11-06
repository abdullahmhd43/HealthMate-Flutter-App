import 'package:intl/intl.dart';

/// Date helpers. Dates are stored in SQLite as ISO `yyyy-MM-dd` text.
class DateHelper {
  DateHelper._();

  static final DateFormat _iso = DateFormat('yyyy-MM-dd');
  static final DateFormat _display = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _long = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _short = DateFormat('d MMM');
  static final DateFormat _weekday = DateFormat('E');
  static final DateFormat _month = DateFormat('MMMM yyyy');

  static String toIso(DateTime date) => _iso.format(date);

  /// Parses a strict `yyyy-MM-dd` string, returning null when invalid.
  static DateTime? tryParseIso(String? value) {
    if (value == null) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    try {
      return _iso.parseStrict(value);
    } on FormatException {
      return null;
    }
  }

  static String display(DateTime date) => _display.format(date);
  static String displayLong(DateTime date) => _long.format(date);
  static String shortDay(DateTime date) => _short.format(date);
  static String weekday(DateTime date) => _weekday.format(date);
  static String monthYear(DateTime date) => _month.format(date);

  /// Strips the time part.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Converts what a user types into the search box into something that can
  /// be matched against the stored ISO date. Accepts `yyyy-MM-dd` fragments
  /// directly and converts `dd/MM/yyyy` (also `.` or `-` separated).
  static String normalizeSearch(String input) {
    final text = input.trim();
    final match = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$')
        .firstMatch(text);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }
    return text;
  }

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
