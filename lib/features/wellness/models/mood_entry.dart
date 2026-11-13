import 'package:flutter/material.dart';

import '../../../core/utils/date_helper.dart';

/// Labels, emoji and colours for the 1-5 mood scale.
class MoodScale {
  MoodScale._();

  static const List<String> emojis = ['😣', '😕', '😐', '🙂', '😄'];
  static const List<String> labels = ['Rough', 'Low', 'Okay', 'Good', 'Great'];
  static const List<Color> colors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF7CB342),
    Color(0xFF2E9E5B),
  ];

  static int _i(int mood) => mood.clamp(1, 5).toInt() - 1;

  static String emoji(int mood) => emojis[_i(mood)];
  static String label(int mood) => labels[_i(mood)];
  static Color color(int mood) => colors[_i(mood)];
}

/// How the user felt on a day, mapped to the `mood_logs` table (one per date).
class MoodEntry {
  const MoodEntry({
    this.id,
    required this.date,
    required this.mood,
    this.note = '',
  });

  final int? id;
  final String date;

  /// 1 (rough) to 5 (great).
  final int mood;
  final String note;

  DateTime get dateTime => DateHelper.tryParseIso(date) ?? DateTime(1970);

  factory MoodEntry.fromMap(Map<String, Object?> map) => MoodEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        mood: map['mood'] as int,
        note: (map['note'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'mood': mood,
        'note': note,
      };

  String? validate() {
    if (DateHelper.tryParseIso(date) == null) return 'The date is not valid.';
    if (mood < 1 || mood > 5) return 'Mood must be 1 to 5.';
    if (note.length > 100) return 'Note must be 100 characters or fewer.';
    return null;
  }
}
