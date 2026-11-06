import '../../../core/utils/date_helper.dart';

/// A single day's health entry, mapped to the `health_records` table.
class HealthRecord {
  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
  });

  /// Null until the record has been inserted into SQLite.
  final int? id;

  /// ISO `yyyy-MM-dd` date.
  final String date;
  final int steps;
  final int calories;

  /// Water intake in millilitres.
  final int water;

  DateTime get dateTime => DateHelper.tryParseIso(date) ?? DateTime(1970);

  factory HealthRecord.fromMap(Map<String, Object?> map) {
    return HealthRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      steps: map['steps'] as int,
      calories: map['calories'] as int,
      water: map['water'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'steps': steps,
      'calories': calories,
      'water': water,
    };
  }

  HealthRecord copyWith({
    int? id,
    String? date,
    int? steps,
    int? calories,
    int? water,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      water: water ?? this.water,
    );
  }

  /// Returns a message if the record must not be stored, otherwise null.
  String? validate() {
    if (DateHelper.tryParseIso(date) == null) {
      return 'The date is not valid.';
    }
    if (steps < 0 || calories < 0 || water < 0) {
      return 'Values cannot be negative.';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is HealthRecord &&
      other.id == id &&
      other.date == date &&
      other.steps == steps &&
      other.calories == calories &&
      other.water == water;

  @override
  int get hashCode => Object.hash(id, date, steps, calories, water);

  @override
  String toString() =>
      'HealthRecord(id: $id, date: $date, steps: $steps, calories: $calories, water: $water)';
}
