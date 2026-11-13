import '../../../core/utils/date_helper.dart';

/// One night of sleep, mapped to the `sleep_logs` table (one row per date).
class SleepEntry {
  const SleepEntry({
    this.id,
    required this.date,
    required this.hours,
    required this.quality,
  });

  final int? id;

  /// ISO `yyyy-MM-dd` (the morning the user woke up).
  final String date;
  final double hours;

  /// 1 (poor) to 5 (great).
  final int quality;

  DateTime get dateTime => DateHelper.tryParseIso(date) ?? DateTime(1970);

  static const List<String> qualityLabels = [
    'Poor',
    'Fair',
    'Okay',
    'Good',
    'Great',
  ];

  String get qualityLabel => labelFor(quality);

  static String labelFor(int quality) =>
      qualityLabels[quality.clamp(1, 5).toInt() - 1];

  factory SleepEntry.fromMap(Map<String, Object?> map) => SleepEntry(
        id: map['id'] as int?,
        date: map['date'] as String,
        hours: (map['hours'] as num).toDouble(),
        quality: map['quality'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'hours': hours,
        'quality': quality,
      };

  String? validate() {
    if (DateHelper.tryParseIso(date) == null) return 'The date is not valid.';
    if (hours < 1 || hours > 24) return 'Sleep must be between 1 and 24 hours.';
    if (quality < 1 || quality > 5) return 'Sleep quality must be 1 to 5.';
    return null;
  }
}
