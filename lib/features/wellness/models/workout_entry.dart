import 'package:flutter/material.dart';

import '../../../core/utils/date_helper.dart';

/// A kind of workout the user can pick.
class WorkoutType {
  const WorkoutType(this.name, this.icon);

  final String name;
  final IconData icon;
}

class WorkoutTypes {
  WorkoutTypes._();

  static const List<WorkoutType> all = [
    WorkoutType('Walking', Icons.directions_walk_rounded),
    WorkoutType('Running', Icons.directions_run_rounded),
    WorkoutType('Cycling', Icons.directions_bike_rounded),
    WorkoutType('Gym', Icons.fitness_center_rounded),
    WorkoutType('Yoga', Icons.self_improvement_rounded),
    WorkoutType('Swimming', Icons.pool_rounded),
    WorkoutType('Sports', Icons.sports_soccer_rounded),
    WorkoutType('Other', Icons.bolt_rounded),
  ];

  static IconData iconFor(String name) {
    for (final type in all) {
      if (type.name == name) return type.icon;
    }
    return Icons.bolt_rounded;
  }
}

/// One workout session, mapped to the `workout_logs` table. A day can have
/// several sessions.
class WorkoutEntry {
  const WorkoutEntry({
    this.id,
    required this.date,
    required this.type,
    required this.minutes,
    this.calories = 0,
    this.note = '',
  });

  final int? id;
  final String date;
  final String type;
  final int minutes;
  final int calories;
  final String note;

  DateTime get dateTime => DateHelper.tryParseIso(date) ?? DateTime(1970);

  factory WorkoutEntry.fromMap(Map<String, Object?> map) => WorkoutEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        type: map['type'] as String,
        minutes: map['minutes'] as int,
        calories: map['calories'] as int,
        note: (map['note'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'type': type,
        'minutes': minutes,
        'calories': calories,
        'note': note,
      };

  String? validate() {
    if (DateHelper.tryParseIso(date) == null) return 'The date is not valid.';
    if (type.trim().isEmpty) return 'Choose a workout type.';
    if (minutes < 1 || minutes > 600) {
      return 'Duration must be between 1 and 600 minutes.';
    }
    if (calories < 0 || calories > 5000) {
      return 'Calories must be between 0 and 5000.';
    }
    if (note.length > 60) return 'Note must be 60 characters or fewer.';
    return null;
  }
}
