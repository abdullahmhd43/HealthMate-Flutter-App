import 'package:intl/intl.dart';

/// Number formatting helpers.
class Formatters {
  Formatters._();

  static final NumberFormat _int = NumberFormat('#,##0');

  static String integer(num value) => _int.format(value.round());

  static String steps(num value) => _int.format(value.round());

  static String calories(num value) => '${_int.format(value.round())} kcal';

  static String water(num value) => '${_int.format(value.round())} ml';

  static String percent(double fraction) => fraction.isNaN
      ? '0%'
      : '${(fraction * 100).clamp(0, 999).round()}%';
}
