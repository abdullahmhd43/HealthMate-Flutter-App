import '../../features/health_records/models/health_record.dart';
import '../constants/app_constants.dart';
import 'date_helper.dart';
import 'formatters.dart';

/// Form validation rules. Each method returns an error message or null.
class Validators {
  Validators._();

  /// Validates a whole, non-negative number typed into a text field.
  static String? wholeNumber(
    String? value, {
    required String label,
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final number = int.tryParse(text);
    if (number == null) return '$label must be a whole number';
    if (number < 0) return '$label cannot be negative';
    if (number > max) {
      return '$label looks too high (maximum ${Formatters.integer(max)})';
    }
    return null;
  }

  static String? steps(String? value) =>
      wholeNumber(value, label: 'Steps', max: AppConstants.maxSteps);

  static String? calories(String? value) =>
      wholeNumber(value, label: 'Calories', max: AppConstants.maxCalories);

  static String? water(String? value) =>
      wholeNumber(value, label: 'Water intake', max: AppConstants.maxWater);

  /// Validates the chosen record date. [now] is injectable for tests.
  static String? date(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Please select a date';
    final today = DateHelper.dateOnly(now ?? DateTime.now());
    final chosen = DateHelper.dateOnly(value);
    if (chosen.isAfter(today)) return 'Date cannot be in the future';
    if (chosen.isBefore(AppConstants.earliestDate)) {
      return 'Date is too far in the past';
    }
    return null;
  }

  /// Returns a message when another record already uses [isoDate].
  /// Pass [excludeId] when editing so a record does not clash with itself.
  static String? duplicateDate(
    String isoDate,
    Iterable<HealthRecord> existing, {
    int? excludeId,
  }) {
    for (final record in existing) {
      if (record.date == isoDate && record.id != excludeId) {
        final parsed = DateHelper.tryParseIso(isoDate);
        final label = parsed == null ? isoDate : DateHelper.display(parsed);
        return 'A record for $label already exists. Edit it instead.';
      }
    }
    return null;
  }

  /// Validates a decimal number in a range (comma or dot accepted).
  static String? decimalInRange(
    String? value, {
    required String label,
    required double min,
    required double max,
    String unit = '',
  }) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return '$label is required';
    final number = double.tryParse(text);
    if (number == null || number.isNaN || number.isInfinite) {
      return '$label must be a number';
    }
    if (number < min || number > max) {
      return '$label must be between ${min.toStringAsFixed(0)} and '
          '${max.toStringAsFixed(0)}$unit';
    }
    return null;
  }

  static double parseDecimal(String text) =>
      double.parse(text.trim().replaceAll(',', '.'));

  static String? age(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Age is required';
    final number = int.tryParse(text);
    if (number == null) return 'Age must be a whole number';
    if (number < 5 || number > 120) return 'Age must be between 5 and 120';
    return null;
  }

  static String? height(String? value) => decimalInRange(value,
      label: 'Height', min: 80, max: 250, unit: ' cm');

  static String? weight(String? value) => decimalInRange(value,
      label: 'Weight', min: 20, max: 300, unit: ' kg');

  /// Name is optional, but limited in length.
  static String? name(String? value) {
    if ((value?.trim().length ?? 0) > 30) {
      return 'Name must be 30 characters or fewer';
    }
    return null;
  }

  /// Validates a goal value entered in settings.
  static String? goal(String? value, {required String label, required int max}) {
    final base = wholeNumber(value, label: label, max: max);
    if (base != null) return base;
    if (int.parse(value!.trim()) == 0) return '$label must be greater than 0';
    return null;
  }
}
