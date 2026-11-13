import '../../../core/utils/date_helper.dart';

/// One logged body weight, mapped to the `weight_logs` table.
class WeightEntry {
  const WeightEntry({this.id, required this.date, required this.weightKg});

  final int? id;

  /// ISO `yyyy-MM-dd`.
  final String date;
  final double weightKg;

  DateTime get dateTime => DateHelper.tryParseIso(date) ?? DateTime(1970);

  factory WeightEntry.fromMap(Map<String, Object?> map) => WeightEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        weightKg: (map['weight_kg'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'weight_kg': weightKg,
      };

  String? validate() {
    if (DateHelper.tryParseIso(date) == null) return 'The date is not valid.';
    if (weightKg < 20 || weightKg > 300) {
      return 'Weight must be between 20 and 300 kg.';
    }
    return null;
  }
}
