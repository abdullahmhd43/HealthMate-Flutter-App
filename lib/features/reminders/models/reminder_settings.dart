/// What the user has switched on in Settings > Reminders.
class ReminderSettings {
  const ReminderSettings({
    this.dailyEnabled = false,
    this.dailyHour = 20,
    this.dailyMinute = 0,
    this.waterEnabled = false,
  });

  final bool dailyEnabled;
  final int dailyHour;
  final int dailyMinute;
  final bool waterEnabled;

  /// Water reminders go off at these hours, every day.
  static const List<int> waterHours = [9, 11, 13, 15, 17, 19];

  bool get anyEnabled => dailyEnabled || waterEnabled;

  /// For example `8:00 PM`.
  String get dailyTimeLabel {
    final hour12 = dailyHour % 12 == 0 ? 12 : dailyHour % 12;
    final period = dailyHour < 12 ? 'AM' : 'PM';
    return '$hour12:${dailyMinute.toString().padLeft(2, '0')} $period';
  }

  ReminderSettings copyWith({
    bool? dailyEnabled,
    int? dailyHour,
    int? dailyMinute,
    bool? waterEnabled,
  }) =>
      ReminderSettings(
        dailyEnabled: dailyEnabled ?? this.dailyEnabled,
        dailyHour: dailyHour ?? this.dailyHour,
        dailyMinute: dailyMinute ?? this.dailyMinute,
        waterEnabled: waterEnabled ?? this.waterEnabled,
      );
}
